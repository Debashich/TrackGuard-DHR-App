import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/app_exception.dart';
import '../../../shared/models/ai_analysis_result.dart';
import '../../../shared/models/ai_provider.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/geo_location.dart';
import '../domain/ai_provider_config.dart';
import 'ai_prompt_builder.dart';
import 'ai_result_validator.dart';

enum CactusGemmaState {
  notInstalled,
  downloading,
  loading,
  ready,
  running,
  failed,
  unavailable,
}

class CactusGemmaProvider {
  final AiPromptBuilder _promptBuilder;
  final AiResultValidator _validator;
  final String modelName;
  final String modelSlug;

  CactusLM? _lm;
  CactusGemmaState _state = CactusGemmaState.notInstalled;
  String? _lastError;
  double _downloadProgress = 0.0;

  final _stateController = StreamController<CactusGemmaState>.broadcast();

  CactusGemmaProvider({
    AiPromptBuilder? promptBuilder,
    AiResultValidator? validator,
    this.modelName = AiProviderConfig.offlineGemmaModelName,
    this.modelSlug = AiProviderConfig.offlineGemmaSlug,
  }) : _promptBuilder = promptBuilder ?? AiPromptBuilder(),
       _validator = validator ?? AiResultValidator() {
    _initCactusConfig();
  }

  CactusGemmaState get state => _state;
  bool get isReady => _state == CactusGemmaState.ready;
  String? get lastError => _lastError;
  double get downloadProgress => _downloadProgress;
  Stream<CactusGemmaState> get stateStream => _stateController.stream;

  void _setState(CactusGemmaState newState, [String? error]) {
    _state = newState;
    _lastError = error;
    _stateController.add(newState);
  }

  void _initCactusConfig() {
    try {
      CactusConfig.isTelemetryEnabled = false;
    } catch (_) {
      // Ignore if native telemetry init fails on unsupported host platforms
    }
  }

  Future<Directory> _getModelDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'models', modelSlug));
  }

  Future<bool> isModelInstalled() async {
    try {
      final dir = await _getModelDir();
      final exists = await dir.exists();
      if (!exists) {
        if (_state != CactusGemmaState.downloading &&
            _state != CactusGemmaState.loading) {
          _setState(CactusGemmaState.notInstalled);
        }
        return false;
      }

      final files = dir.listSync();
      final hasWeights = files.any(
        (f) =>
            f.path.endsWith('.bin') ||
            f.path.endsWith('.gguf') ||
            f.path.endsWith('.task'),
      );

      if (hasWeights) {
        if (_state == CactusGemmaState.notInstalled) {
          _setState(CactusGemmaState.ready);
        }
        return true;
      }

      _setState(CactusGemmaState.notInstalled);
      return false;
    } catch (e) {
      debugPrint('Cactus model check exception: $e');
      _setState(CactusGemmaState.unavailable, e.toString());
      return false;
    }
  }

  Future<void> initialize() async {
    _setState(CactusGemmaState.loading);
    try {
      _lm ??= CactusLM();

      final installed = await isModelInstalled();
      if (!installed) {
        _setState(
          CactusGemmaState.notInstalled,
          'Gemma 4 E2B weights not found in local model storage.',
        );
        return;
      }

      // Initialize Cactus context with model slug
      await _lm!.initializeModel(
        params: CactusInitParams(model: modelSlug, contextSize: 2048),
      );

      _setState(CactusGemmaState.ready);
    } catch (e) {
      debugPrint('Cactus Gemma initialization failed: $e');
      _setState(
        CactusGemmaState.failed,
        'Cactus initialization failed: ${e.toString()}',
      );
    }
  }

  Future<void> downloadModel({
    void Function(double progress, String status)? onProgress,
  }) async {
    _setState(CactusGemmaState.downloading);
    try {
      _lm ??= CactusLM();
      await _lm!.downloadModel(
        model: modelSlug,
        downloadProcessCallback: (progress, status, isError) {
          _downloadProgress = progress ?? 0.0;
          onProgress?.call(_downloadProgress, status);
          if (isError) {
            _setState(CactusGemmaState.failed, status);
          }
        },
      );

      await initialize();
    } catch (e) {
      debugPrint('Cactus model download failed: $e');
      _setState(CactusGemmaState.failed, 'Download failed: ${e.toString()}');
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

    if (_state != CactusGemmaState.ready || _lm == null) {
      throw const OfflineModelUnavailableException(
        'Offline Gemma 4 E2B model is not initialized or ready.',
      );
    }

    _setState(CactusGemmaState.running);

    try {
      // 1. Prepare base64 image data
      final imageBytes = await image.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // 2. Build structured prompt
      final promptText = _promptBuilder.buildPrompt(
        language: language,
        location: location,
      );

      // 3. Construct multimodal ChatMessage
      final chatMessage = ChatMessage(
        role: 'user',
        content: promptText,
        images: [base64Image],
      );

      // 4. Execute completion with timeout
      final completion = await _lm!
          .generateCompletion(
            messages: [chatMessage],
            params: CactusCompletionParams(
              model: modelSlug,
              temperature: 0.2,
              maxTokens: 512,
              completionMode: CompletionMode.local,
            ),
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () => throw const OfflineModelInferenceFailedException(
              'Offline Gemma model inference timed out (45s).',
            ),
          );

      if (!completion.success) {
        throw OfflineModelInferenceFailedException(
          'Cactus Gemma failed: ${completion.response}',
        );
      }

      // 5. Validate and sanitize response
      final result = _validator.validateString(
        completion.response,
        provider: AiProvider.offlineGemma,
        requestedLanguage: language,
        modelName: modelName,
      );

      _setState(CactusGemmaState.ready);
      return result;
    } on AppException {
      _setState(CactusGemmaState.ready);
      rethrow;
    } catch (e) {
      _setState(CactusGemmaState.failed, e.toString());
      throw OfflineModelInferenceFailedException(
        'Offline inference failed: $e',
      );
    }
  }

  void dispose() {
    _stateController.close();
  }
}
