import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../core/errors/app_exception.dart';
import '../domain/ai_provider_config.dart';
import 'offline_model_artifact_validator.dart';

typedef DownloadProgressCallback = void Function(
  int downloadedBytes,
  int? totalBytes,
  double progress,
);

class HuggingFaceModelDownloader {
  final HttpClient Function() _clientFactory;
  final OfflineModelArtifactValidator _validator;

  HttpClient? _currentClient;
  IOSink? _currentSink;
  File? _currentPartFile;
  bool _isCancelled = false;

  HuggingFaceModelDownloader({
    HttpClient Function()? clientFactory,
    OfflineModelArtifactValidator? validator,
  }) : _clientFactory = clientFactory ?? HttpClient.new,
       _validator = validator ?? const OfflineModelArtifactValidator();

  /// Builds a standard Hugging Face direct resolve URL.
  static String buildResolveUrl({
    required String repository,
    String branch = 'main',
    required String file,
  }) {
    final cleanRepo = repository.trim().replaceAll(RegExp(r'^/|/$'), '');
    final cleanFile = file.trim().replaceAll(RegExp(r'^/|/$'), '');
    final cleanBranch = branch.trim().isEmpty ? 'main' : branch.trim();
    return 'https://huggingface.co/$cleanRepo/resolve/$cleanBranch/$cleanFile?download=true';
  }

  /// Cancels an in-progress download and cleans up temporary partial files.
  Future<void> cancel() async {
    _isCancelled = true;
    try {
      _currentClient?.close(force: true);
    } catch (_) {}
    await _cleanupPartFile();
  }

