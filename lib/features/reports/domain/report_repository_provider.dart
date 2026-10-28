import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/supabase_media_data_source.dart';
import '../../../core/supabase/supabase_provider.dart';

import '../data/report_sync_service.dart';
import '../data/supabase_report_data_source.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/sync_status.dart';
import '../data/report_repository.dart';
import '../data/sqlite_report_repository.dart';

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

final reportSyncServiceProvider = Provider<ReportSyncService?>((ref) {
  final client = ref.watch(supabaseClientProvider);

  // Don't attempt remote sync until Supabase is configured and signed in.
  if (client == null || client.auth.currentUser == null) {
    return null;
  }

  return ReportSyncService(
    repository: ref.watch(reportRepositoryProvider),
    remote: SupabaseReportDataSource(client),
    media: SupabaseMediaDataSource(client),
  );
});
