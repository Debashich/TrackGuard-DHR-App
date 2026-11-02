import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/core/connectivity/connectivity_service.dart';
import 'package:trackguard_dhr/core/errors/app_exception.dart';
import 'package:trackguard_dhr/features/ai/application/ai_startup_initializer.dart';
import 'package:trackguard_dhr/features/ai/data/huggingface_model_downloader.dart';
import 'package:trackguard_dhr/features/ai/data/litert_offline_model_manager.dart';
import 'package:trackguard_dhr/features/ai/data/offline_model_artifact_validator.dart';
import 'package:trackguard_dhr/features/ai/domain/ai_provider_config.dart';
import 'package:trackguard_dhr/features/ai/domain/offline_model_manager.dart';
import 'package:trackguard_dhr/features/ai/domain/offline_model_state.dart';

class _MockConnectivityService implements ConnectivityService {
  bool online;
  _MockConnectivityService({this.online = true});

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> watchOnlineStatus() => Stream.value(online);
}

class _TestOfflineModelManager implements OfflineModelManager {
  OfflineModelState state;
  bool initializeCalled = false;
  bool downloadCalled = false;

  _TestOfflineModelManager({required this.state});

  @override
  Stream<OfflineModelState> watchState() => Stream.value(state);

  @override
  Future<OfflineModelState> getState() async => state;

  @override
  Future<void> checkAvailability() async {}

  @override
  Future<void> download() async {
    downloadCalled = true;
  }

  @override
  Future<void> cancelDownload() async {}

  @override
  Future<void> initialize() async {
    initializeCalled = true;
    state = state.copyWith(status: OfflineModelStatus.ready);
  }

  @override
  Future<void> deleteModel() async {}

  @override
  OfflineModelDownloadSettings getDownloadSettings() =>
      const OfflineModelDownloadSettings();