  /// Downloads a model artifact from Hugging Face directly into destinationDirectoryPath.
  Future<File> download({
    required String repository,
    required String file,
    String branch = 'main',
    required String destinationDirectoryPath,
    String? expectedSha256,
    String? authToken,
    int? minSizeBytes,
    DownloadProgressCallback? onProgress,
  }) async {
    _isCancelled = false;

    final destDir = Directory(destinationDirectoryPath);
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    final finalFilePath = p.join(destinationDirectoryPath, file);
    final partFilePath = '$finalFilePath.part';
    final partFile = File(partFilePath);
    _currentPartFile = partFile;

    final resolveUrl = buildResolveUrl(
      repository: repository,
      branch: branch,
      file: file,
    );

    final client = _clientFactory();
    _currentClient = client;

    try {
      var requestUri = Uri.parse(resolveUrl);

      // Check if resuming an existing partial download is viable
      int existingBytes = 0;
      if (await partFile.exists()) {
        existingBytes = await partFile.length();
      }

      var request = await client.getUrl(requestUri);
      request.followRedirects = true;
      request.maxRedirects = 5;

      if (authToken != null && authToken.trim().isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ${authToken.trim()}',
        );
      }

      // If resuming, send Range header
      if (existingBytes > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$existingBytes-');
      }

      var response = await request.close();

      // Handle server redirects if not automatically redirected
      if (response.isRedirect) {
        final redirectUri = response.headers.value(HttpHeaders.locationHeader);
        if (redirectUri != null) {
          request = await client.getUrl(Uri.parse(redirectUri));
          request.followRedirects = true;
          if (authToken != null && authToken.trim().isNotEmpty) {
            request.headers.set(
              HttpHeaders.authorizationHeader,
              'Bearer ${authToken.trim()}',
            );
          }
          if (existingBytes > 0) {
            request.headers.set(
              HttpHeaders.rangeHeader,
              'bytes=$existingBytes-',
            );
          }
          response = await request.close();
        }
      }

      if (_isCancelled) {
        throw const OfflineModelDownloadCancelledException();
      }

      // Check status code
      final isResume = response.statusCode == HttpStatus.partialContent;
      if (response.statusCode != HttpStatus.ok && !isResume) {
        if (response.statusCode == HttpStatus.unauthorized ||
            response.statusCode == HttpStatus.forbidden) {
          throw const OfflineModelDownloadFailedException(
            'Hugging Face authorization required. Please provide a valid Hugging Face access token.',
          );
        }
        if (response.statusCode == HttpStatus.notFound) {
          throw OfflineModelDownloadFailedException(
            'Model artifact not found on Hugging Face: $repository/$file',
          );
        }
        throw OfflineModelDownloadFailedException(
          'Hugging Face download failed with HTTP status ${response.statusCode}',
        );
      }

      // Calculate total expected bytes
      int? totalBytes;
      if (isResume) {
        final contentRange = response.headers.value(HttpHeaders.contentRangeHeader);
        if (contentRange != null && contentRange.contains('/')) {
          final totalStr = contentRange.split('/').last.trim();
          totalBytes = int.tryParse(totalStr);
        }
        totalBytes ??= (response.contentLength > 0
            ? existingBytes + response.contentLength
            : null);
      } else {
        existingBytes = 0; // Server restarted from 0
        totalBytes = response.contentLength > 0 ? response.contentLength : null;
      }

      final mode = isResume ? FileMode.append : FileMode.write;
      final sink = partFile.openWrite(mode: mode);
      _currentSink = sink;

      int currentDownloadedBytes = existingBytes;

      await for (final chunk in response) {
        if (_isCancelled) {
          throw const OfflineModelDownloadCancelledException();
        }

        sink.add(chunk);
        currentDownloadedBytes += chunk.length;

        final double progress;
        if (totalBytes != null && totalBytes > 0) {
          progress = (currentDownloadedBytes / totalBytes).clamp(0.0, 1.0);
        } else {
          progress = 0.0;
        }

        onProgress?.call(currentDownloadedBytes, totalBytes, progress);
      }

      await sink.flush();
      await sink.close();
      _currentSink = null;

      if (_isCancelled) {
        throw const OfflineModelDownloadCancelledException();
      }

      // Pre-validation on the completed part file before renaming
      final minSize = minSizeBytes ?? AiProviderConfig.offlineGemmaMinSizeBytes;
      final downloadedSize = await partFile.length();
      if (downloadedSize < minSize) {
        await _cleanupPartFile();
        throw OfflineModelDownloadFailedException(
          'Downloaded model artifact is incomplete or too small (${(downloadedSize / (1024 * 1024)).toStringAsFixed(1)} MB).',
        );
      }

      // Checksum verification if specified
      if (expectedSha256 != null && expectedSha256.trim().isNotEmpty) {
        final actualHash = await _validator.calculateSha256(partFile);
        if (actualHash.toLowerCase() != expectedSha256.trim().toLowerCase()) {
          await _cleanupPartFile();
          throw OfflineModelDownloadFailedException(
            'SHA-256 checksum mismatch for downloaded artifact.',
          );
        }
      }

      // Atomic rename from .part to target filename
      final finalFile = File(finalFilePath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await partFile.rename(finalFilePath);
      _currentPartFile = null;

      // Final validation of artifact inside directory
      final validation = await _validator.validateArtifact(
        directoryPath: destinationDirectoryPath,
        expectedFilename: file,
        expectedSha256: expectedSha256,
        minSizeBytes: minSize,
      );

      if (!validation.isValid) {
        throw OfflineModelDownloadFailedException(
          validation.errorMessage ?? 'Model artifact validation failed.',
        );
      }

      return finalFile;
    } on OfflineModelDownloadCancelledException {
      await _cleanupPartFile();
      rethrow;
    } catch (e) {
      await _cleanupPartFile();
      if (e is AppException) rethrow;
      throw OfflineModelDownloadFailedException(
        'Failed to download model artifact from Hugging Face: $e',
      );
    } finally {
      client.close();
      _currentClient = null;
    }
  }

  Future<void> _cleanupPartFile() async {
    try {
      await _currentSink?.close();
      _currentSink = null;
    } catch (_) {}

    try {
      if (_currentPartFile != null && await _currentPartFile!.exists()) {
        await _currentPartFile!.delete();
      }
      _currentPartFile = null;
    } catch (e) {
      debugPrint('Error cleaning up partial download file: $e');
    }
  }
}

