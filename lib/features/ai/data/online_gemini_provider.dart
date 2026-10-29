import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/ai_analysis_result.dart';
import '../../../shared/models/ai_provider.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/geo_location.dart';
import '../domain/ai_provider_config.dart';
import 'ai_result_validator.dart';

abstract class OnlineAiProvider {
  Future<bool> isAvailable();

  Future<AiAnalysisResult> analyze({
    required File image,
    required GeoLocation location,
    required AppLanguage language,
  });
}

class OnlineGeminiProvider implements OnlineAiProvider {
  final SupabaseClient? supabaseClient;
  final ConnectivityService _connectivityService;
  final AiResultValidator _validator;

  OnlineGeminiProvider({
    this.supabaseClient,
    ConnectivityService? connectivityService,
    AiResultValidator? validator,
  }) : _connectivityService =
           connectivityService ?? DefaultConnectivityService(),
       _validator = validator ?? AiResultValidator();

  @override
  Future<bool> isAvailable() async {
    final isOnline = await _connectivityService.isOnline();
    if (!isOnline) return false;
    // Edge function backend is available if Supabase is initialized
    return supabaseClient != null;
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
        'Device is offline. Online Gemini requires active connectivity.',
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

    final requestBody = {
      'image': base64Image,
      'language': language.code,
      'location': {
        'sectionId': location.sectionId,
        'kmMarker': location.kmMarker,
        'nearestStationName': location.nearestStationName,
      },
      'promptVersion': AiProviderConfig.promptVersion,
    };

    if (supabaseClient != null) {
      try {
        final response = await supabaseClient!.functions
            .invoke('analyze-hazard', body: requestBody)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw const GeminiTimeoutException(
                'Gemini cloud backend request timed out after 30 seconds.',
              ),
            );

        final statusCode = response.status;
        if (statusCode == 401 || statusCode == 403) {
          throw const GeminiUnauthorizedException(
            'Unauthorized call to Gemini analysis backend.',
          );
        }
        if (statusCode == 429) {
          throw const GeminiRateLimitedException(
            'Gemini API quota exceeded or rate limited.',
          );
        }
        if (statusCode >= 400) {
          throw GeminiUnavailableException(
            'Backend function error with status $statusCode',
          );
        }

        final dynamic responseData = response.data;
        Map<String, dynamic> dataMap;
        if (responseData is Map<String, dynamic>) {
          dataMap = responseData;
        } else if (responseData is String) {
          dataMap = jsonDecode(responseData) as Map<String, dynamic>;
        } else {
          throw const GeminiInvalidResponseException(
            'Unexpected response shape from Gemini backend function.',
          );
        }

        return _validator.validate(
          dataMap,
          provider: AiProvider.onlineGemini,
          requestedLanguage: language,
          modelName:
              dataMap['modelName'] as String? ??
              AiProviderConfig.onlineGeminiModelLabel,
        );
      } on AppException {
        rethrow;
      } on FunctionException catch (fe) {
        debugPrint('Supabase FunctionException: ${fe.status} ${fe.details}');
        if (fe.status == 429) {
          throw const GeminiRateLimitedException();
        }
        if (fe.status == 401 || fe.status == 403) {
          throw const GeminiUnauthorizedException();
        }
        throw GeminiUnavailableException('Gemini backend error: ${fe.details}');
      } on SocketException {
        throw const GeminiUnavailableException(
          'Network connection interrupted during Gemini inference.',
        );
      } catch (e) {
        debugPrint('Gemini backend general error: $e');
        throw GeminiUnavailableException('Failed to call Gemini backend: $e');
      }
    }

    // If backend client is not configured, throw typed exception
    throw const GeminiUnavailableException(
      'Gemini backend edge function client is not configured.',
    );
  }
}
