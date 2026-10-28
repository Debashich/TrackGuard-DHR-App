import '../../../shared/models/hazard_report.dart';

/// Converts the local report model to the columns in public.reports.
/// Local sync state and filesystem paths must not be sent to this table.
class SupabaseReportMapper {
  const SupabaseReportMapper._();

  static Map<String, dynamic> toRemoteRow(
    HazardReport report, {
    String? userId,
  }) {
    final sectionId = report.sectionId;
    if (sectionId.isEmpty) {
      throw ArgumentError(
        'A section must be selected before syncing a report.',
      );
    }

    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    final validUserId =
        userId ?? (isUuid.hasMatch(report.createdBy) ? report.createdBy : null);

    final map = <String, dynamic>{
      'id': report.id,
      'created_at': report.createdAt.toUtc().toIso8601String(),
      'updated_at': report.updatedAt.toUtc().toIso8601String(),
      'latitude': report.latitude,
      'longitude': report.longitude,
      'gps_accuracy_meters': report.gpsAccuracyMeters,
      'location_source': report.locationSource.toJson(),
      'location_captured_at': report.locationCapturedAt
          ?.toUtc()
          .toIso8601String(),
      'distance_to_alignment_km': report.distanceToAlignmentKm,
      'km_marker': report.kmMarker,
      'section_id': sectionId,
      'nearest_station_name': report.nearestStationName,
      'confirmed_hazard_type': report.confirmedHazardType.toJson(),
      'confirmed_severity': report.confirmedSeverity.toJson(),
      'user_note': report.userNote,
      'ai_suggested_hazard_type': report.aiSuggestedHazardType?.toJson(),
      'ai_suggested_severity': report.aiSuggestedSeverity?.toJson(),
      'ai_note': report.aiNote,
      'ai_provider': report.aiProvider.toJson(),
      'ai_model': report.aiModel,
      'ai_language': report.aiLanguage?.code,
      'ai_confidence': report.aiConfidence,
      'inspection_status': report.inspectionStatus.toJson(),
      'sync_version': report.syncVersion,
    };
    if (validUserId != null) {
      map['created_by'] = validUserId;
    }
    return map;
  }

  static HazardReport fromRemoteRow(Map<String, dynamic> row) {
    return HazardReport.fromJson({
      ...row,
      'sync_status': 'synced',
      'sync_timestamp': DateTime.now().toUtc().toIso8601String(),
      'retry_count': 0,
      'last_sync_error': null,
      'original_photo_path': null,
      'thumbnail_photo_path': null,
      'device_info': null,
    });
  }
}
