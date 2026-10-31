import 'dart:io';

import '../../../core/errors/app_exception.dart';
import '../../../shared/models/ai_analysis_result.dart';
import '../../../shared/models/ai_provider.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/geo_location.dart';
import '../domain/ai_analysis_service.dart';
import '../domain/ai_settings.dart';
import 'cactus_gemma_provider.dart';
import 'heuristic_ai_provider.dart';
import 'manual_ai_provider.dart';
import 'online_gemini_provider.dart';

class AiAnalysisServiceImpl implements AiAnalysisService {
  final CactusGemmaProvider _cactusGemma;
  final OnlineGeminiProvider _onlineGemini;
  final ManualAiProvider _manualAi;

  AiAnalysisServiceImpl({
    CactusGemmaProvider? cactusGemma,
    OnlineGeminiProvider? onlineGemini,
    HeuristicAiProvider? heuristicAi,
    ManualAiProvider? manualAi,
  }) : _cactusGemma = cactusGemma ?? CactusGemmaProvider(),
       _onlineGemini = onlineGemini ?? OnlineGeminiProvider(),
       _manualAi = manualAi ?? ManualAiProvider();

  @override
  Future<bool> isOfflineModelAvailable() async {
    return _cactusGemma.isModelInstalled();
  }

  @override
  Future<bool> isOnlineProviderAvailable() async {
    return _onlineGemini.isAvailable();
  }

  @override
  Future<void> initializeOfflineModel() async {
    await _cactusGemma.initialize();
  }

  @override
  CactusGemmaState get offlineModelState => _cactusGemma.state;

  @override
  Stream<CactusGemmaState> watchOfflineModelState() => _cactusGemma.stateStream;

  @override
  Future<AiAnalysisResult> analyze({
    required File image,
    required GeoLocation location,
    required AppLanguage language,
    AiMode? requestedMode,
  }) async {
    final mode = requestedMode ?? AiMode.automatic;

    // Ensure model readiness is up-to-date before evaluating routing
    if (!_cactusGemma.isReady) {
      await _cactusGemma.isModelInstalled();
    }

    // Mode: Manual classification
    if (mode == AiMode.manual) {
      final manual = await _manualAi.analyze(
        location: location,
        language: language,
      );
      return manual.copyWith(requestedProvider: AiProvider.manual);
    }

    // Mode: Offline Gemma explicitly selected
    if (mode == AiMode.offlineGemma) {
      if (_cactusGemma.isReady) {
        final result = await _cactusGemma.analyze(
          image: image,
          location: location,
          language: language,
        );
        return result.copyWith(requestedProvider: AiProvider.offlineGemma);
      } else {
        throw const OfflineModelUnavailableException(
          'Offline Gemma model is not ready on this device.',
        );
      }
    }

    // Mode: Online Gemini explicitly selected
    if (mode == AiMode.onlineGemini) {
      if (await _onlineGemini.isAvailable()) {
        final result = await _onlineGemini.analyze(
          image: image,
          location: location,
          language: language,
        );
        return result.copyWith(requestedProvider: AiProvider.onlineGemini);
      } else {
        if (_cactusGemma.isReady) {
          final gemmaResult = await _cactusGemma.analyze(
            image: image,
            location: location,
            language: language,
          );
          return gemmaResult.copyWith(
            requestedProvider: AiProvider.onlineGemini,
            fallbackReason:
                'Online Gemini unavailable (offline). Fell back to Offline Gemma.',
          );
        }
        throw const GeminiUnavailableException(
          'Online Gemini requires connectivity or backend is unavailable.',
        );
      }
    }

    // Mode: Automatic
    // 1. Prefer Offline Gemma for offline/privacy-first alignment operations
    if (_cactusGemma.isReady) {
      final result = await _cactusGemma.analyze(
        image: image,
        location: location,
        language: language,
      );
      return result.copyWith(requestedProvider: AiProvider.offlineGemma);
    }

    // 2. Try Online Gemini if online and ready
    if (await _onlineGemini.isAvailable()) {
      final result = await _onlineGemini.analyze(
        image: image,
        location: location,
        language: language,
      );
      return result.copyWith(requestedProvider: AiProvider.onlineGemini);
    }

    throw const AiUnavailableException(
      'No AI model available. Please download the offline Gemma model or switch to manual classification.',
    );
  }
}
