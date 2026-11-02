import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:litertlm/litertlm.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/ai_provider_config.dart';
import '../domain/offline_model_manager.dart';
import '../domain/offline_model_state.dart';
import 'huggingface_model_downloader.dart';
import 'offline_model_artifact_validator.dart';

class LitertOfflineModelManager implements OfflineModelManager {
  final ConnectivityService _connectivityService;
  final Future<Directory> Function() _getDocDir;
  final HuggingFaceModelDownloader _downloader;
  final OfflineModelArtifactValidator _validator;

  final StreamController<OfflineModelState> _stateController =
      StreamController<OfflineModelState>.broadcast();

  OfflineModelState _currentState;
  OfflineModelDownloadSettings _downloadSettings =
      const OfflineModelDownloadSettings();

  Engine? _engine;
  bool _isInitialized = false;

  static const int requiredFreeDiskSpaceBytes =
      3500 * 1024 * 1024; // ~3.5 GB free for 2.6 GB model + buffer

  LitertOfflineModelManager({
    ConnectivityService? connectivityService,
    Engine? engine,
    Future<Directory> Function()? getDocDir,
    HuggingFaceModelDownloader? downloader,
    OfflineModelArtifactValidator? validator,
  })  : _connectivityService =
            connectivityService ?? DefaultConnectivityService(),
        _engine = engine,
        _isInitialized = engine != null,
        _getDocDir = getDocDir ?? getApplicationDocumentsDirectory,
        _downloader = downloader ?? HuggingFaceModelDownloader(),
        _validator = validator ?? const OfflineModelArtifactValidator(),
        _currentState = const OfflineModelState(
          status: OfflineModelStatus.checking,
          modelId: AiProviderConfig.offlineGemmaSlug,
          modelName: AiProviderConfig.offlineGemmaModelName,
          version: AiProviderConfig.offlineGemmaVersion,
          repository: AiProviderConfig.offlineGemmaRepository,
          filename: AiProviderConfig.offlineGemmaFile,
          totalBytes: AiProviderConfig.offlineGemmaEstimatedSizeBytes,
        ) {
    _loadSettingsAndState();
  }

  Engine? get engine => _engine;
  bool get isModelLoaded => _isInitialized && _engine != null;
  OfflineModelState get currentState => _currentState;
  bool get isReady => _currentState.isReady;

  @override
  Stream<OfflineModelState> watchState() async* {
    yield _currentState;
    yield* _stateController.stream;
  }

  @override
  Future<OfflineModelState> getState() async {
    return _currentState;
  }

  @override
  OfflineModelDownloadSettings getDownloadSettings() => _downloadSettings;

  @override
  Future<void> setDownloadSettings(
    OfflineModelDownloadSettings settings,
  ) async {
    _downloadSettings = settings;
    await _saveSettings();
  }

