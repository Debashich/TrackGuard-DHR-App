import '../../../shared/models/ai_analysis_result.dart';
import '../../../shared/models/ai_provider.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/hazard_type.dart';
import '../../../shared/models/severity.dart';

class ManualAiProvider {
  Future<AiAnalysisResult> analyze({
    required GeoLocation location,
    required AppLanguage language,
  }) async {
    return AiAnalysisResult(
      hazardType: HazardType.other,
      severity: Severity.medium,
      note: 'Manual report created by permanent-way inspector.',
      provider: AiProvider.manual,
      modelName: null,
      language: language,
      confidence: 1.0,
    );
  }
}
