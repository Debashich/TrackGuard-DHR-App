import 'dart:io';

import '../../../shared/models/ai_analysis_result.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/geo_location.dart';

abstract class AiAnalysisService {
  Future<bool> isOfflineModelAvailable();
  Future<void> initializeOfflineModel();
  Future<AiAnalysisResult> analyze({
    required File image,
    required GeoLocation location,
    required AppLanguage language,
  });
}
