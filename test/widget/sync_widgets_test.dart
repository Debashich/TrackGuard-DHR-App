import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/l10n/app_localizations.dart';
import 'package:trackguard_dhr/shared/models/ai_provider.dart';
import 'package:trackguard_dhr/shared/models/app_language.dart';
import 'package:trackguard_dhr/shared/models/hazard_report.dart';
import 'package:trackguard_dhr/shared/models/hazard_type.dart';
import 'package:trackguard_dhr/shared/models/inspection_status.dart';
import 'package:trackguard_dhr/shared/models/location_source.dart';
import 'package:trackguard_dhr/shared/models/severity.dart';
import 'package:trackguard_dhr/shared/models/sync_status.dart';
import 'package:trackguard_dhr/shared/models/sync_summary.dart';
import 'package:trackguard_dhr/shared/widgets/ai_metadata_card.dart';
import 'package:trackguard_dhr/shared/widgets/sync_error_banner.dart';
import 'package:trackguard_dhr/shared/widgets/sync_status_badge.dart';
import 'package:trackguard_dhr/shared/widgets/sync_status_card.dart';
import 'package:trackguard_dhr/shared/widgets/sync_summary_card.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('SyncStatusBadge Widget Tests', () {
    testWidgets('Renders all sync statuses with text and icons', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Column(
            children: [
              SyncStatusBadge(status: SyncStatus.pending),
              SyncStatusBadge(status: SyncStatus.synced),
              SyncStatusBadge(status: SyncStatus.failed),
              SyncStatusBadge(status: SyncStatus.syncing),
              SyncStatusBadge(status: SyncStatus.conflict),
            ],
          ),
        ),
      );

      expect(find.text('PENDING SYNC'), findsOneWidget);
      expect(find.text('SYNCED'), findsOneWidget);
      expect(find.text('SYNC FAILED'), findsOneWidget);
      expect(find.text('SYNCING...'), findsOneWidget);
      expect(find.text('CONFLICT'), findsOneWidget);
    });
  });

  group('SyncSummaryCard Widget Tests', () {
    testWidgets('Renders offline state and pending count with sync action', (
      tester,
    ) async {
      bool syncClicked = false;
      bool viewQueueClicked = false;

      const summary = SyncSummary(
        pendingCount: 2,
        syncingCount: 0,
        failedCount: 1,
        syncedCount: 4,
        conflictCount: 0,
        isOnline: true,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          SyncSummaryCard(
            summary: summary,
            onSyncNow: () {
              syncClicked = true;
            },
            onViewQueue: () {
              viewQueueClicked = true;
            },
          ),
        ),
      );

      expect(find.text('SYNC SUMMARY'), findsOneWidget);
      expect(find.text('STATION SIGNAL AVAILABLE'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Synced'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      await tester.tap(find.text('Sync Now'));
      expect(syncClicked, isTrue);

      await tester.tap(find.text('View Queue'));
      expect(viewQueueClicked, isTrue);
    });
  });

  group('AiMetadataCard Widget Tests', () {
    testWidgets('Renders Offline Gemma metadata with advisory notice', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AiMetadataCard(
            provider: AiProvider.offlineGemma,
            modelName: 'Gemma 4 E2B',
            language: AppLanguage.en,
            confidence: 0.92,
          ),
        ),
      );

      expect(find.text('Offline Gemma'), findsOneWidget);
      expect(find.text('Gemma 4 E2B'), findsOneWidget);
      expect(
        find.text(
          'AI suggestion is advisory only. Gangman inspection confirmed.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('92%'), findsOneWidget);
    });

    testWidgets('Renders Heuristic fallback without fabricated model names', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AiMetadataCard(
            provider: AiProvider.heuristic,
            language: AppLanguage.hi,
          ),
        ),
      );

      expect(find.text('Heuristic Rules'), findsOneWidget);
      expect(find.text('Rule-based Heuristics'), findsOneWidget);
    });
  });

  group('SyncErrorBanner and SyncStatusCard Tests', () {
    testWidgets('SyncErrorBanner renders friendly error and invokes retry', (
      tester,
    ) async {
      bool retryTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          SyncErrorBanner(
            error: 'TimeoutException: Connection timed out',
            onRetry: () {
              retryTapped = true;
            },
          ),
        ),
      );

      expect(
        find.text(
          'The station connection took too long. The report remains saved locally.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Retry Sync'));
      expect(retryTapped, isTrue);
    });

    testWidgets('SyncStatusCard renders report status and retry count', (
      tester,
    ) async {
      final now = DateTime.now();
      final report = HazardReport(
        id: 'rep-test-12345678',
        createdBy: 'gangman-001',
        createdAt: now,
        updatedAt: now,
        locationSource: LocationSource.gps,
        sectionId: 'kurseong-ghum',
        confirmedHazardType: HazardType.rockfall,
        confirmedSeverity: Severity.high,
        userNote: 'Rock on track',
        inspectionStatus: InspectionStatus.open,
        syncStatus: SyncStatus.failed,
        lastSyncError: 'SocketException: Connection refused',
        retryCount: 2,
      );

      await tester.pumpWidget(
        buildTestableWidget(SyncStatusCard(report: report, onRetry: () {})),
      );

      expect(find.text('SYNC FAILED'), findsOneWidget);
      expect(find.textContaining('Retry attempts: 2'), findsOneWidget);
      expect(
        find.text(
          'No network connection. The report is safely stored on this device.',
        ),
        findsOneWidget,
      );
    });
  });
}
