import 'dart:io';

import '../../../shared/models/ai_analysis_result.dart';
import '../../../shared/models/ai_provider.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/hazard_type.dart';
import '../../../shared/models/severity.dart';

class HeuristicAiProvider {
  Future<AiAnalysisResult> analyze({
    required File image,
    required GeoLocation location,
    required AppLanguage language,
  }) async {
    // Determine deterministic hazard based on location context
    HazardType suggestedType;
    Severity suggestedSeverity;
    final km = location.kmMarker ?? 51.0;

    if (km > 70.0 && km < 75.0) {
      // High altitude Ghum ridge: rockfall or drainage obstruction
      suggestedType = HazardType.rockfall;
      suggestedSeverity = Severity.medium;
    } else if (km >= 75.0 && km < 82.0) {
      // Batasia loop slope: slope slip or retaining wall
      suggestedType = HazardType.slip;
      suggestedSeverity = Severity.high;
    } else {
      // Lower curves & cuttings: blocked drain or damaged wall
      suggestedType = HazardType.blockedDrain;
      suggestedSeverity = Severity.medium;
    }

    final note = _getLocalizedNote(suggestedType, location, language);

    return AiAnalysisResult(
      hazardType: suggestedType,
      severity: suggestedSeverity,
      note: note,
      provider: AiProvider.heuristic,
      modelName: null, // Heuristic has no model name
      language: language,
      confidence: 0.55,
    );
  }

  String _getLocalizedNote(
    HazardType type,
    GeoLocation location,
    AppLanguage language,
  ) {
    final station = location.nearestStationName ?? 'Track alignment';
    switch (language) {
      case AppLanguage.hi:
        return 'ह्यूरिस्टिक फॉलबैक: $station के पास संभावित ${type.name} का पता चला। मानवीय पुष्टि आवश्यक है।';
      case AppLanguage.bn:
        return 'হিউরিস্টিক ফলব্যাক: $station-এর কাছে সম্ভাব্য ${type.name} চিহ্নিত। মানবিক যাচাই আবশ্যক।';
      case AppLanguage.ne:
        return 'ह्युरिस्टिक विकल्प: $station नजिक सम्भावित ${type.name} देखिएको छ। मानव पुष्टि आवश्यक छ।';
      case AppLanguage.en:
        return 'Heuristic fallback: Potential ${type.name} identified near $station. Permanent-way inspection required.';
    }
  }
}
