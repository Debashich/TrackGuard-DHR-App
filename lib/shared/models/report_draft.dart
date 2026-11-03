import 'geo_location.dart';
import 'report_photo.dart';

class ReportDraft {
  final String photoPath;
  final String? thumbnailPath;
  final List<ReportPhoto> additionalPhotos;
  final GeoLocation location;
  final DateTime createdAt;

  const ReportDraft({
    required this.photoPath,
    this.thumbnailPath,
    this.additionalPhotos = const [],
    required this.location,
    required this.createdAt,
  });

  List<ReportPhoto> get photos => [
    ReportPhoto(originalPath: photoPath, thumbnailPath: thumbnailPath),
    ...additionalPhotos,
  ];

  ReportDraft copyWith({
    String? photoPath,
    String? thumbnailPath,
    List<ReportPhoto>? additionalPhotos,
    GeoLocation? location,
    DateTime? createdAt,
  }) {
    return ReportDraft(
      photoPath: photoPath ?? this.photoPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      additionalPhotos: additionalPhotos ?? this.additionalPhotos,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photo_path': photoPath,
      'thumbnail_path': thumbnailPath,
      'additional_photos': additionalPhotos
          .map((photo) => photo.toJson())
          .toList(),
      'location': location.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReportDraft.fromJson(Map<String, dynamic> json) {
    final extraPhotos =
        (json['additional_photos'] as List<dynamic>?)
            ?.map(
              (photo) =>
                  ReportPhoto.fromJson(Map<String, dynamic>.from(photo as Map)),
            )
            .toList() ??
        const <ReportPhoto>[];

    return ReportDraft(
      photoPath: json['photo_path'] as String,
      thumbnailPath: json['thumbnail_path'] as String?,
      additionalPhotos: extraPhotos,
      location: GeoLocation.fromJson(json['location'] as Map<String, dynamic>),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
