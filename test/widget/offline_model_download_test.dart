import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/core/connectivity/connectivity_provider.dart';
import 'package:trackguard_dhr/features/ai/domain/ai_service_provider.dart';
import 'package:trackguard_dhr/features/ai/domain/offline_model_manager.dart';
import 'package:trackguard_dhr/features/ai/domain/offline_model_state.dart';
import 'package:trackguard_dhr/features/ai/presentation/offline_model_download_screen.dart';
import 'package:trackguard_dhr/l10n/app_localizations.dart';

class _FakeOfflineModelManager implements OfflineModelManager {
  OfflineModelState state;
  OfflineModelDownloadSettings settings;
  final StreamController<OfflineModelState> _controller =
      StreamController<OfflineModelState>.broadcast();

  bool downloadCalled = false;
  bool cancelCalled = false;
  bool deleteCalled = false;

  _FakeOfflineModelManager({
    this.state = const OfflineModelState(
      status: OfflineModelStatus.notDownloaded,
    ),
  }) : settings = const OfflineModelDownloadSettings();

  @override
  Stream<OfflineModelState> watchState() async* {
    yield state;
    yield* _controller.stream;
  }

  @override
  Future<OfflineModelState> getState() async => state;

  @override
  Future<void> checkAvailability() async {}

  @override
  Future<void> download() async {
    downloadCalled = true;
    state = state.copyWith(status: OfflineModelStatus.downloading);
    _controller.add(state);
  }

  @override
  Future<void> cancelDownload() async {
    cancelCalled = true;
    state = state.copyWith(status: OfflineModelStatus.notDownloaded);
    _controller.add(state);
  }

  @override
  Future<void> initialize() async {
    state = state.copyWith(status: OfflineModelStatus.ready);
    _controller.add(state);
  }

  @override
  Future<void> deleteModel() async {
    deleteCalled = true;
    state = state.copyWith(status: OfflineModelStatus.notDownloaded);
    _controller.add(state);
  }

  @override
  OfflineModelDownloadSettings getDownloadSettings() => settings;

  @override
  Future<void> setDownloadSettings(
    OfflineModelDownloadSettings newSettings,
  ) async {
    settings = newSettings;
  }

  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  group('OfflineModelDownloadScreen Widget Tests', () {
    testWidgets('Renders model specifications, storage, and download button', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeManager = _FakeOfflineModelManager();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offlineModelManagerProvider.overrideWithValue(fakeManager),
            isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OfflineModelDownloadScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Gemma 4 E2B'), findsOneWidget);
      expect(find.text('DOWNLOAD PREFERENCES'), findsOneWidget);
      expect(find.text('MODEL STATUS & ACTIONS'), findsOneWidget);
      expect(find.text('Download Model'), findsOneWidget);

      // Tap download button
      await tester.tap(find.text('Download Model'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeManager.downloadCalled, isTrue);
    });

    testWidgets('Renders progress bar and cancel button when downloading', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeManager = _FakeOfflineModelManager(
        state: const OfflineModelState(
          status: OfflineModelStatus.downloading,
          progress: 0.45,
          downloadedBytes: 450 * 1024 * 1024,
          totalBytes: 1000 * 1024 * 1024,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offlineModelManagerProvider.overrideWithValue(fakeManager),
            isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OfflineModelDownloadScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('45%'), findsOneWidget);
      expect(find.text('Cancel Download'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Cancel Download'));
      await tester.pumpAndSettle();

      expect(fakeManager.cancelCalled, isTrue);
    });

    testWidgets('Renders ready status and delete button when ready', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeManager = _FakeOfflineModelManager(
        state: OfflineModelState(
          status: OfflineModelStatus.ready,
          downloadedAt: DateTime(2026, 10, 30),
          canDelete: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offlineModelManagerProvider.overrideWithValue(fakeManager),
            isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OfflineModelDownloadScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Gemma 4 E2B Ready'), findsWidgets);
      expect(find.text('Delete Model'), findsOneWidget);
    });
  });
}