  @override
  Future<void> setDownloadSettings(OfflineModelDownloadSettings settings) async {}

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('trackguard_offline_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
            return tempDir.path;
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('OfflineModelState & Settings Model Tests', () {
    test('Default OfflineModelState initializes with expected defaults', () {
      const state = OfflineModelState();
      expect(state.status, equals(OfflineModelStatus.notDownloaded));
      expect(state.isReady, isFalse);
      expect(state.isDownloading, isFalse);
      expect(state.needsDownload, isTrue);
      expect(state.downloadedBytes, equals(0));
      expect(state.progress, equals(0.0));
      expect(state.formattedDownloadedSize, equals('0 MB'));
      expect(state.formattedTotalSize, equals('~2.6 GB'));
      expect(state.filename, equals('gemma-4-E2B-it.litertlm'));
    });

    test('Formatted sizes calculate MB and GB properly', () {
      final state = const OfflineModelState().copyWith(
        downloadedBytes: 500 * 1024 * 1024,
        totalBytes: 2600 * 1024 * 1024,
        progress: 0.19,
      );
      expect(state.formattedDownloadedSize, equals('500.0 MB'));
      expect(state.formattedTotalSize, equals('2.54 GB'));
      expect(state.progressPercent, equals(19));
    });

    test('OfflineModelState JSON serialization works roundtrip', () {
      final now = DateTime.now();
      final state = const OfflineModelState().copyWith(
        status: OfflineModelStatus.ready,
        version: 'litertlm-gemma4-e2b-v1',
        repository: 'litert-community/gemma-4-E2B-it-litert-lm',
        filename: 'gemma-4-E2B-it.litertlm',
        downloadedBytes: 1000,
        totalBytes: 1000,
        downloadedAt: now,
      );
      final json = state.toJson();
      final restored = OfflineModelState.fromJson(json);

      expect(restored.status, equals(OfflineModelStatus.ready));
      expect(restored.version, equals('litertlm-gemma4-e2b-v1'));
      expect(
        restored.repository,
        equals('litert-community/gemma-4-E2B-it-litert-lm'),
      );
      expect(restored.filename, equals('gemma-4-E2B-it.litertlm'));
      expect(restored.downloadedBytes, equals(1000));
      expect(restored.canDelete, isTrue);
    });

    test('OfflineModelDownloadSettings serialization works roundtrip', () {
      const settings = OfflineModelDownloadSettings(
        wifiOnly: true,
        allowCellularDownload: false,
        huggingFaceToken: 'hf_sample_token',
      );
      final json = settings.toJson();
      final restored = OfflineModelDownloadSettings.fromJson(json);

      expect(restored.wifiOnly, isTrue);
      expect(restored.allowCellularDownload, isFalse);
      expect(restored.huggingFaceToken, equals('hf_sample_token'));
    });
  });

  group('HuggingFaceModelDownloader Tests', () {
    test('Builds valid Hugging Face resolve URL with ?download=true', () {
      final url = HuggingFaceModelDownloader.buildResolveUrl(
        repository: 'litert-community/gemma-4-E2B-it-litert-lm',
        file: 'gemma-4-E2B-it.litertlm',
        branch: 'main',
      );
      expect(
        url,
        equals(
          'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm?download=true',
        ),
      );
    });

    test('Trims slashes and defaults to main branch in resolve URL', () {
      final url = HuggingFaceModelDownloader.buildResolveUrl(
        repository: '/litert-community/gemma-4-E2B-it-litert-lm/',
        file: '/gemma-4-E2B-it.litertlm',
        branch: '',
      );
      expect(
        url,
        equals(
          'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm?download=true',
        ),
      );
    });
  });

  group('OfflineModelArtifactValidator Tests', () {
    const validator = OfflineModelArtifactValidator();

    test('Fails when model directory does not exist', () async {
      final res = await validator.validateArtifact(
        directoryPath: '${tempDir.path}/non_existent_dir',
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('does not exist'));
    });

    test('Fails when directory contains only small placeholder or manifest', () async {
      final modelDir = Directory('${tempDir.path}/models/${AiProviderConfig.offlineGemmaSlug}');
      await modelDir.create(recursive: true);
      final manifest = File('${modelDir.path}/manifest.json');
      await manifest.writeAsString('{"model":"placeholder"}');

      final res = await validator.validateArtifact(
        directoryPath: modelDir.path,
        minSizeBytes: 1024 * 1024,
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('No valid model weight artifact'));
    });

    test('Fails when model artifact is smaller than minimum threshold', () async {
      final modelDir = Directory('${tempDir.path}/models/${AiProviderConfig.offlineGemmaSlug}');
      await modelDir.create(recursive: true);
      final file = File('${modelDir.path}/gemma-4-E2B-it.litertlm');
      await file.writeAsString('TINY_STUB');

      final res = await validator.validateArtifact(
        directoryPath: modelDir.path,
        minSizeBytes: 1024 * 1024, // 1 MB min threshold
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('below the minimum required threshold'));
    });

    test('Succeeds and verifies SHA-256 for genuine artifact', () async {
      final modelDir = Directory('${tempDir.path}/models/${AiProviderConfig.offlineGemmaSlug}');
      await modelDir.create(recursive: true);
      final file = File('${modelDir.path}/gemma-4-E2B-it.litertlm');

      // Create dummy file that meets 200 byte test threshold
      final dummyBytes = List<int>.filled(200, 42);
      await file.writeAsBytes(dummyBytes);

      final expectedHash = await validator.calculateSha256(file);
      expect(expectedHash.length, equals(64));

      final res = await validator.validateArtifact(
        directoryPath: modelDir.path,
        expectedFilename: 'gemma-4-E2B-it.litertlm',
        expectedSha256: expectedHash,
        minSizeBytes: 100,
      );

      expect(res.isValid, isTrue);
      expect(res.fileSizeBytes, equals(200));
      expect(res.sha256, equals(expectedHash));
    });

    test('Fails when SHA-256 checksum mismatches', () async {
      final modelDir = Directory('${tempDir.path}/models/${AiProviderConfig.offlineGemmaSlug}');
      await modelDir.create(recursive: true);
      final file = File('${modelDir.path}/gemma-4-E2B-it.litertlm');
      await file.writeAsBytes(List<int>.filled(200, 42));

      final res = await validator.validateArtifact(
        directoryPath: modelDir.path,
        expectedFilename: 'gemma-4-E2B-it.litertlm',
        expectedSha256: 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
        minSizeBytes: 100,
      );

      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('SHA-256 checksum mismatch'));
    });
  });

