import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../domain/ai_provider_config.dart';

class OfflineModelValidationResult {
  final bool isValid;
  final File? artifactFile;
  final int fileSizeBytes;
  final String? sha256;
  final String? errorMessage;

  const OfflineModelValidationResult({
    required this.isValid,
    this.artifactFile,
    this.fileSizeBytes = 0,
    this.sha256,
    this.errorMessage,
  });

  factory OfflineModelValidationResult.valid({
    required File file,
    required int sizeBytes,
    String? sha256,
  }) {
    return OfflineModelValidationResult(
      isValid: true,
      artifactFile: file,
      fileSizeBytes: sizeBytes,
      sha256: sha256,
    );
  }

  factory OfflineModelValidationResult.invalid(String message) {
    return OfflineModelValidationResult(
      isValid: false,
      errorMessage: message,
    );
  }
}

class OfflineModelArtifactValidator {
  const OfflineModelArtifactValidator();

  /// Validates that a model directory contains a genuine, non-placeholder model artifact.
  Future<OfflineModelValidationResult> validateArtifact({
    required String directoryPath,
    String? expectedFilename,
    String? expectedSha256,
    int? minSizeBytes,
  }) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      return OfflineModelValidationResult.invalid(
        'Model directory does not exist: $directoryPath',
      );
    }

    final targetFilename = expectedFilename ?? AiProviderConfig.offlineGemmaFile;
    final minSize = minSizeBytes ?? AiProviderConfig.offlineGemmaMinSizeBytes;

    // Search for expected file or any GGUF/bin weights file
    final targetPath = p.join(directoryPath, targetFilename);
    File? foundFile;

    final directFile = File(targetPath);
    if (await directFile.exists()) {
      foundFile = directFile;
    } else {
      // Look for any valid primary .gguf or .bin file in the directory
      final entities = await dir.list().toList();
      for (final entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          final basename = p.basename(entity.path).toLowerCase();
          if ((ext == '.gguf' || ext == '.bin') &&
              !basename.startsWith('mmproj')) {
            foundFile = entity;
            break;
          }
        }
      }
    }

    if (foundFile == null) {
      return OfflineModelValidationResult.invalid(
        'No valid model weight artifact (.gguf) found in $directoryPath',
      );
    }

    final fileSize = await foundFile.length();

    // Reject stubs and placeholders smaller than minimum threshold
    if (fileSize < minSize) {
      return OfflineModelValidationResult.invalid(
        'Model artifact size (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB) '
        'is below the minimum required threshold (${(minSize / (1024 * 1024)).toStringAsFixed(1)} MB). '
        'Corrupt or placeholder artifact detected.',
      );
    }

    // Verify SHA-256 checksum if configured
    String? computedSha256;
    if (expectedSha256 != null && expectedSha256.trim().isNotEmpty) {
      computedSha256 = await calculateSha256(foundFile);
      if (computedSha256.toLowerCase() != expectedSha256.trim().toLowerCase()) {
        return OfflineModelValidationResult.invalid(
          'SHA-256 checksum mismatch. Expected $expectedSha256, got $computedSha256',
        );
      }
    }

    return OfflineModelValidationResult.valid(
      file: foundFile,
      sizeBytes: fileSize,
      sha256: computedSha256,
    );
  }

  /// Calculates SHA-256 hash of a file efficiently using streaming.
  Future<String> calculateSha256(File file) async {
    try {
      final digest = await sha256.bind(file.openRead()).first;
      return digest.toString();
    } catch (e) {
      debugPrint('Error calculating SHA-256 checksum: $e');
      rethrow;
    }
  }
}

