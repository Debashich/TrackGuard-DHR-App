import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/sync_status.dart';
import '../data/report_repository.dart';
import '../data/sqlite_report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final repository = SqliteReportRepository();
  ref.onDispose(() => repository.dispose());
  return repository;
});

final localReportsProvider =
    StreamProvider<List<HazardReport>>((ref) {
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
