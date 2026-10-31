import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:lib_llama_cpp/lib_llama_cpp.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/app_exception.dart';
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
import 'llama_offline_model_manager.dart';
import 'offline_model_artifact_validator.dart';

enum LlamaGemmaState {
  notInstalled,
  downloading,
  loading,
  ready,
  running,
  failed,
  unavailable,
}

class LlamaGemmaProvider {
  final AiPromptBuilder _promptBuilder;
  final AiResultValidator _validator;
  final OfflineModelManager? modelManager;
  final String modelName;
  final String modelSlug;

  LlamaOpenAIClient? _client;
  LlamaGemmaState _state = LlamaGemmaState.notInstalled;
  String? _lastError;
  double _downloadProgress = 0.0;
  StreamSubscription<OfflineModelState>? _managerSubscription;

  final _stateController = StreamController<LlamaGemmaState>.broadcast();

  LlamaGemmaProvider({
    AiPromptBuilder? promptBuilder,
    AiResultValidator? validator,
    LlamaOpenAIClient? client,
    this.modelManager,
    this.modelName = AiProviderConfig.offlineGemmaModelName,
    this.modelSlug = AiProviderConfig.offlineGemmaSlug,
  })  : _promptBuilder = promptBuilder ?? AiPromptBuilder(),
        _validator = validator ?? AiResultValidator(),
        // ignore: prefer_initializing_formals
        _client = client {
    _initAndSyncManager();
  }

  void _initAndSyncManager() {
    final manager = modelManager;
    if (manager != null) {
      if (manager is LlamaOfflineModelManager && manager.isReady) {
        _state = LlamaGemmaState.ready;
        _client ??= manager.client;
      }
      _managerSubscription = manager.watchState().listen((modelState) {
        if (modelState.isReady) {
          if (manager is LlamaOfflineModelManager) {
            _client = manager.client;
          }
          _setState(LlamaGemmaState.ready);
        } else if (modelState.isDownloading) {
          _setState(LlamaGemmaState.downloading);
        } else if (modelState.status == OfflineModelStatus.failed) {
          _setState(LlamaGemmaState.failed, modelState.errorMessage);
        } else if (modelState.status == OfflineModelStatus.notDownloaded) {
          _setState(LlamaGemmaState.notInstalled);
        }
      });
    }
  }

  LlamaGemmaState get state => _state;
  bool get isReady {
    if (_state == LlamaGemmaState.ready) return true;
    final manager = modelManager;
    if (manager is LlamaOfflineModelManager && manager.isReady) {
      _state = LlamaGemmaState.ready;
      _client ??= manager.client;
      return true;
    }
    return false;
  }
  String? get lastError => _lastError;
  double get downloadProgress => _downloadProgress;
  Stream<LlamaGemmaState> get stateStream => _stateController.stream;

  void _setState(LlamaGemmaState newState, [String? error]) {
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
        if (manager is LlamaOfflineModelManager) {
          _client ??= manager.client;
        }
        _setState(LlamaGemmaState.ready);
        return true;
      } else if (modelState.status == OfflineModelStatus.downloaded) {
        try {
          await manager.initialize();
          if (manager is LlamaOfflineModelManager) {
            _client = manager.client;
          }
          _setState(LlamaGemmaState.ready);
          return true;
        } catch (e) {
          debugPrint('Failed to auto-initialize downloaded model: $e');
        }
      } else if (modelState.isDownloading) {
        _setState(LlamaGemmaState.downloading);
      } else {
        _setState(LlamaGemmaState.notInstalled);
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
        if (_state == LlamaGemmaState.notInstalled) {
          _setState(LlamaGemmaState.ready);
        }
        return true;
      }