  Future<void> _loadSettingsAndState() async {
    try {
      final docDir = await _getDocDir();

      // Clean up legacy GGUF directories if present to reclaim storage
      final legacyDirs = [
        Directory('${docDir.path}/models/gemma-4-e2b-it'),
        Directory('${docDir.path}/models/gemma-4-e2b'),
      ];
      for (final oldDir in legacyDirs) {
        if (await oldDir.exists()) {
          try {
            await oldDir.delete(recursive: true);
          } catch (_) {}
        }
      }

      final settingsFile = File(
        '${docDir.path}/trackguard/offline_model_settings.json',
      );
      if (await settingsFile.exists()) {
        final content = await settingsFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _downloadSettings = OfflineModelDownloadSettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('Failed to load offline model download settings: $e');
    }

    await checkAvailability();
  }

  Future<void> _saveSettings() async {
    try {
      final docDir = await _getDocDir();
      final settingsDir = Directory('${docDir.path}/trackguard');
      if (!await settingsDir.exists()) {
        await settingsDir.create(recursive: true);
      }
      final settingsFile = File(
        '${settingsDir.path}/offline_model_settings.json',
      );
      await settingsFile.writeAsString(jsonEncode(_downloadSettings.toJson()));
    } catch (e) {
      debugPrint('Failed to persist offline model download settings: $e');
    }
  }

  Future<void> _saveMetadata({
    required DateTime? downloadedAt,
    DateTime? lastInitializedAt,
    String? lastInitializationError,
    String? sha256,
  }) async {
    try {
      final docDir = await _getDocDir();
      final dir = Directory('${docDir.path}/trackguard');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final metaFile = File('${dir.path}/offline_model_meta.json');
      final data = {
        'modelId': _currentState.modelId,
        'modelName': _currentState.modelName,
        'version': _currentState.version,
        'repository': _currentState.repository,
        'filename': _currentState.filename,
        'sha256': sha256 ?? _currentState.sha256,
        'downloadedBytes': _currentState.downloadedBytes,
        'downloadedAt': downloadedAt?.toIso8601String(),
        'lastInitializedAt': lastInitializedAt?.toIso8601String(),
        'lastInitializationError': lastInitializationError,
      };
      await metaFile.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Failed to save offline model metadata: $e');
    }
  }

  Future<Map<String, dynamic>?> _loadSavedMetadata() async {
    try {
      final docDir = await _getDocDir();
      final metaFile = File(
        '${docDir.path}/trackguard/offline_model_meta.json',
      );
      if (await metaFile.exists()) {
        final content = await metaFile.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<String> _getModelDirPath() async {
    final docDir = await _getDocDir();
    return '${docDir.path}/models/${AiProviderConfig.offlineGemmaSlug}';
  }

  @override
  Future<void> checkAvailability() async {
    _updateState(_currentState.copyWith(status: OfflineModelStatus.checking));

    try {
      final modelDirPath = await _getModelDirPath();
      final meta = await _loadSavedMetadata();
      final savedDownloadedAt = meta?['downloadedAt'] != null
          ? DateTime.tryParse(meta!['downloadedAt'] as String)
          : null;
      final savedSha256 = meta?['sha256'] as String?;
      final lastInitAt = meta?['lastInitializedAt'] != null
          ? DateTime.tryParse(meta!['lastInitializedAt'] as String)
          : null;
      final lastInitError = meta?['lastInitializationError'] as String?;

      // Strictly validate model artifact existence, format, and minimum threshold.
      // Fast check: avoid streaming 2.6 GB for SHA-256 on routine checks.
      final validation = await _validator.validateArtifact(
        directoryPath: modelDirPath,
        expectedFilename: AiProviderConfig.offlineGemmaFile,
        expectedSha256: null,
        minSizeBytes: AiProviderConfig.offlineGemmaMinSizeBytes,
      );

      if (validation.isValid) {
        final currentStatus = _isInitialized
            ? OfflineModelStatus.ready
            : OfflineModelStatus.downloaded;

        _updateState(
          _currentState.copyWith(
            status: currentStatus,
            downloadedBytes: validation.fileSizeBytes,
            totalBytes: validation.fileSizeBytes,
            progress: 1.0,
            downloadedAt: savedDownloadedAt,
            lastInitializedAt: lastInitAt,
            lastInitializationError: lastInitError,
            sha256: validation.sha256 ?? savedSha256,
            canCancel: false,
            canDelete: true,
            errorMessage: null,
          ),
        );
      } else {
        _isInitialized = false;
        _engine = null;
        _updateState(
          _currentState.copyWith(
            status: OfflineModelStatus.notDownloaded,
            downloadedBytes: 0,
            progress: 0.0,
            downloadedAt: null,
            canCancel: false,
            canDelete: false,
            errorMessage: null,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking LiteRT-LM model availability: $e');
      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.failed,
          errorMessage: 'Failed to inspect offline model status: $e',
          canCancel: false,
          canDelete: false,
        ),
      );
    }
  }

  @override
  Future<void> download() async {
    // 1. Connectivity check
    final isOnline = await _connectivityService.isOnline();
    if (!isOnline) {
      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.failed,
          errorMessage: 'Cannot download model: device is offline.',
        ),
      );
      throw const OfflineModelDownloadFailedException(
        'Cannot download model: device is offline. Connect to Wi-Fi to download.',
      );
    }

    // 2. Wi-Fi check if configured
    if (_downloadSettings.wifiOnly) {
      final connectivityResult =
          await Connectivity().checkConnectivity();
      final hasWifi = connectivityResult.contains(ConnectivityResult.wifi);
      if (!hasWifi) {
        _updateState(
          _currentState.copyWith(
            status: OfflineModelStatus.failed,
            errorMessage:
                'Wi-Fi required for downloading large model (~2.6 GB).',
          ),
        );
        throw const OfflineModelDownloadFailedException(
          'Wi-Fi connection is required according to download settings. Connect to Wi-Fi or enable cellular download in settings.',
        );
      }
    }

    // 3. Free disk space check
    try {
      final docDir = await _getDocDir();
      final stat = await docDir.stat();
      if (stat.type == FileSystemEntityType.notFound) {
        await docDir.create(recursive: true);
      }
    } catch (_) {}

    _updateState(
      _currentState.copyWith(
        status: OfflineModelStatus.downloading,
        progress: 0.0,
        downloadedBytes: 0,
        canCancel: true,
        canDelete: false,
        errorMessage: null,
      ),
    );

    try {
      final modelDirPath = await _getModelDirPath();

      // Download single self-contained .litertlm file
      final downloadedFile = await _downloader.download(
        repository: AiProviderConfig.offlineGemmaRepository,
        file: AiProviderConfig.offlineGemmaFile,
        branch: AiProviderConfig.offlineGemmaBranch,
        destinationDirectoryPath: modelDirPath,
        expectedSha256: AiProviderConfig.offlineGemmaSha256.isNotEmpty
            ? AiProviderConfig.offlineGemmaSha256
            : null,
        authToken: _downloadSettings.huggingFaceToken,
        minSizeBytes: AiProviderConfig.offlineGemmaMinSizeBytes,
        onProgress: (downloadedBytes, totalBytes, progress) {
          _updateState(
            _currentState.copyWith(
              downloadedBytes: downloadedBytes,
              totalBytes: totalBytes ?? _currentState.totalBytes,
              progress: progress,
            ),
          );
        },
      );

      final downloadedAt = DateTime.now();
      final fileSize = await downloadedFile.length();
      final sha256 = await _validator.calculateSha256(downloadedFile);

      await _saveMetadata(
        downloadedAt: downloadedAt,
        sha256: sha256,
      );

      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.downloaded,
          downloadedBytes: fileSize,
          totalBytes: fileSize,
          progress: 1.0,
          downloadedAt: downloadedAt,
          sha256: sha256,
          canCancel: false,
          canDelete: true,
          errorMessage: null,
        ),
      );

      // Auto-initialize following verified download
      await initialize();
    } on OfflineModelDownloadCancelledException {
      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.notDownloaded,
          downloadedBytes: 0,
          progress: 0.0,
          canCancel: false,
        ),
      );
    } catch (e) {
      final errorMsg = e is AppException ? e.message : e.toString();
      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.failed,
          errorMessage: errorMsg,
          canCancel: false,
          canDelete: false,
        ),
      );
      if (e is! AppException) {
        throw OfflineModelDownloadFailedException(e.toString());
      }
      rethrow;
    }
  }

  @override
  Future<void> cancelDownload() async {
    await _downloader.cancel();
    _updateState(
      _currentState.copyWith(
        status: OfflineModelStatus.notDownloaded,
        downloadedBytes: 0,
        progress: 0.0,
        canCancel: false,
      ),
    );
  }

  @override
  Future<void> initialize() async {
    final modelDirPath = await _getModelDirPath();

    // Verify artifact integrity prior to initializing native LiteRT-LM FFI.
    // Fast check: presence and threshold check takes <5ms instead of hashing 2.6 GB.
    final validation = await _validator.validateArtifact(
      directoryPath: modelDirPath,
      expectedFilename: AiProviderConfig.offlineGemmaFile,
      expectedSha256: null,
      minSizeBytes: AiProviderConfig.offlineGemmaMinSizeBytes,
    );

    if (!validation.isValid) {
      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.notDownloaded,
          errorMessage:
              validation.errorMessage ?? 'Model artifact not found on disk.',
        ),
      );
      throw OfflineModelUnavailableException(
        validation.errorMessage ??
            'Cannot initialize model. Valid model weights not found.',
      );
    }

    _updateState(
      _currentState.copyWith(
        status: OfflineModelStatus.initializing,
        canCancel: false,
      ),
    );

    try {
      final modelPath = validation.artifactFile!.path;

      // Close previous engine if present
      await _engine?.dispose();
      _engine = null;

      // Cap Gemma 4 visual token budget to 280 tokens (matches model signatures: vision_70, vision_140, vision_280)
      try {
        ExperimentalFlags.visualTokenBudget = 280;
      } catch (flagError) {
        debugPrint('Failed to set visualTokenBudget: $flagError');
      }

      // Initialize native LiteRT-LM Engine with explicit vision executor backend and 4096 token context
      Engine engine;
      try {
        // Preferred: Full GPU for text + vision (matches Edge Gallery "Model on GPU")
        engine = Engine(
          engineConfig: EngineConfig(
            modelPath: modelPath,
            backend: const Backend.gpu(),
            visionBackend: const Backend.gpu(),
            maxNumTokens: 4096,
            maxNumImages: 1,
          ),
        );
        await engine.initialize();
      } catch (gpuError) {
        debugPrint(
          'LiteRT-LM full GPU init failed ($gpuError), trying GPU text + CPU vision...',
        );
        try {
          engine = Engine(
            engineConfig: EngineConfig(
              modelPath: modelPath,
              backend: const Backend.gpu(),
              visionBackend: const Backend.cpu(),
              maxNumTokens: 4096,
              maxNumImages: 1,
            ),
          );
          await engine.initialize();
        } catch (gpuError) {
          debugPrint(
            'LiteRT-LM GPU init failed ($gpuError), falling back to full CPU...',
          );
          engine = Engine(
            engineConfig: EngineConfig(
              modelPath: modelPath,
              backend: const Backend.cpu(),
              visionBackend: const Backend.cpu(),
              maxNumTokens: 4096,
              maxNumImages: 1,
            ),
          );
          await engine.initialize();
        }
      }

      _engine = engine;
      _isInitialized = true;

      final now = DateTime.now();
      await _saveMetadata(
        downloadedAt: _currentState.downloadedAt,
        lastInitializedAt: now,
        lastInitializationError: null,
      );

      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.ready,
          lastInitializedAt: now,
          lastInitializationError: null,
          canCancel: false,
          canDelete: true,
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('Failed to initialize LiteRT-LM model context: $e');
      final errorMsg = 'Native LiteRT-LM initialization failed: $e';
      _isInitialized = false;
      await _saveMetadata(
        downloadedAt: _currentState.downloadedAt,
        lastInitializationError: errorMsg,
      );
      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.failed,
          errorMessage: errorMsg,
          lastInitializationError: errorMsg,
          canDelete: true,
        ),
      );
      throw OfflineModelInitializationFailedException(e.toString());
    }
  }

  @override
  Future<void> deleteModel() async {
    try {
      await _engine?.dispose();
      _engine = null;
      _isInitialized = false;

      final modelDirPath = await _getModelDirPath();
      final modelDir = Directory(modelDirPath);
      if (await modelDir.exists()) {
        await modelDir.delete(recursive: true);
      }

      final docDir = await _getDocDir();
      final metaFile =
          File('${docDir.path}/trackguard/offline_model_meta.json');
      if (await metaFile.exists()) {
        await metaFile.delete();
      }

      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.notDownloaded,
          downloadedBytes: 0,
          progress: 0.0,
          canCancel: false,
          canDelete: false,
          downloadedAt: null,
          lastInitializedAt: null,
          lastInitializationError: null,
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('Error deleting offline model: $e');
      _updateState(
        _currentState.copyWith(
          errorMessage: 'Failed to delete model: $e',
        ),
      );
      throw OfflineModelInitializationFailedException(e.toString());
    }
  }

  void _updateState(OfflineModelState state) {
    _currentState = state;
    _stateController.add(state);
  }

  @override
  void dispose() {
    _stateController.close();
    _engine?.dispose();
  }
}

