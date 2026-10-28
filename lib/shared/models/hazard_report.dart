import 'ai_provider.dart';
import 'app_language.dart';
import 'hazard_type.dart';
import 'inspection_status.dart';
import 'location_source.dart';
import 'severity.dart';
import 'sync_status.dart';

class HazardReport {
  final String id;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  final double? latitude;
  final double? longitude;
  final double? gpsAccuracyMeters;
  final LocationSource locationSource;
  final DateTime? locationCapturedAt;
  final double? distanceToAlignmentKm;
  final double? kmMarker;
  final String sectionId;
  final String? nearestStationName;

  final HazardType confirmedHazardType;
  final Severity confirmedSeverity;
  final String userNote;

  final HazardType? aiSuggestedHazardType;
  final Severity? aiSuggestedSeverity;
  final String? aiNote;
  final AiProvider aiProvider;
  final String? aiModel;
  final AppLanguage? aiLanguage;
  final double? aiConfidence;

  final InspectionStatus inspectionStatus;
  final SyncStatus syncStatus;
  final int syncVersion;
  final DateTime? syncTimestamp;
  final int retryCount;
  final String? lastSyncError;

  final String? originalPhotoPath;
  final String? thumbnailPhotoPath;
  final String? deviceInfo;

  const HazardReport({
    required this.id,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.gpsAccuracyMeters,
    this.locationSource = LocationSource.gps,
    this.locationCapturedAt,
    this.distanceToAlignmentKm,
    this.kmMarker,
    required this.sectionId,
    this.nearestStationName,
    required this.confirmedHazardType,
    required this.confirmedSeverity,
    required this.userNote,
    this.aiSuggestedHazardType,
    this.aiSuggestedSeverity,
    this.aiNote,
    this.aiProvider = AiProvider.manual,
    this.aiModel,
    this.aiLanguage,
    this.aiConfidence,
    this.inspectionStatus = InspectionStatus.open,
    this.syncStatus = SyncStatus.pending,
    this.syncVersion = 1,
    this.syncTimestamp,
    this.retryCount = 0,
    this.lastSyncError,
    this.originalPhotoPath,
    this.thumbnailPhotoPath,
    this.deviceInfo,
  });
  static const Object _unsetSyncError = Object();
  HazardReport copyWith({
    String? id,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    double? gpsAccuracyMeters,
    LocationSource? locationSource,
    DateTime? locationCapturedAt,
    double? distanceToAlignmentKm,
    double? kmMarker,
    String? sectionId,
    String? nearestStationName,
    HazardType? confirmedHazardType,
    Severity? confirmedSeverity,
    String? userNote,
    HazardType? aiSuggestedHazardType,
    Severity? aiSuggestedSeverity,
    String? aiNote,
    AiProvider? aiProvider,
    String? aiModel,
    AppLanguage? aiLanguage,
    double? aiConfidence,
    InspectionStatus? inspectionStatus,
    SyncStatus? syncStatus,
    int? syncVersion,
    DateTime? syncTimestamp,
    int? retryCount,
    Object? lastSyncError = _unsetSyncError,
    String? originalPhotoPath,
    String? thumbnailPhotoPath,
    String? deviceInfo,
  }) {
    return HazardReport(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsAccuracyMeters: gpsAccuracyMeters ?? this.gpsAccuracyMeters,
      locationSource: locationSource ?? this.locationSource,
      locationCapturedAt: locationCapturedAt ?? this.locationCapturedAt,
      distanceToAlignmentKm:
          distanceToAlignmentKm ?? this.distanceToAlignmentKm,
      kmMarker: kmMarker ?? this.kmMarker,
      sectionId: sectionId ?? this.sectionId,
      nearestStationName: nearestStationName ?? this.nearestStationName,
      confirmedHazardType: confirmedHazardType ?? this.confirmedHazardType,
      confirmedSeverity: confirmedSeverity ?? this.confirmedSeverity,
      userNote: userNote ?? this.userNote,
      aiSuggestedHazardType:
          aiSuggestedHazardType ?? this.aiSuggestedHazardType,
      aiSuggestedSeverity: aiSuggestedSeverity ?? this.aiSuggestedSeverity,
      aiNote: aiNote ?? this.aiNote,
      aiProvider: aiProvider ?? this.aiProvider,
      aiModel: aiModel ?? this.aiModel,
      aiLanguage: aiLanguage ?? this.aiLanguage,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      inspectionStatus: inspectionStatus ?? this.inspectionStatus,
      syncStatus: syncStatus ?? this.syncStatus,
      syncVersion: syncVersion ?? this.syncVersion,
      syncTimestamp: syncTimestamp ?? this.syncTimestamp,
      retryCount: retryCount ?? this.retryCount,
      lastSyncError: identical(lastSyncError, _unsetSyncError)
          ? this.lastSyncError
          : lastSyncError as String?,
      originalPhotoPath: originalPhotoPath ?? this.originalPhotoPath,
      thumbnailPhotoPath: thumbnailPhotoPath ?? this.thumbnailPhotoPath,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'gps_accuracy_meters': gpsAccuracyMeters,
      'location_source': locationSource.toJson(),
      'location_captured_at': locationCapturedAt?.toIso8601String(),
      'distance_to_alignment_km': distanceToAlignmentKm,
      'km_marker': kmMarker,
      'section_id': sectionId,
      'nearest_station_name': nearestStationName,
      'confirmed_hazard_type': confirmedHazardType.toJson(),
      'confirmed_severity': confirmedSeverity.toJson(),
      'user_note': userNote,
      'ai_suggested_hazard_type': aiSuggestedHazardType?.toJson(),
      'ai_suggested_severity': aiSuggestedSeverity?.toJson(),
      'ai_note': aiNote,
      'ai_provider': aiProvider.toJson(),
      'ai_model': aiModel,
      'ai_language': aiLanguage?.code,
      'ai_confidence': aiConfidence,
      'inspection_status': inspectionStatus.toJson(),
      'sync_status': syncStatus.toJson(),
      'sync_version': syncVersion,
      'sync_timestamp': syncTimestamp?.toIso8601String(),
      'retry_count': retryCount,
      'last_sync_error': lastSyncError,
      'original_photo_path': originalPhotoPath,
      'thumbnail_photo_path': thumbnailPhotoPath,
      'device_info': deviceInfo,
    };
  }

