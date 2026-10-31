import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:lib_llama_cpp/lib_llama_cpp.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/ai_provider_config.dart';
import '../domain/offline_model_manager.dart';
import '../domain/offline_model_state.dart';
import 'huggingface_model_downloader.dart';
import 'offline_model_artifact_validator.dart';

class LlamaOfflineModelManager implements OfflineModelManager {
  final ConnectivityService _connectivityService;
  final Future<Directory> Function() _getDocDir;
  final HuggingFaceModelDownloader _downloader;
  final OfflineModelArtifactValidator _validator;

  final StreamController<OfflineModelState> _stateController =
      StreamController<OfflineModelState>.broadcast();

  OfflineModelState _currentState;
  OfflineModelDownloadSettings _downloadSettings =
      const OfflineModelDownloadSettings();

  LlamaOpenAIClient? _client;
  bool _isInitialized = false;

  static const int requiredFreeDiskSpaceBytes =
      1800 * 1024 * 1024; // ~1.8 GB free

  LlamaOfflineModelManager({
    ConnectivityService? connectivityService,
    LlamaOpenAIClient? client,
    Future<Directory> Function()? getDocDir,
    HuggingFaceModelDownloader? downloader,
    OfflineModelArtifactValidator? validator,
  })  : _connectivityService =
            connectivityService ?? DefaultConnectivityService(),
        _client = client,
        _isInitialized = client != null,
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

  LlamaOpenAIClient? get client => _client;
  bool get isModelLoaded => _isInitialized && _client != null;
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

