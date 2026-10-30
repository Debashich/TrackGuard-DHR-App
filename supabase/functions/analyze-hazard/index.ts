/// <reference lib="deno.ns" />
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "@supabase/supabase-js";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const SUPPORTED_LANGUAGES = ["en", "hi", "bn", "ne"] as const;

const SUPPORTED_HAZARDS = [
  "slip",
  "rockfall",
  "blockedDrain",
  "damagedWall",
  "trackDefect",
  "vegetation",
  "other",
] as const;

const SUPPORTED_SEVERITIES = ["low", "medium", "high", "critical"] as const;

const SUPPORTED_IMAGE_MIME_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
] as const;

const PROMPT_VERSION = "phase4-v1";
const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

const RATE_LIMIT_PER_MINUTE = 10;
const RATE_LIMIT_PER_DAY = 100;

type AuditMetadata = {
  inputTokens?: number | null;
  outputTokens?: number | null;
  totalTokens?: number | null;
};

type GeminiResponse = {
  usageMetadata?: {
    promptTokenCount?: unknown;
    candidatesTokenCount?: unknown;
    totalTokenCount?: unknown;
  };
  candidates?: Array<{
    content?: {
      parts?: Array<{
        text?: string;
      }>;
    };
  }>;
};

type AuditResponse = (
  status: number,
  body: Record<string, unknown>,
  metadata?: AuditMetadata,
  extraHeaders?: Record<string, string>,
) => Promise<Response>;

function jsonResponse(
  status: number,
  body: Record<string, unknown>,
  extraHeaders: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      ...extraHeaders,
    },
  });
}

function getLanguageInstruction(language: string): string {
  switch (language) {
    case "hi":
      return 'Write the "note" in natural, professional Hindi (हिंदी).';
    case "bn":
      return 'Write the "note" in natural, professional Bengali (বাংলা).';
    case "ne":
      return 'Write the "note" in natural, professional Nepali (नेपाली).';
    default:
      return 'Write the "note" in plain, professional English.';
  }
}

function normalizeHazard(value: unknown): string | null {
  if (typeof value !== "string") return null;

  const normalized = value.trim().toLowerCase().replace(/[\s_-]/g, "");

  const aliases: Record<string, string> = {
    slip: "slip",
    landslide: "slip",
    rockfall: "rockfall",
    fallingrocks: "rockfall",
    blockeddrain: "blockedDrain",
    drainage: "blockedDrain",
    damagedwall: "damagedWall",
    retainingwall: "damagedWall",
    trackdefect: "trackDefect",
    raildefect: "trackDefect",
    vegetation: "vegetation",
    overgrowth: "vegetation",
    other: "other",
    miscellaneous: "other",
  };

  return aliases[normalized] ?? null;
}

function sanitizeNote(value: unknown): string | null {
  if (typeof value !== "string") return null;

  let note = value.trim();
  if (!note || note.length > 1000) return null;

  const forbidden = [
    /stop the train/gi,
    /stop train/gi,
    /halt the train/gi,
    /close the track/gi,
    /close track/gi,
    /shut down track/gi,
    /send workers immediately/gi,
    /dispatch repair crew/gi,
    /ignore this hazard/gi,
    /definitely safe/gi,
    /100%\s*safe/gi,
    /completely safe/gi,
    /guaranteed safe/gi,
    /track is clear for all speeds/gi,
  ];

  for (const pattern of forbidden) {
    note = note.replace(pattern, "inspection advisory noted");
  }

  return note.slice(0, 300).trim() || null;
}

function numericTokenCount(value: unknown): number | null {
  return typeof value === "number" &&
      Number.isInteger(value) &&
      value >= 0
    ? value
    : null;
}

