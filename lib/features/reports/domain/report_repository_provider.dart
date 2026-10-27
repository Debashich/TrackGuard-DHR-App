import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/report_repository.dart';
import '../data/temporary_report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  // In-memory instance retained for app lifecycle in Phase 1
  return _sharedTemporaryRepo;
});

final _sharedTemporaryRepo = TemporaryReportRepository();

final pendingReportsCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getPendingCount();
});