      // Clean up legacy placeholder path if present
      final oldDir = Directory('${docDir.path}/models/gemma-4-e2b-it');
      if (await oldDir.exists()) {
        try {
          await oldDir.delete(recursive: true);
        } catch (_) {}
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

      // Strictly validate model artifact existence, format, and minimum threshold
      final validation = await _validator.validateArtifact(
        directoryPath: modelDirPath,
        expectedFilename: AiProviderConfig.offlineGemmaFile,
        expectedSha256: AiProviderConfig.offlineGemmaSha256.isNotEmpty
            ? AiProviderConfig.offlineGemmaSha256
            : savedSha256,
        minSizeBytes: AiProviderConfig.offlineGemmaMinSizeBytes,
      );

      if (validation.isValid && validation.artifactFile != null) {
        // Genuine artifact present on disk
        _updateState(
          _currentState.copyWith(
            status: _isInitialized
                ? OfflineModelStatus.ready
                : OfflineModelStatus.downloaded,
            downloadedBytes: validation.fileSizeBytes,
            totalBytes: validation.fileSizeBytes,
            progress: 1.0,
            sha256: validation.sha256 ?? savedSha256,
            downloadedAt: savedDownloadedAt ??
                (await validation.artifactFile!.stat()).modified,
            lastInitializedAt: lastInitAt,
            lastInitializationError: lastInitError,
            canCancel: false,
            canDelete: true,
            errorMessage: null,
          ),
        );
        return;
      }

      final dir = Directory(modelDirPath);
      final exists = await dir.exists();
      if (exists) {
        final files = await dir.list().toList();
        if (files.isNotEmpty) {
          // Files exist but artifact is invalid/corrupt
          _updateState(
            _currentState.copyWith(
              status: OfflineModelStatus.corrupted,
              downloadedBytes: 0,
              totalBytes: AiProviderConfig.offlineGemmaEstimatedSizeBytes,
              progress: 0.0,
              canCancel: false,
              canDelete: true,
              errorMessage:
                  validation.errorMessage ?? 'Invalid model artifact found.',
            ),
          );
          return;
        }
      }

      // Model does not exist
      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.notDownloaded,
          downloadedBytes: 0,
          totalBytes: AiProviderConfig.offlineGemmaEstimatedSizeBytes,
          progress: 0.0,
          canCancel: false,
          canDelete: false,
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('Error checking offline model availability: $e');
      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.failed,
          errorMessage: e.toString(),
          canCancel: false,
        ),
      );
    }
  }

  @override
  Future<void> download() async {
    if (_currentState.status == OfflineModelStatus.downloading) {
      throw const OfflineModelDownloadFailedException(
        'A download is already in progress.',
      );
    }

    // 1. Connectivity Precondition Check
    final isOnline = await _connectivityService.isOnline();
    if (!isOnline) {
      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.failed,
          errorMessage: 'Network connection required to download the model.',
        ),
      );
      throw const OfflineModelNetworkUnavailableException();
    }

    // 2. Wi-Fi Only Precondition Check
    if (_downloadSettings.wifiOnly &&
        !_downloadSettings.allowCellularDownload) {
      try {
        final results = await Connectivity().checkConnectivity();
        final hasWifi =
            results.contains(ConnectivityResult.wifi) ||
            results.contains(ConnectivityResult.ethernet);
        if (!hasWifi) {
          _updateState(
            _currentState.copyWith(
              status: OfflineModelStatus.failed,
              errorMessage:
                  'Wi-Fi required. Cellular download is disabled in settings.',
            ),
          );
          throw const OfflineModelNetworkUnavailableException(
            'Wi-Fi connection required. Enable cellular download in settings to proceed.',
          );
        }
      } catch (e) {
        if (e is AppException) rethrow;
      }
    }

    // 3. Storage Precondition Check
    try {
      final docDir = await _getDocDir();
      if (!await docDir.exists()) {
        await docDir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Storage precondition check error: $e');
    }

    _updateState(
      _currentState.copyWith(
        status: OfflineModelStatus.downloading,
        downloadedBytes: 0,
        totalBytes: AiProviderConfig.offlineGemmaEstimatedSizeBytes,
        progress: 0.0,
        canCancel: true,
        canDelete: false,
        errorMessage: null,
      ),
    );

    final modelDirPath = await _getModelDirPath();

    try {
      // Download directly from Hugging Face with real byte streaming & verification
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

      // Download multimodal vision projector into model folder if configured
      if (AiProviderConfig.offlineGemmaProjectorFile.isNotEmpty) {
        try {
          await _downloader.download(
            repository: AiProviderConfig.offlineGemmaRepository,
            file: AiProviderConfig.offlineGemmaProjectorFile,
            branch: AiProviderConfig.offlineGemmaBranch,
            destinationDirectoryPath: modelDirPath,
            authToken: _downloadSettings.huggingFaceToken,
            minSizeBytes: 5 * 1024 * 1024,
            onProgress: (pBytes, pTotal, pProgress) {
              // Multimodal projector download progress
            },
          );
        } catch (e) {
          debugPrint('Vision projector download note: $e');
        }
      }

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

    // Verify artifact integrity prior to initializing native llama.cpp FFI
    final validation = await _validator.validateArtifact(
      directoryPath: modelDirPath,
      expectedFilename: AiProviderConfig.offlineGemmaFile,
      expectedSha256: AiProviderConfig.offlineGemmaSha256.isNotEmpty
          ? AiProviderConfig.offlineGemmaSha256
          : _currentState.sha256,
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
      final projectorFile = File(
        '$modelDirPath/${AiProviderConfig.offlineGemmaProjectorFile}',
      );
      final hasProjector = await projectorFile.exists();

      // Close previous client if present
      await _client?.close();

      // Configure native llama.cpp with base GGUF and optional vision projector GGUF
      _client = LlamaOpenAIClient(
        models: {
          AiProviderConfig.offlineGemmaSlug: LlamaModelConfig(
            modelPath: modelPath,
            mmprojPath: hasProjector ? projectorFile.path : null,
            contextSize: 2048,
          ),
        },
      );
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
      debugPrint('Failed to initialize Llama model context: $e');
      final errorMsg = 'Native llama.cpp initialization failed: $e';
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
      await _client?.close();
      _client = null;
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
    _client?.close();
  }
}

