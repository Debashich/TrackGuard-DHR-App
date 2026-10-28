import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/sync_status.dart';
import 'report_repository.dart';
import 'supabase_media_data_source.dart';
import 'supabase_report_data_source.dart';

class ReportSyncService {
  ReportSyncService({
    required this.repository,
    required this.remote,
    required this.media,
  });

  final ReportRepository repository;
  final SupabaseReportDataSource remote;
  final SupabaseMediaDataSource media;

  bool _isSyncing = false;

  Future<void> syncPendingReports() async {
    if (_isSyncing) return;

    _isSyncing = true;
    try {
      final reports = await repository.getLocalReports();

      for (final report in reports) {
        if (report.syncStatus != SyncStatus.pending &&
            report.syncStatus != SyncStatus.failed &&
            report.syncStatus != SyncStatus.syncing) {
          continue;
        }

        await repository.saveReport(
          report.copyWith(syncStatus: SyncStatus.syncing),
        );

        try {
          await remote.upsertReport(report);
          await media.uploadReportMedia(report);

          await repository.saveReport(
            report.copyWith(
              syncStatus: SyncStatus.synced,
              syncTimestamp: DateTime.now().toUtc(),
              retryCount: 0,
              lastSyncError: null,
            ),
          );
        } catch (error) {
          await repository.saveReport(
            report.copyWith(
              syncStatus: SyncStatus.failed,
              retryCount: report.retryCount + 1,
              lastSyncError: error.toString(),
            ),
          );
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<List<HazardReport>> fetchRemoteReports({
    int page = 0,
    int pageSize = 50,
  }) async {
    final reports = await remote.fetchReports(page: page, pageSize: pageSize);

    for (final report in reports) {
      final local = await repository.getReportById(report.id);

      // Never overwrite a report that still has local changes.
      if (local != null && local.syncStatus != SyncStatus.synced) {
        continue;
      }

      // Avoid replacing a newer local version with an older remote version.
      if (local != null && local.syncVersion > report.syncVersion) {
        continue;
      }

      await repository.saveReport(report);
    }

    return reports;
  }
}
