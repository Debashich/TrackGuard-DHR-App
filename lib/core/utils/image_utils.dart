import 'dart:io';
import 'dart:math' as math;
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

  /// Prepares an optimized image specifically for on-device VLM (LiteRT-LM Gemma 4 E2B) inference.
  ///
  /// CRITICAL FOR ACCURACY:
  /// Preserves the photo's original aspect ratio (never squashes to a square) so track geometry,
  /// sleeper alignment, and fine rail cracks remain clear, sharp, and undistorted.
  ///
  /// Caps the longest dimension (default 1024) and caps total pixel count to stay safely under
  /// the 280-token budget (approx 600,000 pixels = ~2340 16x16 patches, comfortably below the 2520 patch cap of vision_280).
  static Future<File> prepareOptimizedVisionImage(
    File sourceFile, {
    int maxLongestSide = 1024,
    int maxPixelArea = 600000,
  }) async {
    try {
      final bytes = await sourceFile.readAsBytes();
      final descriptor = await ui.ImageDescriptor.encoded(
        await ui.ImmutableBuffer.fromUint8List(bytes),
      );

      final originalWidth = descriptor.width;
      final originalHeight = descriptor.height;

      if (originalWidth <= 0 || originalHeight <= 0) {
        return sourceFile;
      }

      // Calculate scale to fit within maxLongestSide while strictly maintaining original aspect ratio
      double scale = 1.0;
      final longestSide = math.max(originalWidth, originalHeight);
      if (longestSide > maxLongestSide) {
        scale = maxLongestSide / longestSide;
      }

      var targetWidth = (originalWidth * scale).round();
      var targetHeight = (originalHeight * scale).round();

      // Ensure total pixel area stays safely within the 280-token budget (~600K pixels)
      final currentPixelArea = targetWidth * targetHeight;
      if (currentPixelArea > maxPixelArea) {
        final areaScale = math.sqrt(maxPixelArea / currentPixelArea);
        targetWidth = (targetWidth * areaScale).round();
        targetHeight = (targetHeight * areaScale).round();
      }

      // Round to nearest multiple of 16 (Gemma 4 vision encoder patch size is 16x16)
      targetWidth = math.max(64, (targetWidth ~/ 16) * 16);
      targetHeight = math.max(64, (targetHeight ~/ 16) * 16);

      final codec = await descriptor.instantiateCodec(
        targetWidth: targetWidth,
        targetHeight: targetHeight,
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
        'Prepared aspect-ratio-preserved vision image: ${originalWidth}x$originalHeight -> ${targetWidth}x$targetHeight (${targetFile.lengthSync()} bytes)',
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