Deno.serve(async (req: Request) => {
  const requestId = crypto.randomUUID();
  const startedAt = Date.now();

  let auditResponse: AuditResponse | undefined;

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, {
      error: "method_not_allowed",
      requestId,
    });
  }

  try {
    // 1. Authenticate the caller.

    const authorization = req.headers.get("Authorization");
    const match = authorization?.match(/^Bearer\s+(.+)$/i);

    if (!match) {
      return jsonResponse(401, {
        error: "unauthorized",
        requestId,
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");

    if (!supabaseUrl || !serviceRoleKey || !geminiApiKey) {
      console.error(JSON.stringify({
        event: "configuration_error",
        requestId,
      }));

      return jsonResponse(500, {
        error: "backend_misconfigured",
        requestId,
      });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    const { data: authData, error: authError } = await supabase.auth.getUser(
      match[1],
    );

    if (authError || !authData.user) {
      return jsonResponse(401, {
        error: "unauthorized",
        requestId,
      });
    }

    const userId = authData.user.id;

    // 2. Verify the user's database profile and permissions.

    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("role,is_active")
      .eq("id", userId)
      .maybeSingle();

    if (profileError) {
      console.error(JSON.stringify({
        event: "profile_lookup_failed",
        requestId,
        userId,
        code: profileError.code,
      }));

      return jsonResponse(500, {
        error: "profile_verification_failed",
        requestId,
      });
    }

    if (
      !profile ||
      profile.is_active !== true ||
      !["gangman", "admin"].includes(profile.role)
    ) {
      return jsonResponse(403, {
        error: "account_not_authorized",
        requestId,
      });
    }

    const model = Deno.env.get("GEMINI_MODEL") || "gemini-2.5-flash";

    // 3. Set up persistent audit logging for this authorized request.

    let auditWritten = false;

    auditResponse = async (
      status: number,
      responseBody: Record<string, unknown>,
      metadata: AuditMetadata = {},
      extraHeaders: Record<string, string> = {},
    ): Promise<Response> => {
      if (!auditWritten) {
        // Prevent duplicate audit rows if an error occurs while responding.
        auditWritten = true;

        const successful = status >= 200 && status < 300;

        const auditRow = {
          request_id: requestId,
          user_id: userId,
          model,
          prompt_version: PROMPT_VERSION,
          status: successful ? "success" : "error",
          http_status: status,
          duration_ms: Date.now() - startedAt,
          input_tokens: metadata.inputTokens ?? null,
          output_tokens: metadata.outputTokens ?? null,
          total_tokens: metadata.totalTokens ?? null,
          error_code: successful
            ? null
            : typeof responseBody.error === "string"
            ? responseBody.error
            : "request_failed",
        };

        try {
          const { error } = await supabase
            .from("ai_usage_logs")
            .insert(auditRow);

          if (error) {
            console.error(JSON.stringify({
              event: "audit_log_write_failed",
              requestId,
              userId,
              code: error.code,
            }));
          }
        } catch (error) {
          console.error(JSON.stringify({
            event: "audit_log_write_failed",
            requestId,
            userId,
            errorType: error instanceof Error ? error.name : "UnknownError",
          }));
        }
      }

      return jsonResponse(status, {
        ...responseBody,
        requestId,
      }, extraHeaders);
    };

    // 4. Consume the user's rate-limit allowance atomically.

    const { data: rateLimitData, error: rateLimitError } = await supabase.rpc(
      "consume_ai_request",
      {
        p_user_id: userId,
        p_minute_limit: RATE_LIMIT_PER_MINUTE,
        p_daily_limit: RATE_LIMIT_PER_DAY,
      },
    );

    if (rateLimitError) {
      console.error(JSON.stringify({
        event: "rate_limit_check_failed",
        requestId,
        userId,
        code: rateLimitError.code,
      }));

      return await auditResponse(503, {
        error: "rate_limit_service_unavailable",
      });
    }

    const rateLimit = Array.isArray(rateLimitData) ? rateLimitData[0] : null;

    if (!rateLimit || typeof rateLimit.allowed !== "boolean") {
      console.error(JSON.stringify({
        event: "rate_limit_invalid_response",
        requestId,
        userId,
      }));

      return await auditResponse(503, {
        error: "rate_limit_service_unavailable",
      });
    }

    if (!rateLimit.allowed) {
      const retryAfterSeconds =
        typeof rateLimit.retry_after_seconds === "number"
          ? Math.max(0, rateLimit.retry_after_seconds)
          : 60;

      console.warn(JSON.stringify({
        event: "ai_rate_limit_exceeded",
        requestId,
        userId,
        reason: rateLimit.limit_reason,
        minuteCount: rateLimit.minute_count,
        dailyCount: rateLimit.daily_count,
      }));

      return await auditResponse(
        429,
        {
          error: "rate_limited",
          limitReason: rateLimit.limit_reason,
          retryAfterSeconds,
        },
        {},
        {
          "Retry-After": String(retryAfterSeconds),
        },
      );
    }

    // 5. Validate the incoming request.

    const contentLength = Number(
      req.headers.get("content-length") ?? 0,
    );

    if (contentLength > 15 * 1024 * 1024) {
      return await auditResponse(413, {
        error: "request_too_large",
      });
    }

    let body: Record<string, unknown>;

    try {
      body = await req.json();

      if (!body || typeof body !== "object" || Array.isArray(body)) {
        throw new Error("Invalid JSON object");
      }
    } catch {
      return await auditResponse(400, {
        error: "invalid_json",
      });
    }

    const image = body.image;
    const imageMimeType = body.mimeType;
    const language = body.language;
    const location = body.location;
    const promptVersion = body.promptVersion;

    if (
      typeof image !== "string" ||
      image.length === 0 ||
      image.length > 14 * 1024 * 1024 ||
      !/^[A-Za-z0-9+/]+={0,2}$/.test(image)
    ) {
      return await auditResponse(400, {
        error: "invalid_image",
      });
    }

    if (
      typeof imageMimeType !== "string" ||
      !SUPPORTED_IMAGE_MIME_TYPES.includes(
        imageMimeType as (typeof SUPPORTED_IMAGE_MIME_TYPES)[number],
      )
    ) {
      return await auditResponse(400, {
        error: "unsupported_image_type",
      });
    }

    let imageBytes: Uint8Array;

    try {
      const decoded = atob(image);
      imageBytes = Uint8Array.from(
        decoded,
        (char) => char.charCodeAt(0),
      );
    } catch {
      return await auditResponse(400, {
        error: "invalid_image",
      });
    }

    if (
      imageBytes.length === 0 ||
      imageBytes.length > MAX_IMAGE_BYTES
    ) {
      return await auditResponse(413, {
        error: "image_size_invalid",
      });
    }

    if (
      typeof language !== "string" ||
      !SUPPORTED_LANGUAGES.includes(
        language as (typeof SUPPORTED_LANGUAGES)[number],
      )
    ) {
      return await auditResponse(400, {
        error: "unsupported_language",
      });
    }

    if (promptVersion !== PROMPT_VERSION) {
      return await auditResponse(400, {
        error: "unsupported_prompt_version",
      });
    }

    if (
      !location ||
      typeof location !== "object" ||
      Array.isArray(location)
    ) {
      return await auditResponse(400, {
        error: "invalid_location",
      });
    }

    const loc = location as Record<string, unknown>;

    const sectionId = typeof loc.sectionId === "string"
      ? loc.sectionId.slice(0, 100)
      : "";

    const station = typeof loc.nearestStationName === "string"
      ? loc.nearestStationName.slice(0, 100)
      : "";

    const kmMarker = typeof loc.kmMarker === "number" &&
        Number.isFinite(loc.kmMarker)
      ? loc.kmMarker
      : null;

    const locationContext = [
      sectionId ? `Alignment section: ${sectionId}` : "",
      station ? `Nearest station context: ${station}` : "",
      kmMarker !== null ? `Kilometre marker: ${kmMarker.toFixed(1)}` : "",
    ].filter(Boolean).join("\n") || "Location context unavailable.";

    // 6. Construct the advisory-only Gemini prompt.

    const prompt = `
You are TrackGuard AI, an advisory track-inspection assistant for permanent-way staff on the Darjeeling Himalayan Railway.

Analyze the supplied photograph and identify a potential railway hazard.

Safety rules:
- Provide observational descriptions only, not operational commands.
- Never claim that the track is safe or clear for travel.
- Do not invent locations, coordinates, or details not visible in the image.
- Treat location metadata only as context, not evidence of what the image shows.
- If evidence is ambiguous, choose "other" and describe the uncertainty.
- Return only valid JSON, without markdown or extra text.
- The note must be concise, observational, and at most 300 characters.
- ${getLanguageInstruction(language)}

Location context:
${locationContext}

Choose exactly one hazardType:
${SUPPORTED_HAZARDS.join(", ")}

Choose exactly one severity:
${SUPPORTED_SEVERITIES.join(", ")}

Return this JSON shape:
{
  "hazardType": "one supported hazard type",
  "severity": "one supported severity",
  "note": "observational description",
  "confidence": 0.0
}

Prompt version: ${PROMPT_VERSION}
`.trim();

    // 7. Call Gemini.

    const geminiResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${
        encodeURIComponent(model)
      }:generateContent?key=${encodeURIComponent(geminiApiKey)}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          contents: [{
            role: "user",
            parts: [
              {
                inlineData: {
                  mimeType: imageMimeType,
                  data: image,
                },
              },
              {
                text: prompt,
              },
            ],
          }],
          generationConfig: {
            responseMimeType: "application/json",
          },
        }),
        signal: AbortSignal.timeout(22000),
      },
    );

    if (!geminiResponse.ok) {
  const status = geminiResponse.status;
  const upstreamBody = await geminiResponse.text();

  let upstreamError: {
    error?: {
      code?: number;
      status?: string;
      message?: string;
    };
  } = {};

  try {
    upstreamError = JSON.parse(upstreamBody);
  } catch {
    // Keep the diagnostic safe if Gemini returns non-JSON.
  }

  console.error(JSON.stringify({
    event: "gemini_request_failed",
    requestId,
    userId,
    model,
    upstreamStatus: status,
    upstreamCode: upstreamError.error?.code ?? null,
    upstreamErrorStatus: upstreamError.error?.status ?? null,
    upstreamMessage: upstreamError.error?.message?.slice(0, 500) ?? null,
    durationMs: Date.now() - startedAt,
  }));

  if (status === 429) {
    return await auditResponse(429, {
      error: "rate_limited",
    });
  }

  return await auditResponse(502, {
    error: "ai_provider_unavailable",
  });
}

    // 8. Parse the Gemini response and capture token usage.

    let geminiData: GeminiResponse;

    try {
      const parsed = await geminiResponse.json();

      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
        throw new Error("Invalid Gemini response");
      }

      geminiData = parsed as GeminiResponse;
    } catch {
      console.error(JSON.stringify({
        event: "gemini_response_parse_failed",
        requestId,
        userId,
        model,
      }));

      return await auditResponse(502, {
        error: "invalid_ai_response",
      });
    }

    const usage = geminiData.usageMetadata ?? {};

    const usageMetadata: AuditMetadata = {
      inputTokens: numericTokenCount(usage.promptTokenCount),
      outputTokens: numericTokenCount(usage.candidatesTokenCount),
      totalTokens: numericTokenCount(usage.totalTokenCount),
    };

    const generatedText = geminiData?.candidates?.[0]?.content?.parts
      ?.map((part: { text?: string }) => part.text ?? "")
      .join("")
      .trim();

    if (typeof generatedText !== "string" || !generatedText) {
      console.error(JSON.stringify({
        event: "gemini_empty_response",
        requestId,
        userId,
        model,
      }));

      return await auditResponse(502, {
        error: "invalid_ai_response",
      }, usageMetadata);
    }

    // 9. Parse and validate the model-generated JSON.

    let result: Record<string, unknown>;

    try {
      const parsed = JSON.parse(generatedText);

      if (
        !parsed ||
        typeof parsed !== "object" ||
        Array.isArray(parsed)
      ) {
        throw new Error("Invalid AI result object");
      }

      result = parsed;
    } catch {
      return await auditResponse(502, {
        error: "invalid_ai_response",
      }, usageMetadata);
    }

    const hazardType = normalizeHazard(result.hazardType);

    const severity = typeof result.severity === "string"
      ? result.severity.trim().toLowerCase()
      : null;

    const note = sanitizeNote(result.note);

    const confidence = typeof result.confidence === "number" &&
        Number.isFinite(result.confidence)
      ? Math.max(0, Math.min(1, result.confidence))
      : null;

    if (
      !hazardType ||
      !SUPPORTED_SEVERITIES.includes(
        severity as (typeof SUPPORTED_SEVERITIES)[number],
      ) ||
      !note
    ) {
      console.error(JSON.stringify({
        event: "gemini_schema_validation_failed",
        requestId,
        userId,
        model,
      }));

      return await auditResponse(502, {
        error: "invalid_ai_response",
      }, usageMetadata);
    }

    // 10. Record success and return the existing Flutter response contract.

    console.log(JSON.stringify({
      event: "gemini_request_succeeded",
      requestId,
      userId,
      model,
      promptVersion: PROMPT_VERSION,
      durationMs: Date.now() - startedAt,
      usageMetadata,
    }));

    return await auditResponse(200, {
      hazardType,
      severity,
      note,
      confidence,
      modelName: model,
    }, usageMetadata);
  } catch (error) {
    console.error(JSON.stringify({
      event: "analysis_request_failed",
      requestId,
      errorType: error instanceof Error ? error.name : "UnknownError",
      durationMs: Date.now() - startedAt,
    }));

    if (error instanceof DOMException && error.name === "TimeoutError") {
      if (auditResponse) {
        return await auditResponse(504, {
          error: "ai_request_timeout",
        });
      }

      return jsonResponse(504, {
        error: "ai_request_timeout",
        requestId,
      });
    }

    if (auditResponse) {
      return await auditResponse(500, {
        error: "internal_server_error",
      });
    }

    return jsonResponse(500, {
      error: "internal_server_error",
      requestId,
    });
  }
});
