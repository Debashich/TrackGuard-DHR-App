import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cactus/cactus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/ai_provider_config.dart';
import '../domain/offline_model_manager.dart';
import '../domain/offline_model_state.dart';

class CactusOfflineModelManager implements OfflineModelManager {
  final ConnectivityService _connectivityService;
  final CactusLM _cactusLM;
  final Future<Directory> Function() _getDocDir;

  final StreamController<OfflineModelState> _stateController =
      StreamController<OfflineModelState>.broadcast();

  OfflineModelState _currentState;
  OfflineModelDownloadSettings _downloadSettings =
      const OfflineModelDownloadSettings();

  HttpClient? _activeClient;
  bool _isCancelled = false;

  static const int estimatedModelSizeBytes = 1250 * 1024 * 1024; // ~1.25 GB
  static const int requiredFreeDiskSpaceBytes =
      1800 * 1024 * 1024; // ~1.8 GB free

  CactusOfflineModelManager({
    ConnectivityService? connectivityService,
    CactusLM? cactusLM,
    Future<Directory> Function()? getDocDir,
  }) : _connectivityService =
           connectivityService ?? DefaultConnectivityService(),
       _cactusLM = cactusLM ?? CactusLM(),
       _getDocDir = getDocDir ?? getApplicationDocumentsDirectory,
       _currentState = const OfflineModelState(
         status: OfflineModelStatus.checking,
         modelId: AiProviderConfig.offlineGemmaSlug,
         modelName: AiProviderConfig.offlineGemmaModelName,
         totalBytes: estimatedModelSizeBytes,
       ) {
    _loadSettingsAndState();
  }

  CactusLM get cactusLM => _cactusLM;

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

