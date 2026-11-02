import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/ai_analysis_result.dart';
import '../../../shared/models/ai_provider.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/geo_location.dart';
import '../domain/ai_provider_config.dart';
import 'ai_prompt_builder.dart';
import 'ai_result_validator.dart';

abstract class OnlineAiProvider {
  Future<bool> isAvailable();

  Future<AiAnalysisResult> analyze({
    required File image,
    required GeoLocation location,
    required AppLanguage language,
  });
}

/// Online AI Provider powered by OpenRouter multimodal vision models
/// (default: nvidia/nemotron-3.5-super-vl:free).
///
/// Aliased as [OnlineGeminiProvider] to preserve backward compatibility with
/// domain models, Supabase reports schema, and existing unit tests.
class OnlineGeminiProvider implements OnlineAiProvider {
  final SupabaseClient? supabaseClient;
  final ConnectivityService _connectivityService;
  final AiResultValidator _validator;
  final AiPromptBuilder _promptBuilder;
  final http.Client? httpClient;
  final String? apiKey;
  final String? model;
  final String? apiUrl;

  OnlineGeminiProvider({
    this.supabaseClient,
    ConnectivityService? connectivityService,
    AiResultValidator? validator,
    AiPromptBuilder? promptBuilder,
    this.httpClient,
    this.apiKey,
    this.model,
    this.apiUrl,
  })  : _connectivityService =
            connectivityService ?? DefaultConnectivityService(),
        _validator = validator ?? AiResultValidator(),
        _promptBuilder = promptBuilder ?? AiPromptBuilder();

  @override
  Future<bool> isAvailable() async {
    final isOnline = await _connectivityService.isOnline();
    if (!isOnline) return false;
    final key = (apiKey ?? AppEnv.openRouterApiKey).trim();
    return key.isNotEmpty;
  }

  @override
  Future<AiAnalysisResult> analyze({
    required File image,
    required GeoLocation location,
    required AppLanguage language,
  }) async {
    final isOnline = await _connectivityService.isOnline();
    if (!isOnline) {
      throw const GeminiUnavailableException(
        'Device is offline. Online AI analysis requires active connectivity.',
      );
    }

    final key = (apiKey ?? AppEnv.openRouterApiKey).trim();
    if (key.isEmpty) {
      throw const GeminiUnauthorizedException(
        'OpenRouter API key is not configured. Please set OPENROUTER_API_KEY in .env.',
      );
    }

    if (!await image.exists()) {
      throw const AiValidationFailedException(
        'Captured image file does not exist for online analysis.',
      );
    }

    // Check image size limit (10MB limit for cloud analysis)
    final fileSize = await image.length();
    if (fileSize > 10 * 1024 * 1024) {
      throw const AiImageTooLargeException(
        'Image file size exceeds maximum 10MB limit.',
      );
    }

    final imageBytes = await image.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    final mimeType = _mimeTypeForPath(image.path);
    final imageUrl = 'data:$mimeType;base64,$base64Image';

    final prompt = _promptBuilder.buildPrompt(
      language: language,
      location: location,
    );

    final modelName = (model ?? AppEnv.openRouterModel).trim();
    final endpointUrl = apiUrl ?? AiProviderConfig.openRouterApiUrl;

    final requestHeaders = {
      'Authorization': 'Bearer $key',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://trackguard-dhr.app',
      'X-Title': 'TrackGuard DHR',
    };

    final requestBody = jsonEncode({
      'model': modelName,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': prompt,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': imageUrl,
              },
            },
          ],
        },
      ],
    });

    final client = httpClient ?? http.Client();
    final shouldCloseClient = httpClient == null;

    try {
      final response = await client
          .post(
            Uri.parse(endpointUrl),
            headers: requestHeaders,
            body: requestBody,
          )
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () => throw const GeminiTimeoutException(
              'OpenRouter AI request timed out after 90 seconds.',
            ),
          );

      final statusCode = response.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        throw const GeminiUnauthorizedException(
          'Unauthorized OpenRouter API key. Check OPENROUTER_API_KEY in .env.',
        );
      }
      if (statusCode == 429) {
        throw const GeminiRateLimitedException(
          'OpenRouter API rate limit reached or quota exceeded.',
        );
      }
      if (statusCode >= 400) {
        throw GeminiUnavailableException(
          'OpenRouter API error (status $statusCode): ${response.body}',
        );
      }

      final Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw GeminiInvalidResponseException(
          'Invalid JSON response from OpenRouter: $e',
        );
      }

      final choices = jsonResponse['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw const GeminiInvalidResponseException(
          'OpenRouter response contains no choices.',
        );
      }

      final firstChoice = choices[0];
      if (firstChoice is! Map<String, dynamic>) {
        throw const GeminiInvalidResponseException(
          'OpenRouter choice format is invalid.',
        );
      }

      final message = firstChoice['message'] as Map<String, dynamic>?;
      final rawContent = message?['content'];

      String textContent = '';
      if (rawContent is String) {
        textContent = rawContent;
      } else if (rawContent is List) {
        textContent = rawContent
            .map((part) => part is Map ? part['text'] ?? '' : part.toString())
            .join('\n');
      } else if (rawContent != null) {
        textContent = rawContent.toString();
      }

      if (textContent.trim().isEmpty) {
        throw const GeminiInvalidResponseException(
          'OpenRouter choice message content is empty.',
        );
      }

      return _validator.validateString(
        textContent,
        provider: AiProvider.onlineGemini,
        requestedLanguage: language,
        modelName: modelName,
      );
    } on AppException {
      rethrow;
    } on SocketException catch (se) {
      throw GeminiUnavailableException(
        'Network error during OpenRouter AI inference: ${se.message}',
      );
    } catch (e) {
      debugPrint('OpenRouter general error: $e');
      throw GeminiUnavailableException('Failed to call OpenRouter AI: $e');
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  String _mimeTypeForPath(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) return 'image/png';
    if (lowerPath.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

/// Explicit alias for OpenRouter AI provider
typedef OpenRouterAiProvider = OnlineGeminiProvider;
