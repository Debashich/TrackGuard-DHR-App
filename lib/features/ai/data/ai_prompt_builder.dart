import '../../../shared/models/app_language.dart';
import '../../../shared/models/geo_location.dart';
import '../domain/ai_provider_config.dart';

class AiPromptBuilder {
  static const String defaultSchema = '''
{
  "hazardType": "slip | rockfall | blockedDrain | damagedWall | trackDefect | vegetation | other",
  "severity": "low | medium | high | critical",
  "note": "Short observational description in the requested language (max 300 characters)",
  "confidence": 0.0 to 1.0
}
''';

  String buildPrompt({
    required AppLanguage language,
    required GeoLocation location,
    String responseSchema = defaultSchema,
  }) {
    final languageDirective = _getLanguageDirective(language);
    final stationContext = location.nearestStationName != null
        ? 'Nearest Station Context: ${location.nearestStationName}'
        : 'Alignment Section Context: ${location.sectionId}';
    final kmContext = location.kmMarker != null
        ? 'Kilometre Context: Km ${location.kmMarker!.toStringAsFixed(1)}'
        : 'Kilometre Marker: Unknown';

    return '''
You are TrackGuard AI, an advisory track-inspection assistant for permanent-way staff on the Darjeeling Himalayan Railway (DHR).
Analyze the provided alignment photograph and identify potential railway hazards.

CRITICAL INSTRUCTIONS & SAFETY RULES:
1. ADVISORY ONLY: Provide observational descriptions only. NEVER issue operational commands such as "stop the train", "close the track", "dispatch workers immediately", or "safe for travel".
2. NO CERTAINTY CLAIMS: Frame all observations as advisory indicators (e.g., "Debris observed near the outer rail").
3. DO NOT FABRICATE: Do not invent GPS coordinates, chainage markers, or station names.
4. LOCATION IS CONTEXT ONLY: Use the provided location metadata solely as regional context, not as proof of what is visible in the photograph.
5. STRICT OUTPUT: Respond ONLY with valid, minified JSON matching the exact schema below. Do not wrap in markdown or add conversational preamble.

LOCATION CONTEXT:
- $stationContext
- $kmContext

SUPPORTED HAZARD TYPES (Choose exactly one):
${AiProviderConfig.supportedHazardTypes.join(', ')}

SUPPORTED SEVERITIES (Choose exactly one):
${AiProviderConfig.supportedSeverities.join(', ')}

LANGUAGE REQUIREMENT:
$languageDirective

EXPECTED JSON SCHEMA:
$responseSchema

PROMPT VERSION: ${AiProviderConfig.promptVersion}
''';
  }

  String _getLanguageDirective(AppLanguage language) {
    switch (language) {
      case AppLanguage.hi:
        return 'The "note" field MUST be written in natural, grammatically correct Hindi (हिंदी). Example: "ट्रैक के किनारे ढीले पत्थर दिखाई दे रहे हैं।"';
      case AppLanguage.bn:
        return 'The "note" field MUST be written in natural, grammatically correct Bengali (বাংলা). Example: "লাইনের পাশে আলগা পাথর দেখা যাচ্ছে।"';
      case AppLanguage.ne:
        return 'The "note" field MUST be written in natural, grammatically correct Nepali (नेपाली). Example: "ट्र्याक नजिक खुकुलो ढुङ्गाहरू देखिएका छन्।"';
      case AppLanguage.en:
        return 'The "note" field MUST be written in plain, professional English. Example: "Loose rock debris observed adjacent to outer rail."';
    }
  }
}
