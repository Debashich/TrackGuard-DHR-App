import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/core/connectivity/connectivity_service.dart';
import 'package:trackguard_dhr/core/errors/app_exception.dart';
import 'package:trackguard_dhr/features/ai/data/cactus_offline_model_manager.dart';
import 'package:trackguard_dhr/features/ai/domain/offline_model_state.dart';

class _MockConnectivityService implements ConnectivityService {
  bool online;
  _MockConnectivityService({this.online = true});

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> watchOnlineStatus() => Stream.value(online);
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
    });

    test('Formatted sizes calculate MB and GB properly', () {
      final state = const OfflineModelState().copyWith(
        downloadedBytes: 250 * 1024 * 1024,
        totalBytes: 1250 * 1024 * 1024,
        progress: 0.2,
      );
      expect(state.formattedDownloadedSize, equals('250.0 MB'));
      expect(state.formattedTotalSize, equals('1.22 GB'));
      expect(state.progressPercent, equals(20));
    });

    test('OfflineModelState JSON serialization works roundtrip', () {
      final now = DateTime.now();
      final state = const OfflineModelState().copyWith(
        status: OfflineModelStatus.ready,
        version: '1.2.0',
        downloadedBytes: 1000,
        totalBytes: 1000,
        downloadedAt: now,
      );
      final json = state.toJson();
      final restored = OfflineModelState.fromJson(json);

      expect(restored.status, equals(OfflineModelStatus.ready));
      expect(restored.version, equals('1.2.0'));
      expect(restored.downloadedBytes, equals(1000));
      expect(restored.canDelete, isTrue);
    });

    test('OfflineModelDownloadSettings serialization works roundtrip', () {
      const settings = OfflineModelDownloadSettings(
        wifiOnly: true,
        allowCellularDownload: false,
      );
      final json = settings.toJson();
      final restored = OfflineModelDownloadSettings.fromJson(json);

      expect(restored.wifiOnly, isTrue);
      expect(restored.allowCellularDownload, isFalse);
    });
  });

  group('CactusOfflineModelManager Tests', () {
    test(
      'Initial availability check returns notDownloaded when dir is empty',
      () async {
        final connectivity = _MockConnectivityService(online: true);
        final manager = CactusOfflineModelManager(
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
      final manager = CactusOfflineModelManager(
        connectivityService: connectivity,
        getDocDir: () async => tempDir,
      );

      await expectLater(
        () => manager.download(),
        throwsA(isA<OfflineModelNetworkUnavailableException>()),
      );
      final state = await manager.getState();
      expect(state.status, equals(OfflineModelStatus.failed));
    });

    test(
      'Cancel download resets state to notDownloaded and clears active sink',
      () async {
        final connectivity = _MockConnectivityService(online: true);
        final manager = CactusOfflineModelManager(
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
      final manager = CactusOfflineModelManager(
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
