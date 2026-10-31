import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/core/connectivity/connectivity_service.dart';
import 'package:trackguard_dhr/core/errors/ai_error_mapper.dart';
import 'package:trackguard_dhr/core/errors/app_exception.dart';
import 'package:trackguard_dhr/features/ai/data/ai_analysis_service_impl.dart';
import 'package:trackguard_dhr/features/ai/data/ai_prompt_builder.dart';
import 'package:trackguard_dhr/features/ai/data/ai_result_validator.dart';
import 'package:trackguard_dhr/features/ai/data/cactus_gemma_provider.dart';
import 'package:trackguard_dhr/features/ai/data/heuristic_ai_provider.dart';
import 'package:trackguard_dhr/features/ai/data/online_gemini_provider.dart';
import 'package:trackguard_dhr/features/ai/domain/ai_provider_config.dart';
import 'package:trackguard_dhr/features/ai/domain/ai_settings.dart';
import 'package:trackguard_dhr/l10n/app_localizations.dart';
import 'package:trackguard_dhr/shared/models/ai_analysis_result.dart';
import 'package:trackguard_dhr/shared/models/ai_provider.dart';
import 'package:trackguard_dhr/shared/models/app_language.dart';
import 'package:trackguard_dhr/shared/models/geo_location.dart';
import 'package:trackguard_dhr/shared/models/hazard_type.dart';
import 'package:trackguard_dhr/shared/models/location_source.dart';
import 'package:trackguard_dhr/shared/models/severity.dart';

class _MockConnectivityService implements ConnectivityService {
  final bool online;
  _MockConnectivityService([this.online = true]);

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> watchOnlineStatus() => Stream.value(online);
}

class _MockCactusGemmaProvider extends CactusGemmaProvider {
  final bool ready;

  _MockCactusGemmaProvider({this.ready = true});

  @override
  bool get isReady => ready;

  @override
  CactusGemmaState get state =>
      ready ? CactusGemmaState.ready : CactusGemmaState.notInstalled;

  @override
  Future<bool> isModelInstalled() async => ready;

  @override
  Future<AiAnalysisResult> analyze({
    required File image,
    required GeoLocation location,
    required AppLanguage language,
  }) async {
    return AiAnalysisResult(
      hazardType: HazardType.rockfall,
      severity: Severity.high,
      note: 'Loose boulders observed along the track cutting.',
      provider: AiProvider.offlineGemma,
      modelName: AiProviderConfig.offlineGemmaModelName,
      language: language,
      confidence: 0.88,
    );
  }
}

class _MockOnlineGeminiProvider extends OnlineGeminiProvider {
  final bool available;

  _MockOnlineGeminiProvider({this.available = true})
    : super(connectivityService: _MockConnectivityService(available));

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<AiAnalysisResult> analyze({
    required File image,
    required GeoLocation location,
    required AppLanguage language,
  }) async {
    if (!available) {
      throw const GeminiUnavailableException('Device is offline');
    }
    return AiAnalysisResult(
      hazardType: HazardType.slip,
      severity: Severity.critical,
      note: 'Major embankment slip noted near culvert.',
      provider: AiProvider.onlineGemini,
      modelName: AiProviderConfig.onlineGeminiModelLabel,
      language: language,
      confidence: 0.94,
    );
  }
}

