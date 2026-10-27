import 'dart:io';

import '../../../shared/models/ai_analysis_result.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/geo_location.dart';
import '../domain/ai_analysis_service.dart';
import 'heuristic_ai_provider.dart';
import 'manual_ai_provider.dart';
import 'offline_gemma_provider.dart';

class AiAnalysisServiceImpl implements AiAnalysisService {
  final OfflineGemmaProvider _offlineGemma = OfflineGemmaProvider();
  final HeuristicAiProvider _heuristicAi = HeuristicAiProvider();
  final ManualAiProvider _manualAi = ManualAiProvider();

  @override
  Future<bool> isOfflineModelAvailable() async {
    return _offlineGemma.isModelInstalled();
  }

  @override
  Future<void> initializeOfflineModel() async {
    if (await _offlineGemma.isModelInstalled()) {
      await _offlineGemma.initialize();
    }
  }

  @override
  Future<AiAnalysisResult> analyze({
    required File image,
    required GeoLocation location,
    required AppLanguage language,
  }) async {
    // 1. Try Offline Gemma if ready
    if (_offlineGemma.isReady) {
      try {
        return await _offlineGemma.analyze(
          image: image,
          location: location,
          language: language,
        );
      } catch (_) {
        // Fall back on failure
      }
    }

    // 2. Try Heuristic Fallback
    try {
      return await _heuristicAi.analyze(
        image: image,
        location: location,
        language: language,
      );
    } catch (_) {
      // 3. Last-resort Manual Fallback
      return _manualAi.analyze(location: location, language: language);
    }
  }
}
