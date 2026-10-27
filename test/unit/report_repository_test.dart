import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/features/reports/data/temporary_report_repository.dart';
import 'package:trackguard_dhr/shared/models/geo_location.dart';
import 'package:trackguard_dhr/shared/models/hazard_report.dart';
import 'package:trackguard_dhr/shared/models/hazard_type.dart';
import 'package:trackguard_dhr/shared/models/report_draft.dart';
import 'package:trackguard_dhr/shared/models/severity.dart';
import 'package:trackguard_dhr/shared/models/sync_status.dart';

void main() {
  group('TemporaryReportRepository Contract Tests', () {
    late TemporaryReportRepository repository;

    setUp(() {
      repository = TemporaryReportRepository();
    });

    test('Draft lifecycle: save, retrieve, clear', () async {
      expect(await repository.getDraft(), isNull);

      final draft = ReportDraft(
        photoPath: '/tmp/test.jpg',
        thumbnailPath: '/tmp/test_thumb.jpg',
        location: GeoLocation(
          kmMarker: 55.0,
          sectionId: 'kurseong-ghum',
          capturedAt: DateTime.now(),
        ),
        createdAt: DateTime.now(),
      );

      await repository.saveDraft(draft);
      final retrieved = await repository.getDraft();
      expect(retrieved?.photoPath, '/tmp/test.jpg');
      expect(retrieved?.location.kmMarker, 55.0);

      await repository.clearDraft();
      expect(await repository.getDraft(), isNull);
    });

    test('Report lifecycle: save, getPendingCount, getById', () async {
      expect(await repository.getPendingCount(), 0);

      final report = HazardReport(
        id: 'test-rep-001',
        createdBy: 'user-001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sectionId: 'kurseong-ghum',
        confirmedHazardType: HazardType.damagedWall,
        confirmedSeverity: Severity.medium,
        userNote: 'Retaining wall bulge near km 53',
        syncStatus: SyncStatus.pending,
      );

      await repository.saveReport(report);
      expect(await repository.getPendingCount(), 1);

      final fetched = await repository.getReportById('test-rep-001');
      expect(fetched?.id, 'test-rep-001');
      expect(fetched?.confirmedHazardType, HazardType.damagedWall);

      final allReports = await repository.getLocalReports();
      expect(allReports.length, 1);
    });
  });
}
