import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/report_draft.dart';
import '../../../shared/models/sync_status.dart';
import 'report_repository.dart';

/// Temporary in-memory implementation for Phase 1.
/// In Phase 2, Debashish will replace this with Drift/SQLite persistence.
class TemporaryReportRepository implements ReportRepository {
  ReportDraft? _currentDraft;
  final List<HazardReport> _reports = [];

  @override
  Stream<List<HazardReport>> watchLocalReports() async* {
    yield await getLocalReports();
  }

  @override
  Future<void> saveDraft(ReportDraft draft) async {
    _currentDraft = draft;
  }

  @override
  Future<ReportDraft?> getDraft() async {
    return _currentDraft;
  }

  @override
  Future<void> clearDraft() async {
    _currentDraft = null;
  }

  @override
  Future<void> saveReport(HazardReport report) async {
    final index = _reports.indexWhere((r) => r.id == report.id);
    if (index >= 0) {
      _reports[index] = report;
    } else {
      _reports.insert(0, report);
    }
  }

  @override
  Future<int> getPendingCount() async {
    return _reports.where((r) => r.syncStatus == SyncStatus.pending).length;
  }

  @override
  Future<List<HazardReport>> getLocalReports() async {
    return List.unmodifiable(_reports);
  }

  @override
  Future<HazardReport?> getReportById(String id) async {
    try {
      return _reports.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