      _setState(LlamaGemmaState.notInstalled);
      return false;
    } catch (e) {
      debugPrint('Llama model check exception: $e');
      _setState(LlamaGemmaState.unavailable, e.toString());
      return false;
    }
  }

  Future<void> initialize() async {
    _setState(LlamaGemmaState.loading);
    try {
      final manager = modelManager;
      if (manager != null) {
        await manager.initialize();
        if (manager is LlamaOfflineModelManager) {
          _client = manager.client;
        }
        _setState(LlamaGemmaState.ready);
        return;
      }

      final installed = await isModelInstalled();
      if (!installed) {
        _setState(
          LlamaGemmaState.notInstalled,
          'Gemma 4 E2B weights not found in local model storage.',
        );
        return;
      }

      final dir = await _getModelDir();
      final modelPath = p.join(dir.path, AiProviderConfig.offlineGemmaFile);
      final projectorPath =
          p.join(dir.path, AiProviderConfig.offlineGemmaProjectorFile);
      final hasProjector = await File(projectorPath).exists();

      await _client?.close();
      _client = LlamaOpenAIClient(
        models: {
          modelSlug: LlamaModelConfig(
            modelPath: modelPath,
            mmprojPath: hasProjector ? projectorPath : null,
            contextSize: 2048,
          ),
        },
      );

      _setState(LlamaGemmaState.ready);
    } catch (e) {
      debugPrint('Llama Gemma initialization failed: $e');
      _setState(
        LlamaGemmaState.failed,
        'Llama initialization failed: ${e.toString()}',
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

    _setState(LlamaGemmaState.downloading);
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

      if (AiProviderConfig.offlineGemmaProjectorFile.isNotEmpty) {
        try {
          await downloader.download(
            repository: AiProviderConfig.offlineGemmaRepository,
            file: AiProviderConfig.offlineGemmaProjectorFile,
            branch: AiProviderConfig.offlineGemmaBranch,
            destinationDirectoryPath: dir.path,
            minSizeBytes: 5 * 1024 * 1024,
          );
        } catch (e) {
          debugPrint('Projector download note in LlamaGemmaProvider: $e');
        }
      }

      await initialize();
    } catch (e) {
      debugPrint('Hugging Face model download failed: $e');
      _setState(LlamaGemmaState.failed, 'Download failed: ${e.toString()}');
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
      if (_client == null && manager is LlamaOfflineModelManager) {
        _client = manager.client;
      }
    }

    if (_client == null && manager != null) {
      await manager.initialize();
      if (manager is LlamaOfflineModelManager) {
        _client = manager.client;
      }
    }

    if (_client == null) {
      throw const OfflineModelUnavailableException(
        'Offline Gemma 4 E2B model is not initialized or ready.',
      );
    }

    _setState(LlamaGemmaState.running);

    try {
      // 1. Build structured prompt
      final promptText = _promptBuilder.buildPrompt(
        language: language,
        location: location,
      );

      // 2. Multimodal ChatMessage
      final dir = await _getModelDir();
      final projectorPath =
          p.join(dir.path, AiProviderConfig.offlineGemmaProjectorFile);
      final hasProjector = await File(projectorPath).exists();

      final List<LlamaChatMessage> messages;
      if (hasProjector) {
        messages = [
          LlamaChatMessage(
            role: 'user',
            content: [
              LlamaTextPart(promptText),
              LlamaImageFilePart(path: image.path, mimeType: 'image/jpeg'),
            ],
          ),
        ];
      } else {
        messages = [
          LlamaChatMessage(
            role: 'user',
            content: promptText,
          ),
        ];
      }

      // 3. Execute completion without timeout for low-end devices
      final completion = await _client!.chat.completions.create(
        model: modelSlug,
        messages: messages,
        maxTokens: 512,
        temperature: 0.2,
      );

      if (completion.choices.isEmpty) {
        throw const OfflineModelInferenceFailedException(
          'No output choices returned from llama.cpp.',
        );
      }

      final rawResponse = completion.choices.first.message.content.toString();

      // 4. Validate and sanitize response
      final result = _validator.validateString(
        rawResponse,
        provider: AiProvider.offlineGemma,
        requestedLanguage: language,
        modelName: modelName,
      );

      _setState(LlamaGemmaState.ready);
      return result;
    } on AppException {
      _setState(LlamaGemmaState.ready);
      rethrow;
    } catch (e) {
      _setState(LlamaGemmaState.failed, e.toString());
      throw OfflineModelInferenceFailedException(
        'Offline inference failed: $e',
      );
    }
  }

  void dispose() {
    _managerSubscription?.cancel();
    _stateController.close();
    _client?.close();
  }
}

