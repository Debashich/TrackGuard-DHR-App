class ReportPhoto {
  final String originalPath;
  final String? thumbnailPath;

  const ReportPhoto({required this.originalPath, this.thumbnailPath});

  Map<String, dynamic> toJson() => {
    'original_path': originalPath,
    'thumbnail_path': thumbnailPath,
  };

  factory ReportPhoto.fromJson(Map<String, dynamic> json) {
    return ReportPhoto(
      originalPath: json['original_path'] as String,
      thumbnailPath: json['thumbnail_path'] as String?,
    );
  }
}
