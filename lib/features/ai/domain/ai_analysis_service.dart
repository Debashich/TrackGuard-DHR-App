import 'dart:io';

import '../../../shared/models/ai_analysis_result.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/geo_location.dart';
import '../data/litert_gemma_provider.dart';
import 'ai_settings.dart';

abstract class AiAnalysisService {
  Future<bool> isOfflineModelAvailable();
  Future<bool> isOnlineProviderAvailable();
  Future<void> initializeOfflineModel();

  LitertGemmaState get offlineModelState;
  Stream<LitertGemmaState> watchOfflineModelState();

  Future<AiAnalysisResult> analyze({
    required File image,
    required GeoLocation location,
    required AppLanguage language,
    AiMode? requestedMode,
  });
}
