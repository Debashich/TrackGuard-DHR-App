import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_media_storage.dart';
import '../../../core/constants/dhr_waypoints.dart';
import '../../../core/utils/image_utils.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/report_draft.dart';
import '../../../shared/models/report_photo.dart';
import '../../reports/domain/report_repository_provider.dart';
import '../data/camera_service.dart';
import '../data/location_service.dart';

class ReportCaptureState {
  final bool isCameraInitializing;
  final bool isCameraReady;
  final bool isCapturing;
  final List<File> capturedFiles;
  final bool isTakingAdditionalPhoto;
  final GeoLocation? location;
  final bool isLocationAcquiring;
  final String? errorMessage;

  const ReportCaptureState({
    this.isCameraInitializing = true,
    this.isCameraReady = false,
    this.isCapturing = false,
    this.capturedFiles = const [],
    this.isTakingAdditionalPhoto = false,
    this.location,
    this.isLocationAcquiring = false,
    this.errorMessage,
  });

  // Compatibility with existing single-photo consumers.
  File? get capturedFile => capturedFiles.isEmpty ? null : capturedFiles.first;

  ReportCaptureState copyWith({
    bool? isCameraInitializing,
    bool? isCameraReady,
    bool? isCapturing,
    List<File>? capturedFiles,
    bool clearCapturedFiles = false,
    bool? isTakingAdditionalPhoto,
    GeoLocation? location,
    bool? isLocationAcquiring,
    String? errorMessage,
  }) {
    return ReportCaptureState(
      isCameraInitializing: isCameraInitializing ?? this.isCameraInitializing,
      isCameraReady: isCameraReady ?? this.isCameraReady,
      isCapturing: isCapturing ?? this.isCapturing,
      capturedFiles: clearCapturedFiles
          ? const []
          : (capturedFiles ?? this.capturedFiles),
      isTakingAdditionalPhoto:
          isTakingAdditionalPhoto ?? this.isTakingAdditionalPhoto,
      location: location ?? this.location,
      isLocationAcquiring: isLocationAcquiring ?? this.isLocationAcquiring,
      errorMessage: errorMessage,
    );
  }
}

class ReportCaptureController extends Notifier<ReportCaptureState> {
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();

  CameraController? get cameraController => _cameraService.controller;
  bool get hasMultipleCameras => _cameraService.hasMultipleCameras;

  @override
  ReportCaptureState build() {
    ref.onDispose(() {
      _cameraService.dispose();
    });

    Future.microtask(_init);

    return const ReportCaptureState();
  }

  Future<void> _init() async {
    await initializeCamera();

    if (!ref.mounted) return;

    await acquireLocation();
  }

  Future<void> initializeCamera() async {
    state = state.copyWith(isCameraInitializing: true, errorMessage: null);

    final ready = await _cameraService.initialize();

    if (!ref.mounted) return;

    state = state.copyWith(
      isCameraInitializing: false,
      isCameraReady: ready,
      errorMessage: ready ? null : 'Camera unavailable. Please check permissions or use gallery fallback.',
    );
  }

  Future<void> acquireLocation() async {
    state = state.copyWith(isLocationAcquiring: true);

    final loc = await _locationService.getCurrentLocation();

    if (!ref.mounted) return;

    state = state.copyWith(location: loc, isLocationAcquiring: false);
  }

  Future<void> switchCamera() async {
    await _cameraService.switchCamera();

    state = state.copyWith(isCameraReady: _cameraService.isInitialized);
  }

  Future<void> capturePhoto() async {
    if (state.isCapturing) return;

    state = state.copyWith(isCapturing: true, errorMessage: null);

    try {
      final file = await _cameraService.takePhoto();

      if (file != null) {
        final files = [...state.capturedFiles, file];

        await _cameraService.pausePreview();

        state = state.copyWith(
          capturedFiles: files,
          isTakingAdditionalPhoto: false,
        );
      }

      state = state.copyWith(isCapturing: false);
    } catch (e) {
      state = state.copyWith(
        isCapturing: false,
        errorMessage: 'Failed to capture photo: $e',
      );
    }
  }

