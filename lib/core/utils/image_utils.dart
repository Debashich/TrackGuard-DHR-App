import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
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

  /// Prepares an optimized, 1:1 square downscaled image specifically for on-device VLM (LiteRT-LM) inference.
  /// A square aspect ratio (448x448) ensures LiteRT-LM's internal preprocessor maps directly
  /// to the model's compiled `vision_280` (or `vision_140`) signature instead of attempting
  /// dynamic multi-tile upscaling for portrait/landscape ratios that exceeds the model's 280-token budget.
  static Future<File> prepareOptimizedVisionImage(
    File sourceFile, {
    int targetDimension = 448,
  }) async {
    try {
      final bytes = await sourceFile.readAsBytes();
      final descriptor = await ui.ImageDescriptor.encoded(
        await ui.ImmutableBuffer.fromUint8List(bytes),
      );

      final originalWidth = descriptor.width;
      final originalHeight = descriptor.height;

      // Decode directly as 1:1 square to ensure preprocessor produces <= 280 tokens
      final codec = await descriptor.instantiateCodec(
        targetWidth: targetDimension,
        targetHeight: targetDimension,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return sourceFile;
      }

      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/vision_${_uuid.v4()}.png';
      final targetFile = File(targetPath);
      await targetFile.writeAsBytes(byteData.buffer.asUint8List());

      debugPrint(
        'Optimized square vision image: ${originalWidth}x$originalHeight -> ${targetDimension}x$targetDimension (${targetFile.lengthSync()} bytes)',
      );
      return targetFile;
    } catch (e) {
      debugPrint(
        'Failed to optimize image for vision model: $e. Using original.',
      );
      return sourceFile;
    }
  }
}
