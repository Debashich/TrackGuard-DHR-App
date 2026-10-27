import 'dart:io';

import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/image_utils.dart';

class CameraService {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  final ImagePicker _imagePicker = ImagePicker();

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get hasMultipleCameras => _cameras.length > 1;

  Future<bool> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return false;

      // Select rear camera by default
      _selectedCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_selectedCameraIndex < 0) _selectedCameraIndex = 0;

      await _initController(_cameras[_selectedCameraIndex]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _initController(CameraDescription camera) async {
    await _controller?.dispose();
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;
    await controller.initialize();
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initController(_cameras[_selectedCameraIndex]);
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

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
