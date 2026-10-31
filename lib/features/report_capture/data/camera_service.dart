import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/image_utils.dart';

class CameraService {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isTransitioning = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get hasMultipleCameras => _cameras.length > 1;

  Future<bool> initialize() async {
    if (_controller != null && _controller!.value.isInitialized) {
      return true;
    }
    if (_isTransitioning) {
      return false;
    }
    _isTransitioning = true;
    try {
      return await _tryInitialize();
    } catch (e) {
      debugPrint(
        'Camera initialization initial attempt failed: $e. Retrying in 400ms...',
      );
      await Future.delayed(const Duration(milliseconds: 400));
      try {
        return await _tryInitialize();
      } catch (e2) {
        debugPrint('Camera initialization retry failed: $e2');
        return false;
      }
    } finally {
      _isTransitioning = false;
    }
  }

  Future<bool> _tryInitialize() async {
    await _stopCameraInternal();
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return false;

    // Select rear camera by default
    _selectedCameraIndex = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    if (_selectedCameraIndex < 0) _selectedCameraIndex = 0;

    final camera = _cameras[_selectedCameraIndex];
    // NOTE: Do not set ImageFormatGroup.jpeg here!
    // On Android Camera2/CameraX, setting jpeg causes stream configuration failure:
    // "Unsupported set of inputs/outputs provided".
    // Omitting it allows CameraX to configure standard Surface preview + ImageCapture.
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = controller;

    await controller.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw TimeoutException('Camera initialization timed out'),
    );

    return controller.value.isInitialized;
  }

  Future<void> pausePreview() async {
    try {
      if (_controller != null &&
          _controller!.value.isInitialized &&
          !_controller!.value.isPreviewPaused) {
        await _controller!.pausePreview();
      }
    } catch (e) {
      debugPrint('pausePreview error: $e');
    }
  }

  Future<void> resumePreview() async {
    try {
      if (_controller != null &&
          _controller!.value.isInitialized &&
          _controller!.value.isPreviewPaused) {
        await _controller!.resumePreview();
      }
    } catch (e) {
      debugPrint('resumePreview error: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2 || _isTransitioning) return;
    _isTransitioning = true;
    try {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      await _stopCameraInternal();
      final camera = _cameras[_selectedCameraIndex];
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('Camera switch initialization timed out'),
      );
    } catch (e) {
      debugPrint('switchCamera error: $e');
    } finally {
      _isTransitioning = false;
    }
  }

  Future<File?> takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    final xFile = await _controller!.takePicture();
    return ImageUtils.persistCapturedImage(File(xFile.path), prefix: 'orig');
  }

  Future<File?> pickFromGallery() async {
    final xFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (xFile == null) return null;
    return ImageUtils.persistCapturedImage(File(xFile.path), prefix: 'orig');
  }

  Future<void> _stopCameraInternal() async {
    final ctrl = _controller;
    _controller = null;
    if (ctrl != null) {
      try {
        if (ctrl.value.isInitialized) {
          await ctrl.dispose();
        }
      } catch (e) {
        debugPrint('CameraService.stopCamera dispose error: $e');
      }
    }
  }

  /// Stops camera stream and releases native hardware sensor resources.
  Future<void> stopCamera() async {
    await _stopCameraInternal();
  }

  Future<void> dispose() async {
    await _stopCameraInternal();
  }
}
