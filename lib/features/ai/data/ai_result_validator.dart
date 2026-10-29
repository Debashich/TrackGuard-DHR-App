import 'dart:convert';

import '../../../core/errors/app_exception.dart';
import '../../../shared/models/ai_analysis_result.dart';
import '../../../shared/models/ai_provider.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/hazard_type.dart';
import '../../../shared/models/severity.dart';
import '../domain/ai_provider_config.dart';

class AiResultValidator {
  static const List<String> _forbiddenOperationalPhrases = [
    'stop the train',
    'stop train',
    'halt the train',
    'close the track',
    'close track',
    'shut down track',
    'send workers immediately',
    'dispatch repair crew',
    'ignore this hazard',
    'definitely safe',
    '100% safe',
    'completely safe',
    'guaranteed safe',
    'track is clear for all speeds',
  ];

  /// Parses and validates a raw response string or map.
  AiAnalysisResult validateString(
    String rawResponse, {
    required AiProvider provider,
    required AppLanguage requestedLanguage,
    String? modelName,
    AiProvider? requestedProvider,
    String? fallbackReason,
  }) {
    final cleaned = _extractJson(rawResponse);
    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw AiInvalidOutputException(
        'AI response could not be parsed as JSON: $e',
      );
    }

    return validate(
      parsed,
      provider: provider,
      requestedLanguage: requestedLanguage,
      modelName: modelName,
      requestedProvider: requestedProvider,
      fallbackReason: fallbackReason,
    );
  }

  AiAnalysisResult validate(
    Map<String, dynamic> rawResult, {
    required AiProvider provider,
    required AppLanguage requestedLanguage,
    String? modelName,
    AiProvider? requestedProvider,
    String? fallbackReason,
  }) {
    // 1. Validate hazardType
    final rawHazard =
        (rawResult['hazardType'] ??
                rawResult['hazard_type'] ??
                rawResult['type'])
            ?.toString();

    if (rawHazard == null || rawHazard.trim().isEmpty) {
      throw const AiValidationFailedException(
        'AI response missing required hazard type.',
      );
    }

    final normalizedHazard = _normalizeHazardType(rawHazard);
    if (normalizedHazard == null) {
      throw AiValidationFailedException(
        'Unknown hazard type: "$rawHazard". Supported: ${AiProviderConfig.supportedHazardTypes.join(", ")}',
      );
    }

    // 2. Validate severity
    final rawSeverity = rawResult['severity']?.toString();
    if (rawSeverity == null || rawSeverity.trim().isEmpty) {
      throw const AiValidationFailedException(
        'AI response missing required severity level.',
      );
    }

    final normalizedSeverity = _normalizeSeverity(rawSeverity);
    if (normalizedSeverity == null) {
      throw AiValidationFailedException(
        'Unknown severity level: "$rawSeverity". Supported: ${AiProviderConfig.supportedSeverities.join(", ")}',
      );
    }

    // 3. Validate and sanitize note
    final rawNote =
        (rawResult['note'] ?? rawResult['description'] ?? rawResult['userNote'])
            ?.toString();

    if (rawNote == null || rawNote.trim().isEmpty) {
      throw const AiValidationFailedException(
        'AI response note is empty or missing.',
      );
    }

    final sanitizedNote = sanitizeNote(rawNote.trim());

    // 4. Validate confidence
    final rawConfidence = rawResult['confidence'];
    double? normalizedConfidence;
    if (rawConfidence != null && rawConfidence is num) {
      final val = rawConfidence.toDouble();
      if (val >= 0.0 && val <= 1.0) {
        normalizedConfidence = val;
      } else {
        // Clamp out of range confidence
        normalizedConfidence = val.clamp(0.0, 1.0);
      }
    }

    return AiAnalysisResult(
      hazardType: normalizedHazard,
      severity: normalizedSeverity,
      note: sanitizedNote,
      provider: provider,
      modelName: modelName,
      language: requestedLanguage,
      confidence: normalizedConfidence,
      requestedProvider: requestedProvider,
      fallbackReason: fallbackReason,
    );
  }

  String sanitizeNote(String note) {
    var sanitized = note;

    for (final phrase in _forbiddenOperationalPhrases) {
      final regExp = RegExp(RegExp.escape(phrase), caseSensitive: false);
      if (regExp.hasMatch(sanitized)) {
        sanitized = sanitized.replaceAll(regExp, 'inspection advisory noted');
      }
    }

    if (sanitized.length > AiProviderConfig.maxNoteLength) {
      sanitized = sanitized.substring(0, AiProviderConfig.maxNoteLength);
    }

    return sanitized.trim();
  }

  HazardType? _normalizeHazardType(String value) {
    final lower = value.trim().toLowerCase();
    switch (lower) {
      case 'slip':
      case 'landslide':
        return HazardType.slip;
      case 'rockfall':
      case 'rock_fall':
      case 'falling_rocks':
        return HazardType.rockfall;
      case 'blockeddrain':
      case 'blocked_drain':
      case 'drainage':
        return HazardType.blockedDrain;
      case 'damagedwall':
      case 'damaged_wall':
      case 'retaining_wall':
        return HazardType.damagedWall;
      case 'trackdefect':
      case 'track_defect':
      case 'rail_defect':
        return HazardType.trackDefect;
      case 'vegetation':
      case 'overgrowth':
        return HazardType.vegetation;
      case 'other':
      case 'miscellaneous':
        return HazardType.other;
      default:
        return null;
    }
  }

  Severity? _normalizeSeverity(String value) {
    final lower = value.trim().toLowerCase();
    switch (lower) {
      case 'low':
        return Severity.low;
      case 'medium':
        return Severity.medium;
      case 'high':
        return Severity.high;
      case 'critical':
        return Severity.critical;
      default:
        return null;
    }
  }

  String _extractJson(String response) {
    final trimmed = response.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed;
    }

    // Try finding code block ```json ... ```
    final codeBlockMatch = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```')
        .firstMatch(trimmed);
    if (codeBlockMatch != null && codeBlockMatch.group(1) != null) {
      return codeBlockMatch.group(1)!.trim();
    }

    // Try finding first { and last }
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return trimmed.substring(start, end + 1);
    }

    return trimmed;
  }
}
