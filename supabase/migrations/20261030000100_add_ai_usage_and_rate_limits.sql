
-- Phase 4: AI usage auditing and per-user rate limiting.

CREATE TABLE public.ai_usage_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id text NOT NULL UNIQUE,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  model text NOT NULL,
  prompt_version text NOT NULL,
  status text NOT NULL CHECK (status IN ('success', 'error')),
  http_status integer CHECK (
    http_status IS NULL OR http_status BETWEEN 100 AND 599
  ),
  duration_ms integer CHECK (duration_ms IS NULL OR duration_ms >= 0),
  input_tokens integer CHECK (input_tokens IS NULL OR input_tokens >= 0),
  output_tokens integer CHECK (output_tokens IS NULL OR output_tokens >= 0),
  total_tokens integer CHECK (total_tokens IS NULL OR total_tokens >= 0),
  error_code text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ai_usage_logs_user_created_idx
  ON public.ai_usage_logs (user_id, created_at DESC);

CREATE INDEX ai_usage_logs_created_idx
  ON public.ai_usage_logs (created_at DESC);


CREATE TABLE public.ai_rate_limits (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  minute_window_started_at timestamptz NOT NULL DEFAULT now(),
  minute_count integer NOT NULL DEFAULT 0 CHECK (minute_count >= 0),
  daily_date date NOT NULL DEFAULT (now() AT TIME ZONE 'UTC')::date,
  daily_count integer NOT NULL DEFAULT 0 CHECK (daily_count >= 0),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- No direct access from application clients.
ALTER TABLE public.ai_usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_rate_limits ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.ai_usage_logs FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.ai_rate_limits FROM PUBLIC, anon, authenticated;

GRANT ALL ON public.ai_usage_logs TO service_role;
GRANT ALL ON public.ai_rate_limits TO service_role;


-- Atomically consume one request from the user's minute and daily quotas.
CREATE OR REPLACE FUNCTION public.consume_ai_request(
  p_user_id uuid,
  p_minute_limit integer,
  p_daily_limit integer
)
RETURNS TABLE (
  allowed boolean,
  limit_reason text,
  retry_after_seconds integer,
  minute_count integer,
  daily_count integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_now timestamptz := now();
  v_today date := (now() AT TIME ZONE 'UTC')::date;
  v_minute_started timestamptz;
  v_minute_count integer;
  v_daily_date date;
  v_daily_count integer;
  v_retry integer;
BEGIN
  IF p_user_id IS NULL
     OR p_minute_limit < 1
     OR p_daily_limit < 1 THEN
    RAISE EXCEPTION 'Invalid rate limit arguments';
  END IF;

  INSERT INTO public.ai_rate_limits AS limits (
    user_id,
    minute_window_started_at,
    minute_count,
    daily_date,
    daily_count,
    updated_at
  )
  VALUES (
    p_user_id,
    v_now,
    1,
    v_today,
    1,
    v_now
  )
  ON CONFLICT (user_id) DO UPDATE SET
    minute_window_started_at = CASE
      WHEN limits.minute_window_started_at <= v_now - interval '1 minute'
      THEN v_now
      ELSE limits.minute_window_started_at
    END,
    minute_count = CASE
      WHEN limits.minute_window_started_at <= v_now - interval '1 minute'
      THEN 1
      ELSE limits.minute_count + 1
    END,
    daily_date = v_today,
    daily_count = CASE
      WHEN limits.daily_date <> v_today
      THEN 1
      ELSE limits.daily_count + 1
    END,
    updated_at = v_now
  RETURNING
    limits.minute_window_started_at,
    limits.minute_count,
    limits.daily_date,
    limits.daily_count
  INTO
    v_minute_started,
    v_minute_count,
    v_daily_date,
    v_daily_count;

  allowed := v_minute_count <= p_minute_limit
         AND v_daily_count <= p_daily_limit;

  IF v_daily_count > p_daily_limit THEN
    limit_reason := 'daily_limit';
    v_retry := CEIL(EXTRACT(
      EPOCH FROM (
        ((v_today + 1)::timestamp AT TIME ZONE 'UTC') - v_now
      )
    ))::integer;
  ELSIF v_minute_count > p_minute_limit THEN
    limit_reason := 'minute_limit';
    v_retry := CEIL(EXTRACT(
      EPOCH FROM (
        v_minute_started + interval '1 minute' - v_now
      )
    ))::integer;
  ELSE
    limit_reason := NULL;
    v_retry := 0;
  END IF;

  retry_after_seconds := GREATEST(0, v_retry);
  minute_count := v_minute_count;
  daily_count := v_daily_count;

  RETURN NEXT;
END;
$$;

-- Only the Edge Function's service-role client may invoke this RPC.
REVOKE ALL ON FUNCTION public.consume_ai_request(uuid, integer, integer)
  FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.consume_ai_request(uuid, integer, integer)
  TO service_role;