  group('AiStartupInitializer Tests', () {
    test('Non-blocking startup initializes already downloaded model automatically', () async {
      final fakeManager = _TestOfflineModelManager(
        state: const OfflineModelState(
          status: OfflineModelStatus.downloaded,
        ),
      );

      final initializer = AiStartupInitializer(modelManager: fakeManager);
      await initializer.initializeOnStartup();

      // Wait brief moment for background unawaited task
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(fakeManager.initializeCalled, isTrue);
      expect(initializer.currentReadiness.status, equals(AiStartupReadinessStatus.ready));
    });

    test('Does NOT download model automatically when missing on disk', () async {
      final fakeManager = _TestOfflineModelManager(
        state: const OfflineModelState(
          status: OfflineModelStatus.notDownloaded,
        ),
      );

      final initializer = AiStartupInitializer(modelManager: fakeManager);
      await initializer.initializeOnStartup();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(fakeManager.downloadCalled, isFalse);
      expect(fakeManager.initializeCalled, isFalse);
      expect(initializer.currentReadiness.status, equals(AiStartupReadinessStatus.unavailable));
    });
  });

  group('LiteRtOfflineModelManager Tests', () {
    test(
      'Initial availability check returns notDownloaded when dir is empty',
      () async {
        final connectivity = _MockConnectivityService(online: true);
        final manager = LitertOfflineModelManager(
          connectivityService: connectivity,
          getDocDir: () async => tempDir,
        );

        await manager.checkAvailability();
        final state = await manager.getState();
        expect(state.status, equals(OfflineModelStatus.notDownloaded));
      },
    );

    test('Download fails when device is offline', () async {
      final connectivity = _MockConnectivityService(online: false);
      final manager = LitertOfflineModelManager(
        connectivityService: connectivity,
        getDocDir: () async => tempDir,
      );

      await expectLater(
        () => manager.download(),
        throwsA(isA<OfflineModelDownloadFailedException>()),
      );
      final state = await manager.getState();
      expect(state.status, equals(OfflineModelStatus.failed));
    });

    test(
      'Cancel download resets state to notDownloaded and clears active sink',
      () async {
        final connectivity = _MockConnectivityService(online: true);
        final manager = LitertOfflineModelManager(
          connectivityService: connectivity,
          getDocDir: () async => tempDir,
        );

        await manager.cancelDownload();
        final state = await manager.getState();
        expect(state.status, equals(OfflineModelStatus.notDownloaded));
        expect(state.canCancel, isFalse);
      },
    );

    test('Deleting model removes files and updates state without deleting root files', () async {
      final connectivity = _MockConnectivityService(online: true);
      final manager = LitertOfflineModelManager(
        connectivityService: connectivity,
        getDocDir: () async => tempDir,
      );

      // Create a test report file in temp dir to ensure deleteModel does NOT touch it
      final userReportFile = File('${tempDir.path}/reports/report_123.json');
      await userReportFile.create(recursive: true);
      await userReportFile.writeAsString('{"id":"123"}');

      await manager.deleteModel();
      final state = await manager.getState();
      expect(state.status, equals(OfflineModelStatus.notDownloaded));
      expect(state.canDelete, isFalse);

      // Verify report was NOT deleted
      expect(await userReportFile.exists(), isTrue);
    });
  });
}
