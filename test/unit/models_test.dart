import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/shared/models/ai_provider.dart';
import 'package:trackguard_dhr/shared/models/app_language.dart';
import 'package:trackguard_dhr/shared/models/geo_location.dart';
import 'package:trackguard_dhr/shared/models/hazard_report.dart';
import 'package:trackguard_dhr/shared/models/hazard_type.dart';
import 'package:trackguard_dhr/shared/models/inspection_status.dart';
import 'package:trackguard_dhr/shared/models/location_source.dart';
import 'package:trackguard_dhr/shared/models/severity.dart';
import 'package:trackguard_dhr/shared/models/sync_status.dart';

void main() {
  group('Domain Models & Enums Tests', () {
    test('HazardType enum parsing and fallback', () {
      expect(HazardType.fromString('slip'), HazardType.slip);
      expect(HazardType.fromString('landslip'), HazardType.slip);
      expect(HazardType.fromString('mudslide'), HazardType.slip);
      expect(HazardType.fromString('rockfall'), HazardType.rockfall);
      expect(HazardType.fromString('blocked_drain'), HazardType.blockedDrain);
      expect(HazardType.fromString('retaining_wall'), HazardType.damagedWall);
      expect(HazardType.fromString('track_defect'), HazardType.trackDefect);
      expect(HazardType.fromString('vegetation'), HazardType.vegetation);
      expect(HazardType.fromString('unknown_hazard'), HazardType.other);
      expect(HazardType.fromString(null), HazardType.other);
    });

    test('Severity enum parsing and fallback', () {
      expect(Severity.fromString('low'), Severity.low);
      expect(Severity.fromString('medium'), Severity.medium);
      expect(Severity.fromString('high'), Severity.high);
      expect(Severity.fromString('critical'), Severity.critical);
      expect(Severity.fromString('urgent'), Severity.critical);
      expect(Severity.fromString('unknown'), Severity.medium);
      expect(Severity.fromString(null), Severity.medium);
    });

    test('LocationSource enum parsing', () {
      expect(LocationSource.fromString('gps'), LocationSource.gps);
      expect(LocationSource.fromString('manual'), LocationSource.manual);
      expect(LocationSource.fromString('fallback'), LocationSource.fallback);
      expect(LocationSource.fromString(null), LocationSource.gps);
    });

    test('InspectionStatus and SyncStatus enum parsing', () {
      expect(InspectionStatus.fromString('open'), InspectionStatus.open);
      expect(
        InspectionStatus.fromString('acknowledged'),
        InspectionStatus.acknowledged,
      );
      expect(
        InspectionStatus.fromString('inspection_required'),
        InspectionStatus.inspectionRequired,
      );
      expect(
        InspectionStatus.fromString('resolved'),
        InspectionStatus.resolved,
      );

      expect(SyncStatus.fromString('draft'), SyncStatus.draft);
      expect(SyncStatus.fromString('pending'), SyncStatus.pending);
      expect(SyncStatus.fromString('synced'), SyncStatus.synced);
      expect(SyncStatus.fromString('failed'), SyncStatus.failed);
    });

    test('AppLanguage enum codes and display names', () {
      expect(AppLanguage.fromCode('en'), AppLanguage.en);
      expect(AppLanguage.fromCode('hi'), AppLanguage.hi);
      expect(AppLanguage.fromCode('bn'), AppLanguage.bn);
      expect(AppLanguage.fromCode('ne'), AppLanguage.ne);
      expect(AppLanguage.fromCode('other'), AppLanguage.en);
    });

    test('GeoLocation JSON round-trip and copyWith', () {
      final now = DateTime.now();
      final loc = GeoLocation(
        latitude: 26.8812,
        longitude: 88.2789,
        accuracyMeters: 4.5,
        kmMarker: 51.0,
        sectionId: 'kurseong-ghum',
        nearestStationName: 'Kurseong Station',
        distanceToAlignmentKm: 0.05,
        capturedAt: now,
        source: LocationSource.gps,
        isSimulated: false,
      );

      final json = loc.toJson();
      final fromJson = GeoLocation.fromJson(json);

      expect(fromJson.latitude, 26.8812);
      expect(fromJson.longitude, 88.2789);
      expect(fromJson.accuracyMeters, 4.5);
      expect(fromJson.kmMarker, 51.0);
      expect(fromJson.source, LocationSource.gps);
      expect(fromJson.isSimulated, false);

      final modified = loc.copyWith(kmMarker: 52.5, isSimulated: true);
      expect(modified.kmMarker, 52.5);
      expect(modified.isSimulated, true);
    });

    test('HazardReport domain model serialization and audit metadata', () {
      final now = DateTime.now();
      final report = HazardReport(
        id: 'rep-test-001',
        createdBy: 'user-001',
        createdAt: now,
        updatedAt: now,
        latitude: 27.0150,
        longitude: 88.2635,
        gpsAccuracyMeters: 8.0,
        locationSource: LocationSource.gps,
        kmMarker: 74.2,
        sectionId: 'ghum-darjeeling',
        nearestStationName: 'Ghum Station',
        confirmedHazardType: HazardType.rockfall,
        confirmedSeverity: Severity.high,
        userNote: 'Rocks scattered across track near loop exit.',
        aiSuggestedHazardType: HazardType.rockfall,
        aiSuggestedSeverity: Severity.medium,
        aiNote: 'Loose rocks detected.',
        aiProvider: AiProvider.heuristic,
        aiModel: null,
        aiLanguage: AppLanguage.en,
        aiConfidence: 0.6,
        inspectionStatus: InspectionStatus.open,
        syncStatus: SyncStatus.pending,
      );

      final json = report.toJson();
      final restored = HazardReport.fromJson(json);

      expect(restored.id, 'rep-test-001');
      expect(restored.confirmedHazardType, HazardType.rockfall);
      expect(restored.confirmedSeverity, Severity.high);
      expect(restored.aiSuggestedSeverity, Severity.medium);
      expect(restored.aiProvider, AiProvider.heuristic);
      expect(restored.syncStatus, SyncStatus.pending);
      expect(restored.inspectionStatus, InspectionStatus.open);
    });
  });
}