void main() {
  final testLocation = GeoLocation(
    latitude: 26.9833,
    longitude: 88.2833,
    accuracyMeters: 5.0,
    source: LocationSource.gps,
    capturedAt: DateTime(2026, 10, 29, 12, 0),
    kmMarker: 64.5,
    sectionId: 'kurseong-ghum',
    nearestStationName: 'Sonada',
  );

  group('AiPromptBuilder Tests', () {
    final builder = AiPromptBuilder();

    test('Includes location context and prompt version', () {
      final prompt = builder.buildPrompt(
        language: AppLanguage.en,
        location: testLocation,
      );

      expect(prompt, contains('Sonada'));
      expect(prompt, contains('Km 64.5'));
      expect(prompt, contains(AiProviderConfig.promptVersion));
      expect(prompt, contains('slip, rockfall, blockedDrain'));
      expect(prompt, contains('low, medium, high, critical'));
      expect(prompt, contains('ADVISORY ONLY'));
    });

    test('Generates language-specific directives for all 4 languages', () {
      final promptEn = builder.buildPrompt(
        language: AppLanguage.en,
        location: testLocation,
      );
      expect(promptEn, contains('English'));

      final promptHi = builder.buildPrompt(
        language: AppLanguage.hi,
        location: testLocation,
      );
      expect(promptHi, contains('Hindi (हिंदी)'));

      final promptBn = builder.buildPrompt(
        language: AppLanguage.bn,
        location: testLocation,
      );
      expect(promptBn, contains('Bengali (বাংলা)'));

      final promptNe = builder.buildPrompt(
        language: AppLanguage.ne,
        location: testLocation,
      );
      expect(promptNe, contains('Nepali (नेपाली)'));
    });
  });

  group('AiResultValidator Tests', () {
    final validator = AiResultValidator();

    test('Parses and normalizes valid JSON output', () {
      const rawJson = '''
      {
        "hazardType": "rockfall",
        "severity": "high",
        "note": "Rock debris observed adjacent to outer rail.",
        "confidence": 0.88
      }
      ''';

      final result = validator.validateString(
        rawJson,
        provider: AiProvider.offlineGemma,
        requestedLanguage: AppLanguage.en,
        modelName: 'Gemma 4 E2B',
      );

      expect(result.hazardType, HazardType.rockfall);
      expect(result.severity, Severity.high);
      expect(result.note, 'Rock debris observed adjacent to outer rail.');
      expect(result.confidence, 0.88);
      expect(result.provider, AiProvider.offlineGemma);
    });

    test('Throws on malformed non-JSON output', () {
      expect(
        () => validator.validateString(
          'This is plain text with no json',
          provider: AiProvider.offlineGemma,
          requestedLanguage: AppLanguage.en,
        ),
        throwsA(isA<AiInvalidOutputException>()),
      );
    });

    test('Throws on unknown hazard type', () {
      const jsonUnknownHazard = '''
      {
        "hazardType": "alien_invasion",
        "severity": "high",
        "note": "Unidentified hazard."
      }
      ''';

      expect(
        () => validator.validateString(
          jsonUnknownHazard,
          provider: AiProvider.offlineGemma,
          requestedLanguage: AppLanguage.en,
        ),
        throwsA(isA<AiValidationFailedException>()),
      );
    });

    test('Throws on unknown severity level', () {
      const jsonUnknownSeverity = '''
      {
        "hazardType": "slip",
        "severity": "apocalyptic",
        "note": "Slope sliding."
      }
      ''';

      expect(
        () => validator.validateString(
          jsonUnknownSeverity,
          provider: AiProvider.offlineGemma,
          requestedLanguage: AppLanguage.en,
        ),
        throwsA(isA<AiValidationFailedException>()),
      );
    });

    test('Throws on empty note', () {
      const jsonEmptyNote = '''
      {
        "hazardType": "slip",
        "severity": "medium",
        "note": "   "
      }
      ''';

      expect(
        () => validator.validateString(
          jsonEmptyNote,
          provider: AiProvider.offlineGemma,
          requestedLanguage: AppLanguage.en,
        ),
        throwsA(isA<AiValidationFailedException>()),
      );
    });

    test('Clamps out-of-range confidence safely', () {
      const jsonOverConfidence = '''
      {
        "hazardType": "vegetation",
        "severity": "low",
        "note": "Bushes overhanging rail.",
        "confidence": 1.75
      }
      ''';

      final result = validator.validateString(
        jsonOverConfidence,
        provider: AiProvider.offlineGemma,
        requestedLanguage: AppLanguage.en,
      );

      expect(result.confidence, 1.0);
    });

    test('Sanitizes operational instructions into advisory observations', () {
      final sanitized = validator.sanitizeNote(
        'Danger! Stop the train immediately and close track before proceeding.',
      );

      expect(sanitized, isNot(contains('Stop the train')));
      expect(sanitized, isNot(contains('close track')));
      expect(sanitized, contains('inspection advisory noted'));
    });
  });

  group('Provider Selection & Fallback Rules Tests', () {
    final dummyFile = File('dummy_image.jpg');

    test('Manual mode immediately returns manual classification', () async {
      final service = AiAnalysisServiceImpl(
        cactusGemma: _MockCactusGemmaProvider(ready: true),
        onlineGemini: _MockOnlineGeminiProvider(available: true),
      );

      final result = await service.analyze(
        image: dummyFile,
        location: testLocation,
        language: AppLanguage.en,
        requestedMode: AiMode.manual,
      );

      expect(result.provider, AiProvider.manual);
      expect(result.requestedProvider, AiProvider.manual);
      expect(result.modelName, isNull);
    });

    test('Offline Gemma mode uses Cactus Gemma when ready', () async {
      final service = AiAnalysisServiceImpl(
        cactusGemma: _MockCactusGemmaProvider(ready: true),
        onlineGemini: _MockOnlineGeminiProvider(available: false),
      );

      final result = await service.analyze(
        image: dummyFile,
        location: testLocation,
        language: AppLanguage.en,
        requestedMode: AiMode.offlineGemma,
      );

      expect(result.provider, AiProvider.offlineGemma);
      expect(result.modelName, AiProviderConfig.offlineGemmaModelName);
    });

    test(
      'Offline Gemma mode throws when Gemma is not ready',
      () async {
        final service = AiAnalysisServiceImpl(
          cactusGemma: _MockCactusGemmaProvider(ready: false),
        );

        await expectLater(
          () => service.analyze(
            image: dummyFile,
            location: testLocation,
            language: AppLanguage.en,
            requestedMode: AiMode.offlineGemma,
          ),
          throwsA(isA<OfflineModelUnavailableException>()),
        );
      },
    );

    test('Online Gemini mode uses Gemini cloud when available', () async {
      final service = AiAnalysisServiceImpl(
        cactusGemma: _MockCactusGemmaProvider(ready: false),
        onlineGemini: _MockOnlineGeminiProvider(available: true),
      );

      final result = await service.analyze(
        image: dummyFile,
        location: testLocation,
        language: AppLanguage.en,
        requestedMode: AiMode.onlineGemini,
      );

      expect(result.provider, AiProvider.onlineGemini);
      expect(result.modelName, AiProviderConfig.onlineGeminiModelLabel);
    });

    test(
      'Online Gemini mode falls back to Offline Gemma when cloud is offline',
      () async {
        final service = AiAnalysisServiceImpl(
          cactusGemma: _MockCactusGemmaProvider(ready: true),
          onlineGemini: _MockOnlineGeminiProvider(available: false),
        );

        final result = await service.analyze(
          image: dummyFile,
          location: testLocation,
          language: AppLanguage.en,
          requestedMode: AiMode.onlineGemini,
        );

        expect(result.provider, AiProvider.offlineGemma);
        expect(result.requestedProvider, AiProvider.onlineGemini);
        expect(result.fallbackReason, contains('Online Gemini unavailable'));
      },
    );

    test(
      'Automatic mode prefers Offline Gemma for privacy/offline operation',
      () async {
        final service = AiAnalysisServiceImpl(
          cactusGemma: _MockCactusGemmaProvider(ready: true),
          onlineGemini: _MockOnlineGeminiProvider(available: true),
        );

        final result = await service.analyze(
          image: dummyFile,
          location: testLocation,
          language: AppLanguage.en,
          requestedMode: AiMode.automatic,
        );

        expect(result.provider, AiProvider.offlineGemma);
      },
    );

    test(
      'Automatic mode uses Online Gemini when Offline Gemma is not ready',
      () async {
        final service = AiAnalysisServiceImpl(
          cactusGemma: _MockCactusGemmaProvider(ready: false),
          onlineGemini: _MockOnlineGeminiProvider(available: true),
        );

        final result = await service.analyze(
          image: dummyFile,
          location: testLocation,
          language: AppLanguage.en,
          requestedMode: AiMode.automatic,
        );

        expect(result.provider, AiProvider.onlineGemini);
      },
    );
  });

  group('AiErrorMapper Tests', () {
    testWidgets('Maps typed AI exceptions to localized messages', (
      tester,
    ) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        AiErrorMapper.getLocalizedMessage(
          const OfflineModelUnavailableException(),
          l10n,
        ),
        l10n.aiGemmaUnavailable,
      );

      expect(
        AiErrorMapper.getLocalizedMessage(
          const GeminiUnavailableException(),
          l10n,
        ),
        l10n.aiGeminiRequiresNetwork,
      );

      expect(
        AiErrorMapper.getLocalizedMessage(
          const GeminiRateLimitedException(),
          l10n,
        ),
        l10n.aiRateLimited,
      );

      expect(
        AiErrorMapper.getLocalizedMessage(const GeminiTimeoutException(), l10n),
        l10n.aiTimeout,
      );

      expect(
        AiErrorMapper.getLocalizedMessage(
          const AiImageTooLargeException(),
          l10n,
        ),
        l10n.aiImageTooLarge,
      );
    });

    test('canRetry accurately checks error retry viability', () {
      expect(AiErrorMapper.canRetry(const GeminiTimeoutException()), isTrue);
      expect(
        AiErrorMapper.canRetry(const GeminiRateLimitedException()),
        isTrue,
      );
      expect(
        AiErrorMapper.canRetry(const GeminiUnauthorizedException()),
        isFalse,
      );
      expect(
        AiErrorMapper.canRetry(const OfflineModelUnavailableException()),
        isFalse,
      );
    });
  });

  group('AiSettings Model Tests', () {
    test('AiSettings serialization and copyWith work as expected', () {
      const original = AiSettings(
        mode: AiMode.offlineGemma,
        allowOnlineGemini: false,
        allowOfflineGemma: true,
        saveImagesForAi: true,
        requireHumanConfirmation: true,
      );

      final json = original.toJson();
      final restored = AiSettings.fromJson(json);

      expect(restored.mode, AiMode.offlineGemma);
      expect(restored.allowOnlineGemini, isFalse);
      expect(restored.allowOfflineGemma, isTrue);
      expect(restored.saveImagesForAi, isTrue);
      expect(restored.requireHumanConfirmation, isTrue);

      final modified = original.copyWith(mode: AiMode.onlineGemini);
      expect(modified.mode, AiMode.onlineGemini);
      expect(modified.allowOnlineGemini, isFalse);
    });
  });
}
