import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/dhr_waypoints.dart';
import '../../../core/utils/image_utils.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/report_draft.dart';
import '../../reports/domain/report_repository_provider.dart';
import '../data/camera_service.dart';
import '../data/location_service.dart';

class ReportCaptureState {
  final bool isCameraInitializing;
  final bool isCameraReady;
  final bool isCapturing;
  final File? capturedFile;
  final GeoLocation? location;
  final bool isLocationAcquiring;
  final String? errorMessage;

  const ReportCaptureState({
    this.isCameraInitializing = true,
    this.isCameraReady = false,
    this.isCapturing = false,
    this.capturedFile,
    this.location,
    this.isLocationAcquiring = false,
    this.errorMessage,
  });

  ReportCaptureState copyWith({
    bool? isCameraInitializing,
    bool? isCameraReady,
    bool? isCapturing,
    File? capturedFile,
    bool clearCapturedFile = false,
    GeoLocation? location,
    bool? isLocationAcquiring,
    String? errorMessage,
  }) {
    return ReportCaptureState(
      isCameraInitializing: isCameraInitializing ?? this.isCameraInitializing,
      isCameraReady: isCameraReady ?? this.isCameraReady,
      isCapturing: isCapturing ?? this.isCapturing,
      capturedFile: clearCapturedFile
          ? null
          : (capturedFile ?? this.capturedFile),
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

    _init();
    return const ReportCaptureState();
  }

  Future<void> _init() async {
    // Acquire location in parallel
    acquireLocation();

    // Initialize camera
    final ready = await _cameraService.initialize();
    state = state.copyWith(
      isCameraInitializing: false,
      isCameraReady: ready,
      errorMessage: ready
          ? null
          : 'Camera unavailable. Please use gallery fallback.',
    );
  }

  Future<void> acquireLocation() async {
    state = state.copyWith(isLocationAcquiring: true);
    final loc = await _locationService.getCurrentLocation();
    state = state.copyWith(location: loc, isLocationAcquiring: false);
  }

  Future<void> switchCamera() async {
    await _cameraService.switchCamera();
    state = state.copyWith(isCameraReady: _cameraService.isInitialized);
  }

  Future<void> capturePhoto() async {
    state = state.copyWith(isCapturing: true);
    try {
      final file = await _cameraService.takePhoto();
      state = state.copyWith(isCapturing: false, capturedFile: file);
    } catch (e) {
      state = state.copyWith(
        isCapturing: false,
        errorMessage: 'Failed to capture photo: $e',
      );
    }
  }

  Future<void> pickFromGallery() async {
    state = state.copyWith(isCapturing: true);
    try {
      final file = await _cameraService.pickFromGallery();
      state = state.copyWith(isCapturing: false, capturedFile: file);
    } catch (e) {
      state = state.copyWith(
        isCapturing: false,
        errorMessage: 'Failed to select image from gallery: $e',
      );
    }
  }

  void retakePhoto() {
    state = state.copyWith(clearCapturedFile: true);
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
    if (state.capturedFile == null) return false;

    // Ensure we have a location, fallback if none
    final location =
        state.location ?? _locationService.createFallbackLocation();

    // Create thumbnail
    final thumbnail = await ImageUtils.generateThumbnail(state.capturedFile!);

    final draft = ReportDraft(
      photoPath: state.capturedFile!.path,
      thumbnailPath: thumbnail.path,
      location: location,
      createdAt: DateTime.now(),
    );

    // Save draft via repository abstraction
    final repo = ref.read(reportRepositoryProvider);
    await repo.saveDraft(draft);

    return true;
  }
}

final reportCaptureControllerProvider =
    NotifierProvider<ReportCaptureController, ReportCaptureState>(() {
      return ReportCaptureController();
    });
