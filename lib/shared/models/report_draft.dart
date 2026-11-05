import 'geo_location.dart';
import 'hazard_type.dart';
import 'severity.dart';

class ReportDraft {
  final String sessionId;
  final String photoPath;
  final String? thumbnailPath;
  final GeoLocation location;
  final DateTime createdAt;

  // Review-stage values. Null means the report has not been reviewed yet.
  final HazardType? confirmedHazard;
  final Severity? confirmedSeverity;
  final double? reviewKmMarker;
  final String? gangmanNote;

  const ReportDraft({
    required this.sessionId,
    required this.photoPath,
    this.thumbnailPath,
    required this.location,
    required this.createdAt,
    this.confirmedHazard,
    this.confirmedSeverity,
    this.reviewKmMarker,
    this.gangmanNote,
  });

  ReportDraft copyWith({
    String? sessionId,
    String? photoPath,
    String? thumbnailPath,
    GeoLocation? location,
    DateTime? createdAt,
    HazardType? confirmedHazard,
    Severity? confirmedSeverity,
    double? reviewKmMarker,
    String? gangmanNote,
  }) {
    return ReportDraft(
      sessionId: sessionId ?? this.sessionId,
      photoPath: photoPath ?? this.photoPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      confirmedHazard: confirmedHazard ?? this.confirmedHazard,
      confirmedSeverity: confirmedSeverity ?? this.confirmedSeverity,
      reviewKmMarker: reviewKmMarker ?? this.reviewKmMarker,
      gangmanNote: gangmanNote ?? this.gangmanNote,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'photo_path': photoPath,
      'thumbnail_path': thumbnailPath,
      'location': location.toJson(),
      'created_at': createdAt.toIso8601String(),
      'confirmed_hazard': confirmedHazard?.toJson(),
      'confirmed_severity': confirmedSeverity?.toJson(),
      'review_km_marker': reviewKmMarker,
      'gangman_note': gangmanNote,
    };
  }

  factory ReportDraft.fromJson(Map<String, dynamic> json) {
    return ReportDraft(
      sessionId:
          json['session_id'] as String? ??
          'legacy-${json['created_at'] ?? 'unknown'}',
      photoPath: json['photo_path'] as String,
      thumbnailPath: json['thumbnail_path'] as String?,
      location: GeoLocation.fromJson(json['location'] as Map<String, dynamic>),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      confirmedHazard: json['confirmed_hazard'] != null
          ? HazardType.fromString(json['confirmed_hazard'] as String)
          : null,
      confirmedSeverity: json['confirmed_severity'] != null
          ? Severity.fromString(json['confirmed_severity'] as String)
          : null,
      reviewKmMarker: (json['review_km_marker'] as num?)?.toDouble(),
      gangmanNote: json['gangman_note'] as String?,
    );
  }
}
