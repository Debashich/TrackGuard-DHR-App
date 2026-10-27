import 'location_source.dart';

class GeoLocation {
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final double? kmMarker;
  final String sectionId;
  final String? nearestStationName;
  final double? distanceToAlignmentKm;
  final DateTime capturedAt;
  final LocationSource source;
  final bool isSimulated;

  const GeoLocation({
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.kmMarker,
    required this.sectionId,
    this.nearestStationName,
    this.distanceToAlignmentKm,
    required this.capturedAt,
    this.source = LocationSource.gps,
    this.isSimulated = false,
  });

  GeoLocation copyWith({
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    double? kmMarker,
    String? sectionId,
    String? nearestStationName,
    double? distanceToAlignmentKm,
    DateTime? capturedAt,
    LocationSource? source,
    bool? isSimulated,
  }) {
    return GeoLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      kmMarker: kmMarker ?? this.kmMarker,
      sectionId: sectionId ?? this.sectionId,
      nearestStationName: nearestStationName ?? this.nearestStationName,
      distanceToAlignmentKm:
          distanceToAlignmentKm ?? this.distanceToAlignmentKm,
      capturedAt: capturedAt ?? this.capturedAt,
      source: source ?? this.source,
      isSimulated: isSimulated ?? this.isSimulated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracyMeters': accuracyMeters,
      'kmMarker': kmMarker,
      'sectionId': sectionId,
      'nearestStationName': nearestStationName,
      'distanceToAlignmentKm': distanceToAlignmentKm,
      'capturedAt': capturedAt.toIso8601String(),
      'source': source.toJson(),
      'isSimulated': isSimulated,
    };
  }

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
      kmMarker: (json['kmMarker'] as num?)?.toDouble(),
      sectionId: json['sectionId'] as String? ?? 'kurseong-ghum',
      nearestStationName: json['nearestStationName'] as String?,
      distanceToAlignmentKm: (json['distanceToAlignmentKm'] as num?)
          ?.toDouble(),
      capturedAt: json['capturedAt'] != null
          ? DateTime.parse(json['capturedAt'] as String)
          : DateTime.now(),
      source: LocationSource.fromString(json['source'] as String?),
      isSimulated: json['isSimulated'] as bool? ?? false,
    );
  }
}
