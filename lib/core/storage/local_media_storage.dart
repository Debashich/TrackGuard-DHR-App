import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/report_draft.dart';
import '../../shared/models/report_photo.dart';

class LocalMediaStorage {
  static const _uuid = Uuid();

  Future<ReportDraft> persistDraftMedia(ReportDraft draft) async {
    final documents = await getApplicationDocumentsDirectory();

    final folder = Directory(
      p.join(documents.path, 'trackguard', 'media', _uuid.v4()),
    );

    await folder.create(recursive: true);

    try {
      final persistedPhotos = <ReportPhoto>[];

      for (var i = 0; i < draft.photos.length; i++) {
        final photo = draft.photos[i];

        final original = await _copyInto(
          sourcePath: photo.originalPath,
          destinationDirectory: folder,
          fileName: 'original_$i',
        );

        String? thumbnailPath;

        if (photo.thumbnailPath != null) {
          final thumbnail = await _copyInto(
            sourcePath: photo.thumbnailPath!,
            destinationDirectory: folder,
            fileName: 'thumbnail_$i',
          );

          thumbnailPath = thumbnail.path;
        }

        persistedPhotos.add(
          ReportPhoto(
            originalPath: original.path,
            thumbnailPath: thumbnailPath,
          ),
        );
      }

      final primary = persistedPhotos.first;

      return draft.copyWith(
        photoPath: primary.originalPath,
        thumbnailPath: primary.thumbnailPath,
        additionalPhotos: persistedPhotos.skip(1).toList(),
      );
    } catch (_) {
      if (await folder.exists()) {
        await folder.delete(recursive: true);
      }

      rethrow;
    }
  }

  Future<File> _copyInto({
    required String sourcePath,
    required Directory destinationDirectory,
    required String fileName,
  }) async {
    final source = File(sourcePath);

    if (!await source.exists()) {
      throw FileSystemException('Source image does not exist', sourcePath);
    }

    final extension = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath);

    final destination = File(
      p.join(destinationDirectory.path, '$fileName$extension'),
    );

    return source.copy(destination.path);
  }
}