  Future<void> pickFromGallery() async {
    if (state.isCapturing) return;

    state = state.copyWith(isCapturing: true, errorMessage: null);

    try {
      final files = await _cameraService.pickFromGallery();

      if (files.isNotEmpty) {
        await _cameraService.pausePreview();

        state = state.copyWith(
          capturedFiles: [...state.capturedFiles, ...files],
          isTakingAdditionalPhoto: false,
        );
      }

      state = state.copyWith(isCapturing: false);
    } catch (e) {
      state = state.copyWith(
        isCapturing: false,
        errorMessage: 'Failed to select images from gallery: $e',
      );
    }
  }

  Future<void> startAdditionalCapture() async {
    state = state.copyWith(isTakingAdditionalPhoto: true, errorMessage: null);

    if (_cameraService.isInitialized) {
      await _cameraService.resumePreview();

      state = state.copyWith(isCameraReady: true, isCameraInitializing: false);
    } else {
      await initializeCamera();
    }
  }

  Future<void> removePhoto(int index) async {
    if (index < 0 || index >= state.capturedFiles.length) return;

    final files = [...state.capturedFiles]..removeAt(index);

    state = state.copyWith(
      capturedFiles: files,
      isTakingAdditionalPhoto: false,
    );

    if (files.isEmpty) {
      await resumeCameraIfNeeded();
    }
  }

  Future<void> retakePhoto() async {
    state = state.copyWith(
      clearCapturedFiles: true,
      isTakingAdditionalPhoto: false,
      errorMessage: null,
    );

    await resumeCameraIfNeeded();
  }

  Future<void> stopCamera() async {
    await _cameraService.stopCamera();

    state = state.copyWith(isCameraReady: false);
  }

  Future<void> resumeCameraIfNeeded() async {
    if (state.capturedFiles.isEmpty || state.isTakingAdditionalPhoto) {
      if (_cameraService.isInitialized) {
        await _cameraService.resumePreview();

        state = state.copyWith(
          isCameraReady: true,
          isCameraInitializing: false,
        );
      } else {
        await initializeCamera();
      }
    }
  }

  void setManualWaypoint(DhrWaypoint wp, double? customKm) {
    final manualLoc = _locationService.createManualLocation(
      waypoint: wp,
      customKm: customKm,
    );

    state = state.copyWith(location: manualLoc);
  }

  void updateKmMarker(double km) {
    if (state.location != null) {
      final updated = state.location!.copyWith(
        kmMarker: km,
        sectionId: DhrWaypoints.estimateSection(km),
      );

      state = state.copyWith(location: updated);
    }
  }

  Future<bool> confirmDraftAndProceed() async {
    if (state.capturedFiles.isEmpty) return false;

    await _cameraService.stopCamera();

    state = state.copyWith(isCameraReady: false);

    try {
      final location =
          state.location ?? _locationService.createFallbackLocation();

      final photos = <ReportPhoto>[];

      for (final file in state.capturedFiles) {
        final thumbnail = await ImageUtils.generateThumbnail(file);

        photos.add(
          ReportPhoto(originalPath: file.path, thumbnailPath: thumbnail.path),
        );
      }

      final draft = ReportDraft(
        photoPath: photos.first.originalPath,
        thumbnailPath: photos.first.thumbnailPath,
        additionalPhotos: photos.skip(1).toList(),
        location: location,
        createdAt: DateTime.now(),
      );

      final persistentDraft = await LocalMediaStorage().persistDraftMedia(
        draft,
      );

      final repo = ref.read(reportRepositoryProvider);
      await repo.saveDraft(persistentDraft);

      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save inspection draft: $e',
      );

      return false;
    }
  }
}

final reportCaptureControllerProvider =
    NotifierProvider<ReportCaptureController, ReportCaptureState>(
      ReportCaptureController.new,
    );
