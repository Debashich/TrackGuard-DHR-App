import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageUtils {
  static const _uuid = Uuid();

  /// Creates a durable local file copy in the app documents or cache directory
  static Future<File> persistCapturedImage(
    File sourceFile, {
    String prefix = 'img',
  }) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = '${prefix}_${_uuid.v4()}.jpg';
    final targetPath = '${tempDir.path}/$fileName';
    return sourceFile.copy(targetPath);
  }

  /// Create a thumbnail file path or copy
  static Future<File> generateThumbnail(File sourceFile) async {
    return persistCapturedImage(sourceFile, prefix: 'thumb');
  }
}
