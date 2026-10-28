import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/sync_status.dart';
import '../../../shared/models/sync_summary.dart';
import '../data/report_repository.dart';
import '../data/report_sync_service.dart';
import '../data/sqlite_report_repository.dart';
import '../data/supabase_media_data_source.dart';
import '../data/supabase_report_data_source.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final repository = SqliteReportRepository();
  ref.onDispose(() => repository.dispose());
  return repository;
});

final localReportsProvider = StreamProvider<List<HazardReport>>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return repository.watchLocalReports();
});

final pendingReportsCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(reportRepositoryProvider);

  return repository.watchLocalReports().map(
    (reports) => reports
        .where((report) => report.syncStatus == SyncStatus.pending)
        .length,
  );
});

final syncSummaryProvider = Provider<SyncSummary>((ref) {
  final reports = ref.watch(localReportsProvider).value ?? [];
  final isOnline = ref.watch(isOnlineProvider).value ?? false;

  int pending = 0;
  int syncing = 0;
  int failed = 0;
  int synced = 0;
  int conflict = 0;
  DateTime? lastSuccess;
  String? lastError;

  for (final r in reports) {
    switch (r.syncStatus) {
      case SyncStatus.pending:
        pending++;
        break;
      case SyncStatus.syncing:
        syncing++;
        break;
      case SyncStatus.failed:
        failed++;
        if (lastError == null && r.lastSyncError != null) {
          lastError = r.lastSyncError;
        }
        break;
      case SyncStatus.synced:
        synced++;
        if (r.syncTimestamp != null) {
          if (lastSuccess == null || r.syncTimestamp!.isAfter(lastSuccess)) {
            lastSuccess = r.syncTimestamp;
          }
        }
        break;
      case SyncStatus.conflict:
        conflict++;
        break;
      case SyncStatus.draft:
        break;
    }
  }

  return SyncSummary(
    pendingCount: pending,
    syncingCount: syncing,
    failedCount: failed,
    syncedCount: synced,
    conflictCount: conflict,
    lastSuccessfulSync: lastSuccess,
    lastError: lastError,
    isOnline: isOnline,
    isSyncing: syncing > 0,
  );
});

final reportSyncServiceProvider = Provider<ReportSyncService?>((ref) {
  final client = ref.watch(supabaseClientProvider);

  // Allow remote sync whenever Supabase client is initialized.
  if (client == null) {
    return null;
  }

  return ReportSyncService(
    repository: ref.watch(reportRepositoryProvider),
    remote: SupabaseReportDataSource(client),
    media: SupabaseMediaDataSource(client),
  );
});