  factory HazardReport.fromJson(Map<String, dynamic> json) {
    return HazardReport(
      id: json['id'] as String,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      gpsAccuracyMeters: (json['gps_accuracy_meters'] as num?)?.toDouble(),
      locationSource: LocationSource.fromString(
        json['location_source'] as String?,
      ),
      locationCapturedAt: json['location_captured_at'] != null
          ? DateTime.parse(json['location_captured_at'] as String)
          : null,
      distanceToAlignmentKm: (json['distance_to_alignment_km'] as num?)
          ?.toDouble(),
      kmMarker: (json['km_marker'] as num?)?.toDouble(),
      sectionId: json['section_id'] as String? ?? 'kurseong-ghum',
      nearestStationName: json['nearest_station_name'] as String?,
      confirmedHazardType: HazardType.fromString(
        json['confirmed_hazard_type'] as String?,
      ),
      confirmedSeverity: Severity.fromString(
        json['confirmed_severity'] as String?,
      ),
      userNote: json['user_note'] as String? ?? '',
      aiSuggestedHazardType: json['ai_suggested_hazard_type'] != null
          ? HazardType.fromString(json['ai_suggested_hazard_type'] as String?)
          : null,
      aiSuggestedSeverity: json['ai_suggested_severity'] != null
          ? Severity.fromString(json['ai_suggested_severity'] as String?)
          : null,
      aiNote: json['ai_note'] as String?,
      aiProvider: AiProvider.fromString(json['ai_provider'] as String?),
      aiModel: json['ai_model'] as String?,
      aiLanguage: json['ai_language'] != null
          ? AppLanguage.fromCode(json['ai_language'] as String?)
          : null,
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
      inspectionStatus: InspectionStatus.fromString(
        json['inspection_status'] as String?,
      ),
      syncStatus: SyncStatus.fromString(json['sync_status'] as String?),
      syncVersion: (json['sync_version'] as num?)?.toInt() ?? 1,
      syncTimestamp: json['sync_timestamp'] != null
          ? DateTime.parse(json['sync_timestamp'] as String)
          : null,
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      lastSyncError: json['last_sync_error'] as String?,
      originalPhotoPath: json['original_photo_path'] as String?,
      thumbnailPhotoPath: json['thumbnail_photo_path'] as String?,
      deviceInfo: json['device_info'] as String?,
    );
  }
}
