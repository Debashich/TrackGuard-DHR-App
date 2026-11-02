import 'dart:io';

import '../../../core/errors/app_exception.dart';
import '../../../shared/models/ai_analysis_result.dart';
import '../../../shared/models/ai_provider.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/geo_location.dart';
import '../domain/ai_analysis_service.dart';
import '../domain/ai_settings.dart';
import 'heuristic_ai_provider.dart';
import 'litert_gemma_provider.dart';
import 'manual_ai_provider.dart';
import 'openrouter_ai_provider.dart';

class AiAnalysisServiceImpl implements AiAnalysisService {
  final LitertGemmaProvider _litertGemma;
  final OnlineGeminiProvider _onlineGemini;
  final ManualAiProvider _manualAi;

  AiAnalysisServiceImpl({
    LitertGemmaProvider? litertGemma,
    LitertGemmaProvider? cactusGemma,
    OnlineGeminiProvider? onlineGemini,
    HeuristicAiProvider? heuristicAi,
    ManualAiProvider? manualAi,
  }) : _litertGemma = litertGemma ?? cactusGemma ?? LitertGemmaProvider(),
       _onlineGemini = onlineGemini ?? OnlineGeminiProvider(),
       _manualAi = manualAi ?? ManualAiProvider();

  @override
  Future<bool> isOfflineModelAvailable() async {
    return _litertGemma.isModelInstalled();
  }

  @override
  Future<bool> isOnlineProviderAvailable() async {
    return _onlineGemini.isAvailable();
  }

  @override
  Future<void> initializeOfflineModel() async {
    await _litertGemma.initialize();
  }

  @override
  LitertGemmaState get offlineModelState => _litertGemma.state;

  @override
  Stream<LitertGemmaState> watchOfflineModelState() => _litertGemma.stateStream;

  @override
  Future<AiAnalysisResult> analyze({
    required File image,
    required GeoLocation location,
    required AppLanguage language,
    AiMode? requestedMode,
  }) async {
    final mode = requestedMode ?? AiMode.automatic;

    // Ensure model readiness is up-to-date before evaluating routing
    if (!_litertGemma.isReady) {
      await _litertGemma.isModelInstalled();
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
      final isAvailable =
          _litertGemma.isReady || await _litertGemma.isModelInstalled();
      if (isAvailable) {
        final result = await _litertGemma.analyze(
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
        if (_litertGemma.isReady) {
          final gemmaResult = await _litertGemma.analyze(
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
    final canUseOffline =
        _litertGemma.isReady || await _litertGemma.isModelInstalled();
    if (canUseOffline) {
      final result = await _litertGemma.analyze(
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
