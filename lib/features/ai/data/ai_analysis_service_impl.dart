import 'dart:io';

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
  final HeuristicAiProvider _heuristicAi;
  final ManualAiProvider _manualAi;

  AiAnalysisServiceImpl({
    CactusGemmaProvider? cactusGemma,
    OnlineGeminiProvider? onlineGemini,
    HeuristicAiProvider? heuristicAi,
    ManualAiProvider? manualAi,
  }) : _cactusGemma = cactusGemma ?? CactusGemmaProvider(),
       _onlineGemini = onlineGemini ?? OnlineGeminiProvider(),
       _heuristicAi = heuristicAi ?? HeuristicAiProvider(),
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
        try {
          final result = await _cactusGemma.analyze(
            image: image,
            location: location,
            language: language,
          );
          return result.copyWith(requestedProvider: AiProvider.offlineGemma);
        } catch (e) {
          // Fall back to heuristic on execution failure
          final fallback = await _heuristicAi.analyze(
            image: image,
            location: location,
            language: language,
          );
          return fallback.copyWith(
            requestedProvider: AiProvider.offlineGemma,
            fallbackReason:
                'Offline Gemma execution failed ($e). Used heuristic fallback.',
          );
        }
      } else {
        // Gemma not ready/installed
        final fallback = await _heuristicAi.analyze(
          image: image,
          location: location,
          language: language,
        );
        return fallback.copyWith(
          requestedProvider: AiProvider.offlineGemma,
          fallbackReason:
              'Offline Gemma model is not ready. Used heuristic fallback.',
        );
      }
    }

    // Mode: Online Gemini explicitly selected
    if (mode == AiMode.onlineGemini) {
      if (await _onlineGemini.isAvailable()) {
        try {
          final result = await _onlineGemini.analyze(
            image: image,
            location: location,
            language: language,
          );
          return result.copyWith(requestedProvider: AiProvider.onlineGemini);
        } catch (e) {
          // Failed to call online backend
          if (_cactusGemma.isReady) {
            try {
              final gemmaResult = await _cactusGemma.analyze(
                image: image,
                location: location,
                language: language,
              );
              return gemmaResult.copyWith(
                requestedProvider: AiProvider.onlineGemini,
                fallbackReason:
                    'Online Gemini failed ($e). Fell back to Offline Gemma.',
              );
            } catch (_) {}
          }
          final fallback = await _heuristicAi.analyze(
            image: image,
            location: location,
            language: language,
          );
          return fallback.copyWith(
            requestedProvider: AiProvider.onlineGemini,
            fallbackReason:
                'Online Gemini failed ($e). Used heuristic fallback.',
          );
        }
      } else {
        // Online Gemini unavailable (offline or not configured)
        if (_cactusGemma.isReady) {
          try {
            final gemmaResult = await _cactusGemma.analyze(
              image: image,
              location: location,
              language: language,
            );
            return gemmaResult.copyWith(
              requestedProvider: AiProvider.onlineGemini,
              fallbackReason: 'Online Gemini unavailable (offline). Fell back to Offline Gemma.',
            );
          } catch (_) {}
        }
        final fallback = await _heuristicAi.analyze(
          image: image,
          location: location,
          language: language,
        );
        return fallback.copyWith(
          requestedProvider: AiProvider.onlineGemini,
          fallbackReason:
              'Online Gemini requires connectivity. Used heuristic fallback.',
        );
      }
    }

    // Mode: Automatic
    // 1. Prefer Offline Gemma for offline/privacy-first alignment operations
    if (_cactusGemma.isReady) {
      try {
        final result = await _cactusGemma.analyze(
          image: image,
          location: location,
          language: language,
        );
        return result.copyWith(requestedProvider: AiProvider.offlineGemma);
      } catch (_) {
        // Continue to online fallback on Gemma error
      }
    }

    // 2. Try Online Gemini if online and ready
    if (await _onlineGemini.isAvailable()) {
      try {
        final result = await _onlineGemini.analyze(
          image: image,
          location: location,
          language: language,
        );
        return result.copyWith(requestedProvider: AiProvider.onlineGemini);
      } catch (_) {
        // Continue to heuristic fallback
      }
    }

    // 3. Deterministic Heuristic Fallback
    try {
      final heuristicResult = await _heuristicAi.analyze(
        image: image,
        location: location,
        language: language,
      );
      return heuristicResult.copyWith(
        requestedProvider: AiProvider.heuristic,
        fallbackReason:
            'Local and cloud models unavailable. Used heuristic fallback.',
      );
    } catch (_) {
      // 4. Absolute Last-resort Manual
      final manualResult = await _manualAi.analyze(
        location: location,
        language: language,
      );
      return manualResult.copyWith(
        requestedProvider: AiProvider.manual,
        fallbackReason: 'All automated AI analysis unavailable.',
      );
    }
  }
}
