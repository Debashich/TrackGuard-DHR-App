import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/constants/dhr_waypoints.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/location_source.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/primary_button.dart';
import 'report_capture_controller.dart';
import 'widgets/waypoint_picker.dart';

class ReportCaptureScreen extends ConsumerStatefulWidget {
  const ReportCaptureScreen({super.key});

  @override
  ConsumerState<ReportCaptureScreen> createState() =>
      _ReportCaptureScreenState();
}

class _ReportCaptureScreenState extends ConsumerState<ReportCaptureScreen>
    with WidgetsBindingObserver {
  ReportCaptureController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = ref.read(reportCaptureControllerProvider.notifier);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Explicitly release camera hardware using the stored reference, not ref.read
    _controller?.stopCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    super.didChangeAppLifecycleState(lifecycleState);
    if (lifecycleState == AppLifecycleState.paused) {
      _controller?.stopCamera();
    } else if (lifecycleState == AppLifecycleState.resumed) {
      _controller?.resumeCameraIfNeeded();
    }
  }

  void _showWaypointPicker(
    BuildContext context,
    ReportCaptureState captureState,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WaypointPickerSheet(
        currentKm: captureState.location?.kmMarker,
        onWaypointSelected: (DhrWaypoint wp) {
          ref
              .read(reportCaptureControllerProvider.notifier)
              .setManualWaypoint(wp, wp.km);
        },
        onKmChanged: (km) {
          ref.read(reportCaptureControllerProvider.notifier).updateKmMarker(km);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final captureState = ref.watch(reportCaptureControllerProvider);
    final controllerNotifier = ref.read(
      reportCaptureControllerProvider.notifier,
    );
    final cameraController = controllerNotifier.cameraController;

    final loc = captureState.location;
    final isGps = loc?.source == LocationSource.gps;
    final locText = loc != null
        ? '${loc.nearestStationName ?? "DHR"} • Km ${(loc.kmMarker ?? 51.0).toStringAsFixed(1)}'
        : l10n.gpsAcquiring;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _controller?.stopCamera();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await controllerNotifier.stopCamera();
              if (context.mounted) {
                context.pop();
              }
            },
          ),
          title: Text(l10n.captureTitle),
          actions: [
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (loc != null || !captureState.isCameraInitializing)
                Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 0), child: Material(color: Colors.white, borderRadius: BorderRadius.circular(28), child: InkWell(borderRadius: BorderRadius.circular(28), onTap: () => _showWaypointPicker(context, captureState), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13), child: Row(children: [Icon(isGps ? Icons.gps_fixed : Icons.edit_location_alt, color: isGps ? AppTheme.statusGreen : AppTheme.statusAmber), const SizedBox(width: 10), Expanded(child: Text(isGps ? 'Near $locText' : 'GPS weak — tap to pick station ($locText)', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700))), const Text('Change', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w700))]))))),
              // Location Warning Banner if Fallback/Manual
              if (loc != null && loc.source != LocationSource.gps) ...[
                Container(
                  color: AppTheme.primaryAmberDark.withValues(alpha: 0.85),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.manualLocationNotice,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            _showWaypointPicker(context, captureState),
                        child: Text(
                          l10n.editKm,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Main Preview Area
              Expanded(
                child: captureState.capturedFile != null
                    ? _buildPhotoReview(context, captureState)
                    : _buildCameraPreview(
                        context,
                        captureState,
                        cameraController,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoReview(
    BuildContext context,
    ReportCaptureState state,
  ) {
    if (state.capturedFile == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(reportCaptureControllerProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(state.capturedFile!, fit: BoxFit.contain),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.pin_drop,
                        color: AppTheme.primaryAmber,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${state.location?.nearestStationName ?? "DHR Alignment"} • Km ${(state.location?.kmMarker ?? 51.0).toStringAsFixed(1)} (${DhrWaypoints.getSectionName(state.location?.sectionId ?? "kurseong-ghum")})',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          color: AppTheme.surfaceDark,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56), foregroundColor: Colors.white, side: const BorderSide(color: Colors.white, width: 1.5)),
                  onPressed: () => controller.retakePhoto(),
                  child: Text(l10n.retake),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(
                  text: l10n.confirmPhoto,
                  icon: Icons.check,
                  backgroundColor: AppTheme.statusGreen,
                  foregroundColor: Colors.white,
                  onPressed: () async {
                    final success = await controller.confirmDraftAndProceed();
                    if (success && context.mounted) {
                      context.push('/gangman/report/review').then((_) {
                        if (mounted) {
                          _controller?.resumeCameraIfNeeded();
                        }
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview(
    BuildContext context,
    ReportCaptureState state,
    CameraController? cameraController,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(reportCaptureControllerProvider.notifier);

    if (state.isCameraInitializing) {
      return const LoadingView(message: 'Starting camera...');
    }

    if (!state.isCameraReady ||
        cameraController == null ||
        !cameraController.value.isInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? l10n.cameraUnavailable,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Retry Camera',
                icon: Icons.refresh,
                onPressed: () => controller.initializeCamera(),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: Text(l10n.galleryFallback),
                onPressed: () => controller.pickFromGallery(),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera Viewfinder
        CameraPreview(cameraController),

        // Bottom Controls Toolbar
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Gallery button
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.photo_library, color: Colors.white),
                  tooltip: l10n.galleryFallback,
                  onPressed: () => controller.pickFromGallery(),
                ),

                // Shutter button
                GestureDetector(
                  onTap: state.isCapturing
                      ? null
                      : () => controller.capturePhoto(),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: state.isCapturing
                          ? Colors.grey
                          : AppTheme.primaryAmber,
                    ),
                    child: state.isCapturing
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size: 36,
                            color: Colors.black,
                          ),
                  ),
                ),

                // Camera Switch button
                IconButton(
                  iconSize: 32,
                  icon: Icon(
                    Icons.flip_camera_ios,
                    color: controller.hasMultipleCameras
                        ? Colors.white
                        : Colors.white24,
                  ),
                  tooltip: l10n.switchCamera,
                  onPressed: controller.hasMultipleCameras
                      ? () => controller.switchCamera()
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


