import 'geo_location.dart';

class ReportDraft {
  final String photoPath;
  final String? thumbnailPath;
  final GeoLocation location;
  final DateTime createdAt;

  const ReportDraft({
    required this.photoPath,
    this.thumbnailPath,
    required this.location,
    required this.createdAt,
  });

  ReportDraft copyWith({
    String? photoPath,
    String? thumbnailPath,
    GeoLocation? location,
    DateTime? createdAt,
  }) {
    return ReportDraft(
      photoPath: photoPath ?? this.photoPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photo_path': photoPath,
      'thumbnail_path': thumbnailPath,
      'location': location.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReportDraft.fromJson(Map<String, dynamic> json) {
    return ReportDraft(
      photoPath: json['photo_path'] as String,
      thumbnailPath: json['thumbnail_path'] as String?,
      location: GeoLocation.fromJson(json['location'] as Map<String, dynamic>),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
