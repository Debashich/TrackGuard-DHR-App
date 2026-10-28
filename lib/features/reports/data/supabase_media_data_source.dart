import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/hazard_report.dart';

class SupabaseMediaDataSource {
  SupabaseMediaDataSource(this._client);

  final SupabaseClient _client;

  Future<void> uploadReportMedia(HazardReport report) async {
    final user = _client.auth.currentUser;

    final originalPath = report.originalPhotoPath;
    if (originalPath == null || originalPath.isEmpty) return;

    final originalFile = File(originalPath);
    if (!await originalFile.exists()) {
      throw FileSystemException(
        'Original report photo does not exist.',
        originalPath,
      );
    }

    final bucket = _client.storage.from('report-media');
    final userPrefix = user?.id ?? 'anonymous';
    final prefix = '$userPrefix/${report.id}';
    final extension = _extension(originalPath);
    final mimeType = _mimeType(extension);
    final remoteOriginalPath = '$prefix/original.$extension';

    await bucket.upload(
      remoteOriginalPath,
      originalFile,
      fileOptions: FileOptions(contentType: mimeType, upsert: true),
    );

    String? remoteThumbnailPath;
    final thumbnailPath = report.thumbnailPhotoPath;

    if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
      final thumbnailFile = File(thumbnailPath);

      if (await thumbnailFile.exists()) {
        final thumbnailExtension = _extension(thumbnailPath);
        remoteThumbnailPath = '$prefix/thumbnail.$thumbnailExtension';

        await bucket.upload(
          remoteThumbnailPath,
          thumbnailFile,
          fileOptions: FileOptions(
            contentType: _mimeType(thumbnailExtension),
            upsert: true,
          ),
        );
      }
    }

    await _client.from('report_media').upsert({
      'id': const Uuid().v4(),
      'report_id': report.id,
      'original_path': remoteOriginalPath,
      'thumbnail_path': remoteThumbnailPath,
      'mime_type': mimeType,
      'file_size': await originalFile.length(),
    }, onConflict: 'report_id');
  }

  String _extension(String path) {
    final filename = path.split('/').last;
    final dot = filename.lastIndexOf('.');
    if (dot < 0 || dot == filename.length - 1) return 'jpg';
    return filename.substring(dot + 1).toLowerCase();
  }

  String _mimeType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }
}
