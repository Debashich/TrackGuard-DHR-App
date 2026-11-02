import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:litertlm/litertlm.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/image_utils.dart';
import '../../../shared/models/ai_analysis_result.dart';
import '../../../shared/models/ai_provider.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/geo_location.dart';
import '../domain/ai_provider_config.dart';
import '../domain/offline_model_manager.dart';
import '../domain/offline_model_state.dart';
import 'ai_prompt_builder.dart';
import 'ai_result_validator.dart';
import 'huggingface_model_downloader.dart';
import 'litert_offline_model_manager.dart';
import 'offline_model_artifact_validator.dart';

enum LitertGemmaState {
  notInstalled,
  downloading,
  loading,
  ready,
  running,
  failed,
  unavailable,
}

class LitertGemmaProvider {
  final AiPromptBuilder _promptBuilder;
  final AiResultValidator _validator;
  final OfflineModelManager? modelManager;
  final String modelName;
  final String modelSlug;

  Engine? _engine;
  LitertGemmaState _state = LitertGemmaState.notInstalled;
  String? _lastError;
  double _downloadProgress = 0.0;
  StreamSubscription<OfflineModelState>? _managerSubscription;

  final _stateController = StreamController<LitertGemmaState>.broadcast();

  LitertGemmaProvider({
    AiPromptBuilder? promptBuilder,
    AiResultValidator? validator,
    Engine? engine,
    this.modelManager,
    this.modelName = AiProviderConfig.offlineGemmaModelName,
    this.modelSlug = AiProviderConfig.offlineGemmaSlug,
  })  : _promptBuilder = promptBuilder ?? AiPromptBuilder(),
        _validator = validator ?? AiResultValidator(),
        // ignore: prefer_initializing_formals
        _engine = engine {
    _initAndSyncManager();
  }

  void _initAndSyncManager() {
    final manager = modelManager;
    if (manager != null) {
      if (manager is LitertOfflineModelManager && manager.isReady) {
        _state = LitertGemmaState.ready;
        _engine ??= manager.engine;
      }
      _managerSubscription = manager.watchState().listen((modelState) {
        if (modelState.isReady) {
          if (manager is LitertOfflineModelManager) {
            _engine = manager.engine;
          }
          _setState(LitertGemmaState.ready);
        } else if (modelState.isDownloading) {
          _setState(LitertGemmaState.downloading);
        } else if (modelState.status == OfflineModelStatus.failed) {
          _setState(LitertGemmaState.failed, modelState.errorMessage);
        } else if (modelState.status == OfflineModelStatus.notDownloaded) {
          _setState(LitertGemmaState.notInstalled);
        }
      });
    }
  }

  LitertGemmaState get state => _state;
  bool get isReady {
    if (_state == LitertGemmaState.ready) return true;
    final manager = modelManager;
    if (manager is LitertOfflineModelManager && manager.isReady) {
      _state = LitertGemmaState.ready;
      _engine ??= manager.engine;
      return true;
    }
    return false;
  }

  String? get lastError => _lastError;
  double get downloadProgress => _downloadProgress;
  Stream<LitertGemmaState> get stateStream => _stateController.stream;

  void _setState(LitertGemmaState newState, [String? error]) {
    _state = newState;
    _lastError = error;
    _stateController.add(newState);
  }