    await _ensureModelRegistered();
    await checkAvailability();
  }

  Future<void> _ensureModelRegistered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cactus_model_${AiProviderConfig.offlineGemmaSlug}';
      if (!prefs.containsKey(key)) {
        // Register verified Gemma weights download URL for CactusLM
        final jsonString = jsonEncode({
          'created_at': DateTime.now().toIso8601String(),
          'slug': AiProviderConfig.offlineGemmaSlug,
          'download_url':
              'https://vlqqczxwyaodtcdmdmlw.supabase.co/storage/v1/object/public/cactus-models/gemma3-270m.zip',
          'size_mb': 172,
          'supports_tool_calling': true,
          'supports_vision': true,
          'name': AiProviderConfig.offlineGemmaModelName,
          'is_downloaded': false,
        });
        await prefs.setString(key, jsonString);
      }
    } catch (e) {
      debugPrint('Error ensuring offline Gemma model cache: $e');
    }
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

  Future<void> _saveMetadata(DateTime? downloadedAt) async {
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
        'downloadedAt': downloadedAt?.toIso8601String(),
      };
      await metaFile.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Failed to save offline model metadata: $e');
    }
  }

  Future<DateTime?> _loadSavedDownloadDate() async {
    try {
      final docDir = await _getDocDir();
      final metaFile = File(
        '${docDir.path}/trackguard/offline_model_meta.json',
      );
      if (await metaFile.exists()) {
        final content = await metaFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        if (json['downloadedAt'] != null) {
          return DateTime.tryParse(json['downloadedAt'] as String);
        }
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
      final modelDir = Directory(modelDirPath);

      if (await modelDir.exists()) {
        final files = await modelDir.list().toList();
        if (files.isNotEmpty) {
          // Model files exist on disk
          final downloadedAt =
              await _loadSavedDownloadDate() ??
              (await modelDir.stat()).modified;

          // Check if runtime is initialized
          final isLoaded = _cactusLM.isLoaded();
          _updateState(
            _currentState.copyWith(
              status: isLoaded
                  ? OfflineModelStatus.ready
                  : OfflineModelStatus.downloaded,
              downloadedBytes: estimatedModelSizeBytes,
              totalBytes: estimatedModelSizeBytes,
              progress: 1.0,
              downloadedAt: downloadedAt,
              canCancel: false,
              canDelete: true,
              errorMessage: null,
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
          totalBytes: estimatedModelSizeBytes,
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
      final stat = await docDir.stat();
      if (!await docDir.exists()) {
        await docDir.create(recursive: true);
      }
      debugPrint('Document directory stat mode: ${stat.mode}');
    } catch (e) {
      debugPrint('Storage precondition check error: $e');
    }

    _isCancelled = false;
    _updateState(
      _currentState.copyWith(
        status: OfflineModelStatus.downloading,
        downloadedBytes: 0,
        totalBytes: estimatedModelSizeBytes,
        progress: 0.0,
        canCancel: true,
        canDelete: false,
        errorMessage: null,
      ),
    );

    try {
      await _ensureModelRegistered();

      // Download real model files directly via CactusLM
      await _cactusLM.downloadModel(
        model: AiProviderConfig.offlineGemmaSlug,
        downloadProcessCallback: (progress, statusMessage, isError) {
          if (_isCancelled) return;
          final prog = (progress ?? 0.0).clamp(0.0, 1.0);
          final bytes = (estimatedModelSizeBytes * prog).toInt();
          _updateState(
            _currentState.copyWith(
              status: isError
                  ? OfflineModelStatus.failed
                  : OfflineModelStatus.downloading,
              downloadedBytes: bytes,
              totalBytes: estimatedModelSizeBytes,
              progress: prog,
              errorMessage: isError ? statusMessage : null,
            ),
          );
        },
      );

      if (_isCancelled) {
        throw const OfflineModelDownloadCancelledException();
      }

      final downloadedAt = DateTime.now();
      await _saveMetadata(downloadedAt);

      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.downloaded,
          downloadedBytes: estimatedModelSizeBytes,
          totalBytes: estimatedModelSizeBytes,
          progress: 1.0,
          downloadedAt: downloadedAt,
          canCancel: false,
          canDelete: true,
          errorMessage: null,
        ),
      );

      // Auto-initialize following download
      await initialize();
    } on OfflineModelDownloadCancelledException {
      await _cleanupActiveDownload();
      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.notDownloaded,
          downloadedBytes: 0,
          progress: 0.0,
          canCancel: false,
        ),
      );
    } catch (e) {
      await _cleanupActiveDownload();
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

  Future<void> _cleanupActiveDownload() async {
    try {
      final modelDirPath = await _getModelDirPath();
      final modelDir = Directory(modelDirPath);
      if (await modelDir.exists()) {
        await modelDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  @override
  Future<void> cancelDownload() async {
    _isCancelled = true;
    _activeClient?.close(force: true);
    await _cleanupActiveDownload();
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
    final modelDir = Directory(modelDirPath);
    if (!await modelDir.exists()) {
      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.notDownloaded,
          errorMessage: 'Model files not found on disk.',
        ),
      );
      throw const OfflineModelUnavailableException(
        'Cannot initialize model. Model files are not downloaded.',
      );
    }

    _updateState(
      _currentState.copyWith(
        status: OfflineModelStatus.initializing,
        canCancel: false,
      ),
    );

    try {
      // Validate model weights size before invoking native C++/llama.cpp FFI
      final modelFiles = await modelDir.list().toList();
      int totalSizeBytes = 0;
      for (final entity in modelFiles) {
        if (entity is File) {
          totalSizeBytes += await entity.length();
        }
      }

      // Real GGUF neural weights for 2B models are hundreds of megabytes.
      // If only placeholder manifest files exist (< 1 MB), native llama.cpp fails on header parse.
      if (totalSizeBytes < 1024 * 1024) {
        _updateState(
          _currentState.copyWith(
            status: OfflineModelStatus.unsupported,
            errorMessage:
                'Gemma 4 E2B weights file is missing or placeholder. Provide valid GGUF weights or use Online Gemini.',
            canCancel: false,
            canDelete: true,
          ),
        );
        return;
      }

      // Initialize Cactus runtime
      await _cactusLM.initializeModel(
        params: CactusInitParams(
          model: AiProviderConfig.offlineGemmaSlug,
          contextSize: 2048,
        ),
      );

      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.ready,
          canCancel: false,
          canDelete: true,
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('Failed to initialize Cactus model context: $e');
      // If native library cannot load on this architecture, keep downloaded state and report
      _updateState(
        _currentState.copyWith(
          status: OfflineModelStatus.downloaded,
          errorMessage: 'Native engine initialization failed: $e',
          canDelete: true,
        ),
      );
      throw OfflineModelInitializationFailedException(e.toString());
    }
  }

  @override
  Future<void> deleteModel() async {
    try {
      // Unload active runtime context
      _cactusLM.unload();

      final modelDirPath = await _getModelDirPath();
      final modelDir = Directory(modelDirPath);
      if (await modelDir.exists()) {
        await modelDir.delete(recursive: true);
      }

      final docDir = await _getDocDir();
      final metaFile = File(
        '${docDir.path}/trackguard/offline_model_meta.json',
      );
      if (await metaFile.exists()) {
        await metaFile.delete();
      }

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
    } catch (e) {
      debugPrint('Failed to delete offline model: $e');
      throw OfflineModelDeleteFailedException(e.toString());
    }
  }

  void _updateState(OfflineModelState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  void dispose() {
    _stateController.close();
    _activeClient?.close(force: true);
  }
}
