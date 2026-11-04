import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/image_utils.dart';

class CameraService {
  static List<CameraDescription>? _cachedCameras;

  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;

  final ImagePicker _imagePicker = ImagePicker();

  bool _isTransitioning = false;
  Future<bool>? _initializationFuture;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get hasMultipleCameras => _cameras.length > 1;

  /// Initializes the camera once, sharing an in-progress initialization
  /// between callers instead of starting competing native operations.
  Future<bool> initialize() {
    if (isInitialized) {
      return Future.value(true);
    }

    final existingFuture = _initializationFuture;
    if (existingFuture != null) {
      return existingFuture;
    }

    final future = _initializeInternal();
    _initializationFuture = future;

    return future.whenComplete(() {
      if (identical(_initializationFuture, future)) {
        _initializationFuture = null;
      }
    });
  }

  Future<bool> _initializeInternal() async {
    if (_isTransitioning) return false;

    _isTransitioning = true;

    try {
      return await _tryInitialize();
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      return false;
    } finally {
      _isTransitioning = false;
    }
  }

  Future<bool> _tryInitialize() async {
    // Clean up any previous controller before creating another.
    if (_controller != null) {
      await _stopCameraInternal();
    }

    // Discover cameras only once per application process.
    _cachedCameras ??= await availableCameras();
    _cameras = _cachedCameras!;

    if (_cameras.isEmpty) {
      debugPrint('No cameras available on this device.');
      return false;
    }

    // Prefer the rear camera.
    _selectedCameraIndex = _cameras.indexWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    if (_selectedCameraIndex < 0) {
      _selectedCameraIndex = 0;
    }

    final camera = _cameras[_selectedCameraIndex];

    // Use a clear preview suitable for inspecting track hazards. Low resolution
    // made the live view visibly soft on devices with large displays.
    // Do not force ImageFormatGroup.jpeg on Android.
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller = controller;

    try {
      // Allow Android enough time to initialize the native camera.
      // Avoid the old 3-second timeout followed by an immediate retry.
      await controller.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Camera initialization timed out');
        },
      );

      return controller.value.isInitialized;
    } catch (e) {
      debugPrint('Camera controller initialization failed: $e');

      if (identical(_controller, controller)) {
        _controller = null;
      }

      try {
        await controller.dispose();
      } catch (disposeError) {
        debugPrint('Camera cleanup failed: $disposeError');
      }

      return false;
    }
  }

  Future<void> pausePreview() async {
    try {
      final controller = _controller;

      if (controller != null &&
          controller.value.isInitialized &&
          !controller.value.isPreviewPaused) {
        await controller.pausePreview();
      }
    } catch (e) {
      debugPrint('pausePreview error: $e');
    }
  }

  Future<void> resumePreview() async {
    try {
      final controller = _controller;

      if (controller != null &&
          controller.value.isInitialized &&
          controller.value.isPreviewPaused) {
        await controller.resumePreview();
      }
    } catch (e) {
      debugPrint('resumePreview error: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2 || _isTransitioning) return;

    _isTransitioning = true;

    try {
      final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;

      await _stopCameraInternal();

      final controller = CameraController(
        _cameras[nextIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      _controller = controller;

      try {
        await controller.initialize().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Camera switch initialization timed out');
          },
        );

        if (controller.value.isInitialized) {
          _selectedCameraIndex = nextIndex;
        }
      } catch (e) {
        debugPrint('Camera switch initialization failed: $e');

        if (identical(_controller, controller)) {
          _controller = null;
        }

        await controller.dispose();
      }
    } catch (e) {
      debugPrint('switchCamera error: $e');
    } finally {
      _isTransitioning = false;
    }
  }

  Future<File?> takePhoto() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return null;
    }

    final xFile = await controller.takePicture();

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
    final controller = _controller;
    _controller = null;

    if (controller != null) {
      try {
        await controller.dispose();
      } catch (e) {
        debugPrint('Camera disposal error: $e');
      }
    }
  }

  /// Releases native camera hardware.
  Future<void> stopCamera() async {
    if (_isTransitioning) return;
    await _stopCameraInternal();
  }

  Future<void> dispose() async {
    await _stopCameraInternal();
  }
}
