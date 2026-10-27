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

class ReportCaptureScreen extends ConsumerWidget {
  const ReportCaptureScreen({super.key});

  void _showWaypointPicker(
    BuildContext context,
    WidgetRef ref,
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
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(l10n.captureTitle),
        actions: [
          // GPS Pill / Waypoint button
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: isGps
                  ? AppTheme.statusGreen.withValues(alpha: 0.2)
                  : AppTheme.statusAmber.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            onPressed: () => _showWaypointPicker(context, ref, captureState),
            icon: Icon(
              isGps ? Icons.gps_fixed : Icons.edit_location_alt,
              size: 16,
              color: isGps ? AppTheme.statusGreen : AppTheme.primaryAmber,
            ),
            label: Text(
              locText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isGps ? AppTheme.statusGreen : AppTheme.primaryAmber,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                          _showWaypointPicker(context, ref, captureState),
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
                  ? _buildPhotoReview(context, ref, captureState)
                  : _buildCameraPreview(
                      context,
                      ref,
                      captureState,
                      cameraController,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoReview(
    BuildContext context,
    WidgetRef ref,
    ReportCaptureState state,
  ) {
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
                    color: Colors.black.withValues(alpha: 0.75),
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
                            color: Colors.white,
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
                  onPressed: () => controller.retakePhoto(),
                  child: Text(l10n.retake),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(
                  text: l10n.confirmPhoto,
                  icon: Icons.check,
                  onPressed: () async {
                    final success = await controller.confirmDraftAndProceed();
                    if (success && context.mounted) {
                      context.push('/gangman/report/review');
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
    WidgetRef ref,
    ReportCaptureState state,
    CameraController? cameraController,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(reportCaptureControllerProvider.notifier);

    if (state.isCameraInitializing) {
      return LoadingView(message: l10n.processingImage);
    }

    if (!state.isCameraReady || cameraController == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                l10n.cameraUnavailable,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: l10n.galleryFallback,
                icon: Icons.photo_library,
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
