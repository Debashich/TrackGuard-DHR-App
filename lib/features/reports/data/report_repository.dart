import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/report_draft.dart';

abstract class ReportRepository {
  Future<void> saveDraft(ReportDraft draft);
  Future<ReportDraft?> getDraft();
  Future<void> clearDraft();
  Future<void> saveReport(HazardReport report);
  Future<int> getPendingCount();
  Future<List<HazardReport>> getLocalReports();
  Future<HazardReport?> getReportById(String id);
}
