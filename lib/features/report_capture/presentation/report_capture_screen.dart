import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/dhr_waypoints.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/location_source.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/trackguard_dialog.dart';
import 'report_capture_controller.dart';
import 'widgets/waypoint_picker.dart';

enum _CaptureExitAction { saveDraft, discard }

class ReportCaptureScreen extends ConsumerStatefulWidget {
  const ReportCaptureScreen({super.key});

  @override
  ConsumerState<ReportCaptureScreen> createState() =>
      _ReportCaptureScreenState();
}

class _ReportCaptureScreenState extends ConsumerState<ReportCaptureScreen>
    with WidgetsBindingObserver {
  ReportCaptureController? _controller;
  bool _isExitDialogOpen = false;

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
      builder: (ctx) {
        DhrWaypoint? currentWp;
        final stationName = captureState.location?.nearestStationName;
        if (stationName != null) {
          for (final wp in DhrWaypoints.waypoints) {
            if (wp.name == stationName) {
              currentWp = wp;
              break;
            }
          }
        }
        return WaypointPickerSheet(
          selectedWaypoint: currentWp,
          currentKm: captureState.location?.kmMarker,
          onWaypointSelected: (DhrWaypoint wp) {
            ref
                .read(reportCaptureControllerProvider.notifier)
                .setManualWaypoint(wp, wp.km);
          },
          onKmChanged: (km) {
            ref
                .read(reportCaptureControllerProvider.notifier)
                .updateKmMarker(km);
          },
        );
      },
    );
  }

  Future<void> _handleCaptureExit() async {
    if (_isExitDialogOpen || !mounted) return;

    final controller = ref.read(reportCaptureControllerProvider.notifier);
    final captureState = ref.read(reportCaptureControllerProvider);

    if (captureState.capturedFile == null) {
      await controller.stopCamera();
      if (mounted) context.pop();
      return;
    }

    _isExitDialogOpen = true;

    final action = await showDialog<_CaptureExitAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => TrackGuardDialog(
        icon: Icons.edit_note_rounded,
        iconBgColor: TrackGuardDialog.brandBlueSoft,
        iconColor: TrackGuardDialog.brandBlue,
        title: 'Leave this report?',
        message: 'You have a captured photo that has not been saved yet. Would you like to save it as a draft or discard it?',
        primaryLabel: 'Save as Draft',
        primaryIcon: Icons.bookmark_added_rounded,
        primaryColor: TrackGuardDialog.brandBlue,
        onPrimaryPressed: () =>
            Navigator.pop(dialogContext, _CaptureExitAction.saveDraft),
        secondaryLabel: 'Discard Report',
        secondaryIcon: Icons.delete_outline_rounded,
        onSecondaryPressed: () =>
            Navigator.pop(dialogContext, _CaptureExitAction.discard),
        cancelLabel: 'Keep Editing',
        onCancelPressed: () => Navigator.pop(dialogContext),
      ),
    );

    _isExitDialogOpen = false;

    if (!mounted || action == null) return;

    final bool success;
    switch (action) {
      case _CaptureExitAction.saveDraft:
        success = await controller.confirmDraftAndProceed();
        break;
      case _CaptureExitAction.discard:
        success = await controller.discardCapturedPhoto();
        break;
    }

    if (!mounted) return;

    if (success) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(reportCaptureControllerProvider).errorMessage ??
                'Could not complete the action.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final captureState = ref.watch(reportCaptureControllerProvider);
    final controllerNotifier = ref.read(
      reportCaptureControllerProvider.notifier,
    );
    final cameraController = controllerNotifier.cameraController;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: captureState.capturedFile == null,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            _controller?.stopCamera();
          } else if (captureState.capturedFile != null) {
            _handleCaptureExit();
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF0A1E3F),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0A1E3F)),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: _handleCaptureExit,
            ),
            title: Text(
              l10n.captureTitle,
              style: const TextStyle(
                color: Color(0xFF0A1E3F),
                fontWeight: FontWeight.w700,
                fontSize: 18.0,
                letterSpacing: -0.2,
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: captureState.capturedFile != null
                ? _buildPhotoReview(context, captureState)
                : _buildCameraPreview(context, captureState, cameraController),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Top Location Card (Mockup Design) ─────────────────────────

  Widget _buildTopLocationCard(
    BuildContext context,
    ReportCaptureState state, {
    required bool review,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final loc = state.location;
    void open() => _showWaypointPicker(context, state);

    final isGps = loc?.source == LocationSource.gps;
    final stationName = loc?.nearestStationName != null
        ? _localizedStationName(l10n, loc!.nearestStationName!)
        : (loc != null ? l10n.dhrAlignment : l10n.gpsAcquiring);
    final km = 'Km ${(loc?.kmMarker ?? 51.0).toStringAsFixed(1)}';
    final statusText = isGps
        ? 'GPS Locked'
        : (loc != null ? l10n.setManually : 'Searching...');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: open,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                // Location Icon Box
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEBF3FC),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Symbols.location_on_rounded,
                      color: Color(0xFF074E95),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Station Name & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stationName,
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '$km  •  $statusText ',
                            style: const TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (isGps)
                            const Icon(
                              Symbols.check_circle_rounded,
                              color: Color(0xFF16A34A),
                              size: 14,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Down Chevron
                const Icon(
                  Symbols.keyboard_arrow_down_rounded,
                  color: Color(0xFF0A1E3F),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _localizedStationName(AppLocalizations l10n, String stationName) {
    for (final waypoint in DhrWaypoints.waypoints) {
      if (waypoint.name == stationName) {
        return l10n.stationName(waypoint.id);
      }
    }
    return stationName;
  }

  // ───────────────────────── Photo review ─────────────────────────

  Widget _buildPhotoReview(BuildContext context, ReportCaptureState state) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(reportCaptureControllerProvider.notifier);
    final photo = state.capturedFile;
    if (photo == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Top Location Card
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
          child: _buildTopLocationCard(context, state, review: true),
        ),

        // Photo Preview Frame
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(photo, fit: BoxFit.contain),
              ),
            ),
          ),
        ),

        // Bottom Actions
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(
                          color: Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: controller.retakePhoto,
                      child: Text(
                        l10n.retake,
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: PrimaryButton(
                      text: l10n.confirmPhoto,
                      icon: Icons.check_rounded,
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      onPressed: state.isCapturing
                          ? null
                          : () async {
                              final success = await controller
                                  .confirmDraftAndProceed();

                              if (success && context.mounted) {
                                context.push('/gangman/report/review').then((
                                  _,
                                ) {
                                  if (mounted) {
                                    _controller?.resumeCameraIfNeeded();
                                  }
                                });
                              }
                            },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Camera preview (Mockup Design) ─────────────────────────

  Widget _buildCameraPreview(
    BuildContext context,
    ReportCaptureState state,
    CameraController? cameraController,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(reportCaptureControllerProvider.notifier);

    if (state.isCameraInitializing) {
      return LoadingView(message: l10n.startingCamera);
    }

    if (!state.isCameraReady ||
        cameraController == null ||
        !cameraController.value.isInitialized) {
      return _CameraErrorView(
        message: state.errorMessage ?? l10n.cameraUnavailable,
        galleryLabel: l10n.galleryFallback,
        retryLabel: l10n.retryCamera,
        onRetry: controller.initializeCamera,
        onGallery: controller.pickFromGallery,
      );
    }

    return Column(
      children: [
        // 1. Top Location Card (Mockup Design)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
          child: _buildTopLocationCard(context, state, review: false),
        ),

        // 2. Camera Viewfinder with Rounded Frame and Survey Corner Brackets (Mockup Design)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _CoverPreview(controller: cameraController),
                    // Four survey corner brackets
                    const IgnorePointer(
                      child: CustomPaint(
                        painter: _CornersPainter(inset: EdgeInsets.all(20)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 3. Bottom Camera Controls Bar (Mockup Design)
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(36, 16, 36, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Gallery button with label
                _buildBottomControlItem(
                  icon: Symbols.image_rounded,
                  label: 'Gallery',
                  onTap: controller.pickFromGallery,
                ),

                // Center Shutter Button with outer ring and inner camera icon
                _buildShutterButton(
                  busy: state.isCapturing,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    controller.capturePhoto();
                  },
                ),

                // Switch Camera button with label
                _buildBottomControlItem(
                  icon: Symbols.cameraswitch_rounded,
                  label: 'Switch',
                  onTap: controller.hasMultipleCameras
                      ? controller.switchCamera
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControlItem({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: onTap != null ? 1.0 : 0.4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF3FC),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: const Color(0xFF074E95), size: 24),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShutterButton({
    required bool busy,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF074E95), width: 2.5),
        ),
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF074E95),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF074E95).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(
                    Symbols.photo_camera_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Preview & Focus Corners ─────────────────────────

/// Fills the available space without stretching the camera feed.
class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.previewSize;
    if (size == null) return CameraPreview(controller);

    // previewSize is reported in landscape; swap for portrait.
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: size.height,
          height: size.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

/// Four corner brackets, like a survey/inspection focus frame.
class _CornersPainter extends CustomPainter {
  const _CornersPainter({required this.inset});

  final EdgeInsets inset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final r = Rect.fromLTRB(
      inset.left,
      inset.top,
      size.width - inset.right,
      size.height - inset.bottom,
    );
    const len = 28.0;

    final path = Path()
      ..moveTo(r.left, r.top + len)
      ..lineTo(r.left, r.top)
      ..lineTo(r.left + len, r.top)
      ..moveTo(r.right - len, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right, r.top + len)
      ..moveTo(r.right, r.bottom - len)
      ..lineTo(r.right, r.bottom)
      ..lineTo(r.right - len, r.bottom)
      ..moveTo(r.left + len, r.bottom)
      ..lineTo(r.left, r.bottom)
      ..lineTo(r.left, r.bottom - len);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornersPainter old) => old.inset != inset;
}

// ───────────────────────── Camera Error / Fallback View (Mockup Design) ─────────────────────────

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({
    required this.message,
    required this.galleryLabel,
    required this.retryLabel,
    required this.onRetry,
    required this.onGallery,
  });

  final String message;
  final String galleryLabel;
  final String retryLabel;
  final VoidCallback onRetry;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Concentric soft pink circles with red camera off icon
            Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFF1F2),
              ),
              child: Center(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFE4E6),
                  ),
                  child: const Center(
                    child: Icon(
                      Symbols.no_photography_rounded,
                      size: 44,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Camera Unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20.0,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'Please use the gallery fallback or retry the\ncamera.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14.0,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),

            // Retry Camera Button (Solid blue)
            Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF074E95),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF074E95).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRetry,
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Symbols.refresh_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          retryLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Select from Gallery Button (Outlined)
            Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF074E95), width: 1.2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onGallery,
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Symbols.photo_library_rounded,
                          color: Color(0xFF074E95),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          galleryLabel,
                          style: const TextStyle(
                            color: Color(0xFF074E95),
                            fontSize: 15.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