  Future<Directory> _getModelDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'models', modelSlug));
  }

  Future<bool> isModelInstalled() async {
    final manager = modelManager;
    if (manager != null) {
      final modelState = await manager.getState();
      if (modelState.isReady) {
        if (manager is LitertOfflineModelManager) {
          _engine ??= manager.engine;
        }
        _setState(LitertGemmaState.ready);
        return true;
      } else if (modelState.status == OfflineModelStatus.downloaded) {
        try {
          await manager.initialize();
          if (manager is LitertOfflineModelManager) {
            _engine = manager.engine;
          }
          _setState(LitertGemmaState.ready);
          return true;
        } catch (e) {
          debugPrint('Failed to auto-initialize downloaded model: $e');
        }
      } else if (modelState.isDownloading) {
        _setState(LitertGemmaState.downloading);
      } else {
        _setState(LitertGemmaState.notInstalled);
      }
      return false;
    }

    try {
      final dir = await _getModelDir();
      final validation =
          await const OfflineModelArtifactValidator().validateArtifact(
        directoryPath: dir.path,
        expectedFilename: AiProviderConfig.offlineGemmaFile,
      );

      if (validation.isValid) {
        if (_state == LitertGemmaState.notInstalled) {
          _setState(LitertGemmaState.ready);
        }
        return true;
      }

      _setState(LitertGemmaState.notInstalled);
      return false;
    } catch (e) {
      debugPrint('LiteRT-LM model check exception: $e');
      _setState(LitertGemmaState.unavailable, e.toString());
      return false;
    }
  }

  Future<void> initialize() async {
    _setState(LitertGemmaState.loading);
    try {
      final manager = modelManager;
      if (manager != null) {
        await manager.initialize();
        if (manager is LitertOfflineModelManager) {
          _engine = manager.engine;
        }
        _setState(LitertGemmaState.ready);
        return;
      }

      final installed = await isModelInstalled();
      if (!installed) {
        _setState(
          LitertGemmaState.notInstalled,
          'Gemma 4 E2B weights not found in local model storage.',
        );
        return;
      }

      final dir = await _getModelDir();
      final modelPath = p.join(dir.path, AiProviderConfig.offlineGemmaFile);

      await _engine?.dispose();

      // Cap Gemma 4 visual token budget to 280 tokens (matches model signatures: vision_70, vision_140, vision_280)
      try {
        ExperimentalFlags.visualTokenBudget = 280;
      } catch (flagError) {
        debugPrint('Failed to set visualTokenBudget: $flagError');
      }

      // Use CPU backend for both text decoder and vision encoder on devices like Mali-G57
      // to avoid native WebGPU driver crashes (abort/SIGSEGV) during vision patch embedding.
      final engine = Engine(
        engineConfig: EngineConfig(
          modelPath: modelPath,
          backend: const Backend.cpu(),
          visionBackend: const Backend.cpu(),
          maxNumTokens: 4096,
          maxNumImages: 1,
        ),
      );
      await engine.initialize();

      _engine = engine;
      _setState(LitertGemmaState.ready);
    } catch (e) {
      debugPrint('LiteRT-LM Gemma initialization failed: $e');
      _setState(
        LitertGemmaState.failed,
        'LiteRT-LM initialization failed: ${e.toString()}',
      );
    }
  }

  Future<void> downloadModel({
    void Function(double progress, String status)? onProgress,
  }) async {
    if (modelManager != null) {
      await modelManager!.download();
      return;
    }

    _setState(LitertGemmaState.downloading);
    try {
      final dir = await _getModelDir();
      final downloader = HuggingFaceModelDownloader();
      await downloader.download(
        repository: AiProviderConfig.offlineGemmaRepository,
        file: AiProviderConfig.offlineGemmaFile,
        branch: AiProviderConfig.offlineGemmaBranch,
        destinationDirectoryPath: dir.path,
        expectedSha256: AiProviderConfig.offlineGemmaSha256.isNotEmpty
            ? AiProviderConfig.offlineGemmaSha256
            : null,
        onProgress: (downloadedBytes, totalBytes, progress) {
          _downloadProgress = progress;
          onProgress?.call(
            _downloadProgress,
            'Downloading ${(progress * 100).toInt()}%',
          );
        },
      );

      await initialize();
    } catch (e) {
      debugPrint('Hugging Face model download failed: $e');
      _setState(LitertGemmaState.failed, 'Download failed: ${e.toString()}');
      throw OfflineModelInitializationFailedException(
        'Failed to download Gemma 4 E2B model: $e',
      );
    }
  }

  Future<AiAnalysisResult> analyze({
    required File image,
    required GeoLocation location,
    required AppLanguage language,
  }) async {
    if (!await image.exists()) {
      throw const AiValidationFailedException(
        'Captured image file does not exist for offline analysis.',
      );
    }

    final manager = modelManager;
    if (manager != null) {
      final modelState = await manager.getState();
      if (!modelState.isReady) {
        throw const OfflineModelUnavailableException(
          'Offline Gemma 4 E2B model is not initialized or ready.',
        );
      }
      if (_engine == null && manager is LitertOfflineModelManager) {
        _engine = manager.engine;
      }
    }

    if (_engine == null && manager != null) {
      await manager.initialize();
      if (manager is LitertOfflineModelManager) {
        _engine = manager.engine;
      }
    }

    if (_engine == null) {
      throw const OfflineModelUnavailableException(
        'Offline Gemma 4 E2B model is not initialized or ready.',
      );
    }

    _setState(LitertGemmaState.running);

    // 1. Build structured prompt
    final promptText = _promptBuilder.buildPrompt(
      language: language,
      location: location,
    );

    Conversation? conversation;
    File? visionImageFile;
    try {
      // Ensure visual token budget is set to 280 (max signature in gemma-4-E2B-it.litertlm)
      try {
        ExperimentalFlags.visualTokenBudget = 280;
      } catch (_) {}

      // 2. Prepare optimized vision image (scaled down to avoid Mali GPU/CPU VRAM OOM)
      visionImageFile = await ImageUtils.prepareOptimizedVisionImage(image);

      // 3. Create LiteRT-LM conversation
      conversation = await _engine!.createConversation();

      // 4. Multimodal Message with image first, then text prompt (required for proper autoregressive sequencing in Gemma 4)
      final message = Message.userContents(
        Contents([
          Content.imageFile(visionImageFile.path),
          Content.text(promptText),
        ]),
      );

      // 5. Stream message asynchronously to keep the UI thread responsive (prevents Android ANR Signal 3)
      final responseBuffer = StringBuffer();
      String accumulated = '';
      await for (final chunk in conversation.sendMessageStream(message)) {
        final text = chunk.text;
        if (text.isEmpty) continue;
        if (text.startsWith(accumulated) && text.length > accumulated.length) {
          accumulated = text;
        } else {
          responseBuffer.write(text);
          accumulated = responseBuffer.toString();
        }
      }
      final rawResponse = accumulated;

      if (rawResponse.trim().isEmpty) {
        throw const OfflineModelInferenceFailedException(
          'Empty response returned from LiteRT-LM model.',
        );
      }

      // 6. Validate and sanitize response
      final result = _validator.validateString(
        rawResponse,
        provider: AiProvider.offlineGemma,
        requestedLanguage: language,
        modelName: modelName,
      );

      _setState(LitertGemmaState.ready);
      return result;
    } on AppException {
      _setState(LitertGemmaState.ready);
      rethrow;
    } catch (e) {
      _setState(LitertGemmaState.failed, e.toString());
      throw OfflineModelInferenceFailedException(
        'Offline inference failed: $e',
      );
    } finally {
      try {
        await conversation?.dispose();
      } catch (_) {}
      if (visionImageFile != null && visionImageFile.path != image.path) {
        try {
          if (await visionImageFile.exists()) {
            await visionImageFile.delete();
          }
        } catch (_) {}
      }
    }
  }

  void dispose() {
    _managerSubscription?.cancel();
    _stateController.close();
    _engine?.dispose();
  }
}

