import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/core/sync/sync_error_message_mapper.dart';
import 'package:trackguard_dhr/core/utils/date_format_utils.dart';
import 'package:trackguard_dhr/l10n/app_localizations.dart';
import 'package:trackguard_dhr/shared/models/sync_error_event.dart';
import 'package:trackguard_dhr/shared/models/sync_summary.dart';

void main() {
  group('SyncSummary Model Tests', () {
    test('Calculates counts, hasPendingOrFailed, and allSynced correctly', () {
      const summaryEmpty = SyncSummary(
        pendingCount: 0,
        syncingCount: 0,
        failedCount: 0,
        syncedCount: 5,
        conflictCount: 0,
        isOnline: true,
      );

      expect(summaryEmpty.hasPendingOrFailed, isFalse);
      expect(summaryEmpty.allSynced, isTrue);

      const summaryPending = SyncSummary(
        pendingCount: 3,
        syncingCount: 1,
        failedCount: 0,
        syncedCount: 2,
        conflictCount: 0,
        isOnline: false,
      );

      expect(summaryPending.hasPendingOrFailed, isTrue);
      expect(summaryPending.allSynced, isFalse);

      const summaryFailed = SyncSummary(
        pendingCount: 0,
        syncingCount: 0,
        failedCount: 2,
        syncedCount: 1,
        conflictCount: 0,
        isOnline: true,
      );

      expect(summaryFailed.hasPendingOrFailed, isTrue);
      expect(summaryFailed.allSynced, isFalse);
    });

    test('SyncErrorEvent preserves attributes and canRetry state', () {
      final now = DateTime.now();
      final event = SyncErrorEvent(
        reportId: 'rep-001',
        userMessage: 'Station signal interrupted',
        technicalCode: 'TIMEOUT_504',
        occurredAt: now,
        canRetry: true,
      );

      expect(event.reportId, 'rep-001');
      expect(event.userMessage, 'Station signal interrupted');
      expect(event.technicalCode, 'TIMEOUT_504');
      expect(event.occurredAt, now);
      expect(event.canRetry, isTrue);
    });
  });

  group('SyncErrorMessageMapper Tests', () {
    testWidgets(
      'Maps errors to clear localized messages without stack traces',
      (tester) async {
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

        // Offline / socket errors
        expect(
          SyncErrorMessageMapper.toUserMessage(
            'SocketException: OS Error: Connection refused',
            l10n,
          ),
          l10n.syncErrorOffline,
        );
        expect(
          SyncErrorMessageMapper.toUserMessage('Device is offline', l10n),
          l10n.syncErrorOffline,
        );

        // Timeout errors
        expect(
          SyncErrorMessageMapper.toUserMessage(
            'TimeoutException after 0:00:15.000000',
            l10n,
          ),
          l10n.syncErrorTimeout,
        );

        // Unauthorized errors
        expect(
          SyncErrorMessageMapper.toUserMessage(
            'PostgrestException: 401 Unauthorized JWT expired',
            l10n,
          ),
          l10n.syncErrorUnauthorized,
        );

        // Media / Storage upload errors
        expect(
          SyncErrorMessageMapper.toUserMessage(
            'StorageException: photo upload failed to bucket',
            l10n,
          ),
          l10n.syncErrorMediaUpload,
        );

        // Server unavailable errors
        expect(
          SyncErrorMessageMapper.toUserMessage('503 Service Unavailable', l10n),
          l10n.syncErrorServerUnavailable,
        );

        // Conflict errors
        expect(
          SyncErrorMessageMapper.toUserMessage(
            '409 Conflict: resource modified',
            l10n,
          ),
          l10n.syncErrorConflict,
        );

        // Unknown fallback
        expect(
          SyncErrorMessageMapper.toUserMessage(
            'Unexpected runtime defect',
            l10n,
          ),
          l10n.syncErrorUnknown,
        );
      },
    );

    test('extractTechnicalCode pulls HTTP or error codes safely', () {
      expect(
        SyncErrorMessageMapper.extractTechnicalCode(
          'Error 401: Unauthorized access',
        ),
        '401',
      );
      expect(
        SyncErrorMessageMapper.extractTechnicalCode(
          'Server returned 503 Service Unavailable',
        ),
        '503',
      );
      expect(
        SyncErrorMessageMapper.extractTechnicalCode(
          'StorageException occurred',
        ),
        'STORAGE_ERR',
      );
    });

    test('canRetry accurately determines retry viability', () {
      expect(
        SyncErrorMessageMapper.canRetry('TimeoutException: timed out'),
        isTrue,
      );
      expect(
        SyncErrorMessageMapper.canRetry('SocketException: Connection lost'),
        isTrue,
      );
      expect(SyncErrorMessageMapper.canRetry('401 Unauthorized'), isFalse);
      expect(SyncErrorMessageMapper.canRetry('403 Forbidden'), isFalse);
    });
  });

  group('DateFormatUtils Tests', () {
    testWidgets(
      'formatSyncTime formats Today and Yesterday with localization',
      (tester) async {
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

        final now = DateTime.now();
        final formattedToday = DateFormatUtils.formatSyncTime(now, l10n);
        expect(formattedToday, startsWith('Today,'));

        final yesterday = now.subtract(const Duration(days: 1));
        final formattedYesterday = DateFormatUtils.formatSyncTime(
          yesterday,
          l10n,
        );
        expect(formattedYesterday, startsWith('Yesterday,'));

        final pastDate = DateTime(2025, 5, 12, 10, 30);
        final formattedPast = DateFormatUtils.formatReportDate(pastDate);
        expect(formattedPast, contains('12 May 2025'));
      },
    );
  });
}
