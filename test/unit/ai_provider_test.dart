import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/core/errors/app_exception.dart';
import 'package:trackguard_dhr/features/ai/data/heuristic_ai_provider.dart';
import 'package:trackguard_dhr/features/ai/data/offline_gemma_provider.dart';
import 'package:trackguard_dhr/shared/models/ai_provider.dart';
import 'package:trackguard_dhr/shared/models/app_language.dart';
import 'package:trackguard_dhr/shared/models/geo_location.dart';
import 'package:trackguard_dhr/shared/models/hazard_type.dart';
import 'package:trackguard_dhr/shared/models/location_source.dart';
import 'package:trackguard_dhr/shared/models/severity.dart';

void main() {
  group('AI Provider & Sanitization Tests', () {
    test('OfflineGemmaProvider parses valid structured JSON', () {
      const json =
          '{"type":"rockfall","severity":"high","note":"Loose rocks on cutting slope."}';
      final result = OfflineGemmaProvider.parseAndSanitize(
        json,
        AppLanguage.en,
      );

      expect(result.hazardType, HazardType.rockfall);
      expect(result.severity, Severity.high);
      expect(result.note, 'Loose rocks on cutting slope.');
      expect(result.provider, AiProvider.offlineGemma);
      expect(result.confidence, greaterThan(0.8));
    });

    test('OfflineGemmaProvider sanitizes operational directives', () {
      const json =
          '{"type":"slip","severity":"critical","note":"Danger! Stop train immediately and close track."}';
      final result = OfflineGemmaProvider.parseAndSanitize(
        json,
        AppLanguage.en,
      );

      expect(result.hazardType, HazardType.slip);
      expect(result.severity, Severity.critical);
      // Operational commands must be filtered out
      expect(result.note?.contains('stop train'), false);
      expect(result.note?.contains('close track'), false);
    });

    test('OfflineGemmaProvider throws on corrupted JSON', () {
      const corruptedJson = '{invalid json string}';
      expect(
        () => OfflineGemmaProvider.parseAndSanitize(
          corruptedJson,
          AppLanguage.en,
        ),
        throwsA(isA<AiInvalidOutputException>()),
      );
    });

    test('HeuristicAiProvider generates deterministic suggestion and localized note', () async {
      final provider = HeuristicAiProvider();
      final dummyFile = File('dummy.jpg');
      final location = GeoLocation(
        kmMarker: 72.0,
        sectionId: 'kurseong-ghum',
        nearestStationName: 'Ghum Ridge',
        capturedAt: DateTime.now(),
        source: LocationSource.gps,
      );

      final resultEn = await provider.analyze(
        image: dummyFile,
        location: location,
        language: AppLanguage.en,
      );
      expect(resultEn.provider, AiProvider.heuristic);
      expect(resultEn.hazardType, HazardType.rockfall);
      expect(resultEn.note?.contains('Ghum Ridge'), true);

      final resultHi = await provider.analyze(
        image: dummyFile,
        location: location,
        language: AppLanguage.hi,
      );
      expect(resultHi.note?.contains('ह्यूरिस्टिक फॉलबैक'), true);

      final resultBn = await provider.analyze(
        image: dummyFile,
        location: location,
        language: AppLanguage.bn,
      );
      expect(resultBn.note?.contains('হিউরিস্টিক ফলব্যাক'), true);

      final resultNe = await provider.analyze(
        image: dummyFile,
        location: location,
        language: AppLanguage.ne,
      );
      expect(resultNe.note?.contains('ह्युरिस्टिक विकल्प'), true);
    });
  });
}
