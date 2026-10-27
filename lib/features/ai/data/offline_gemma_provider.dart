import 'dart:convert';
import 'dart:io';

import '../../../core/errors/app_exception.dart';
import '../../../shared/models/ai_analysis_result.dart';
import '../../../shared/models/ai_provider.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/hazard_type.dart';
import '../../../shared/models/severity.dart';

class OfflineGemmaProvider {
  bool _isInitialized = false;

  bool get isReady => _isInitialized;

  Future<bool> isModelInstalled() async {
    // In Phase 1, Cactus Gemma model binary is checked on device storage
    // If not present, returns false safely without throwing
    return false;
  }

  Future<void> initialize() async {
    // Adapter hook for Cactus Flutter/native bindings
    _isInitialized = false;
  }

  Future<AiAnalysisResult> analyze({
    required File image,
    required GeoLocation location,
    required AppLanguage language,
  }) async {
    if (!_isInitialized) {
      throw const AiUnavailableException(
        'Offline Gemma model is not installed on this device.',
      );
    }

    // Cactus execution would return structured JSON:
    // { "type": "rockfall", "severity": "high", "note": "..." }
    const rawJson =
        '{"type":"rockfall","severity":"medium","note":"Observed loose debris near alignment."}';
    return parseAndSanitize(rawJson, language);
  }

  static AiAnalysisResult parseAndSanitize(
    String rawOutput,
    AppLanguage language,
  ) {
    try {
      final Map<String, dynamic> data = jsonDecode(rawOutput);
      final rawType = data['type'] as String?;
      final rawSeverity = data['severity'] as String?;
      final rawNote = data['note'] as String?;

      final sanitizedType = HazardType.fromString(rawType);
      final sanitizedSeverity = Severity.fromString(rawSeverity);
      final sanitizedNote = _sanitizeNote(rawNote);

      return AiAnalysisResult(
        hazardType: sanitizedType,
        severity: sanitizedSeverity,
        note: sanitizedNote,
        provider: AiProvider.offlineGemma,
        modelName: 'Gemma 4 E2B (LiteRT)',
        language: language,
        confidence: 0.82,
      );
    } catch (e) {
      throw AiInvalidOutputException('Failed to parse AI output: $e');
    }
  }

  static String _sanitizeNote(String? note) {
    if (note == null || note.trim().isEmpty) {
      return 'Advisory observation: Surface anomaly noted near track.';
    }
    // Safety check: ensure no direct operational command (stop train, etc.)
    final lower = note.toLowerCase();
    if (lower.contains('stop train') || lower.contains('close track')) {
      return note.replaceAll(
        RegExp(r'(stop train|close track)', caseSensitive: false),
        'inspection required',
      );
    }
    return note.trim();
  }
}
