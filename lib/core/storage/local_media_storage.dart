import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/report_draft.dart';

class LocalMediaStorage {
  static const _uuid = Uuid();

  /// Copies temporary camera/gallery files into app-owned storage.
  /// Returns a draft whose paths remain valid after app restarts.
  Future<ReportDraft> persistDraftMedia(ReportDraft draft) async {
    final documents = await getApplicationDocumentsDirectory();

    final folder = Directory(
      p.join(documents.path, 'trackguard', 'media', _uuid.v4()),
    );

    await folder.create(recursive: true);

    try {
      final original = await _copyInto(
        sourcePath: draft.photoPath,
        destinationDirectory: folder,
        fileName: 'original',
      );

      String? thumbnailPath;
      if (draft.thumbnailPath != null) {
        final thumbnail = await _copyInto(
          sourcePath: draft.thumbnailPath!,
          destinationDirectory: folder,
          fileName: 'thumbnail',
        );
        thumbnailPath = thumbnail.path;
      }

      return draft.copyWith(
        photoPath: original.path,
        thumbnailPath: thumbnailPath,
      );
    } catch (_) {
      // Avoid leaving a partially copied media directory behind.
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
