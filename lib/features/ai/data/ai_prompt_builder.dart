import '../../../shared/models/app_language.dart';
import '../../../shared/models/geo_location.dart';
import '../domain/ai_provider_config.dart';

class AiPromptBuilder {
  static const String defaultSchema = '''
{
  "observedDefects": "Concise factual observation of primary physical damage or condition",
  "hazardType": "trackDefect | slip | rockfall | blockedDrain | damagedWall | vegetation | other",
  "severity": "critical | high | medium | low",
  "note": "Concise human-facing inspection note in the requested language (max 250 characters)",
  "confidence": 0.0 to 1.0
}
''';

  /// Builds the persistent system prompt defining role, domain rules, and defect priority hierarchy.
  String buildSystemPrompt({String responseSchema = defaultSchema}) {
    return '''
You are TrackGuard AI, an expert permanent-way track inspection assistant for the Darjeeling Himalayan Railway (DHR).
Your objective is to inspect railway alignment photographs, identify critical track infrastructure defects, and classify hazards accurately.

PRIORITY DEFECT HIERARCHY (Identify and report the highest-priority defect visible):
1. TRACK DEFECTS (`trackDefect`): Broken, cracked, fractured, or disconnected steel rails; rail gaps; broken, split, decayed, or displaced wooden/concrete sleepers (ties); missing fishplates or clips. THIS OUTRANKS ALL OTHER OBSERVATIONS.
2. EMBANKMENT SLIPS & WASHOUTS (`slip`): Foundation subsidence, track bed erosion, sliding hillside beneath the track, or soil displacement undermining sleepers.
3. ROCKFALL (`rockfall`): Large fallen boulders, detached rocks, or landslide debris that have fallen ONTO the tracks from mountain cuttings (distinct from normal ballast).
4. BLOCKED DRAINS & WATER (`blockedDrain`): Water pooling on or over the tracks, clogged hillside catchpits, or flooded side culverts.
5. DAMAGED RETAINING WALLS (`damagedWall`): Collapsed, cracked, or bulging stone masonry revetments alongside the track.
6. VEGETATION (`vegetation`): Thick bushes, fallen trees, or heavy overgrowth physically obstructing train passage over the rails (report ONLY if no structural defects exist).

CRITICAL DOMAIN RULES:
- Crushed stone ballast under and around the rails is NORMAL railway foundation. DO NOT report normal ballast stones as "rockfall" or "slip"!
- Minor grass or ground cover on the track bed is NORMAL. DO NOT report grass as "vegetation" hazard unless severe overgrowth physically covers the rails or blocks trains!
- If broken/cracked rails OR broken/displaced sleepers are visible, you MUST classify the hazard as `trackDefect`!

SEVERITY GUIDELINES:
- `critical`: Broken rails, gaps or severe fractures in the rail head, complete track washouts threatening immediate derailment.
- `high`: Broken, split, or displaced sleepers; unstable boulders near track; bulging masonry walls.
- `medium`: Maintenance defects (loose fasteners, partial drainage clogging, moderate wear).
- `low`: Minor advisory observations (isolated edge vegetation, cosmetic weathering).

SAFETY & COMPLIANCE:
- ADVISORY ONLY: Provide observational descriptions only. NEVER issue operational commands such as "stop the train", "close the track", or "safe for travel".
- STRICT OUTPUT: Respond ONLY with valid, minified JSON matching the exact schema below. Do not wrap in markdown or add conversational preamble.

EXPECTED JSON SCHEMA:
$responseSchema

SUPPORTED HAZARD TYPES: ${AiProviderConfig.supportedHazardTypes.join(', ')}
SUPPORTED SEVERITIES: ${AiProviderConfig.supportedSeverities.join(', ')}
PROMPT VERSION: ${AiProviderConfig.promptVersion}
''';
  }

  /// Builds the contextual user prompt containing location metadata and language directives.
  String buildUserPrompt({
    required AppLanguage language,
    required GeoLocation location,
  }) {
    final languageDirective = _getLanguageDirective(language);
    final stationContext = location.nearestStationName != null
        ? 'Nearest Station: ${location.nearestStationName}'
        : 'Alignment Section: ${location.sectionId}';
    final kmContext = location.kmMarker != null
        ? 'Kilometre: Km ${location.kmMarker!.toStringAsFixed(1)}'
        : 'Kilometre: Unknown';

    return '''
Inspect the railway photograph and identify the primary structural defect according to the priority hierarchy.

LOCATION CONTEXT:
- $stationContext
- $kmContext

LANGUAGE REQUIREMENT:
$languageDirective

Output valid JSON only:
''';
  }

  /// Combined prompt for single-message interfaces (e.g., OpenRouter / Gemini Cloud).
  String buildPrompt({
    required AppLanguage language,
    required GeoLocation location,
    String responseSchema = defaultSchema,
  }) {
    return '${buildSystemPrompt(responseSchema: responseSchema)}\n\n${buildUserPrompt(language: language, location: location)}';
  }

  String _getLanguageDirective(AppLanguage language) {
    switch (language) {
      case AppLanguage.hi:
        return 'The "note" field MUST be written in professional Hindi (हिंदी), accurately describing the primary structural defect (e.g., "<स्थिति> <स्थान पर> देखी गई")।';
      case AppLanguage.bn:
        return 'The "note" field MUST be written in professional Bengali (বাংলা), accurately describing the primary structural defect (e.g., "<ত্রুটি> <স্থানে> পরিলক্ষিত হয়েছে")।';
      case AppLanguage.ne:
        return 'The "note" field MUST be written in professional Nepali (नेपाली), accurately describing the primary structural defect (e.g., "<त्रुटि> <स्थानमा> देखिएको छ")।';
      case AppLanguage.en:
        return 'The "note" field MUST be written in clear, factual English describing the primary structural defect (e.g., "<observed defect> at <location in frame>").';
    }
  }
}
