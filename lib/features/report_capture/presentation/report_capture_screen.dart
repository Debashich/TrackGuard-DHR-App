import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/dhr_waypoints.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/location_source.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/primary_button.dart';
import 'report_capture_controller.dart';
import 'widgets/waypoint_picker.dart';

// Strings below are not localized yet; move them into the .arb files.
const _kGpsLocked = 'GPS locked';
const _kSetManually = 'Set manually';
const _kStartingCamera = 'Starting camera…';
const _kRetryCamera = 'Retry camera';
const _kCapturePhoto = 'Capture photo';

/// Palette drawn from the DHR itself: tea-garden night greens, locomotive
/// brass, and a signal-lamp green for "locked".
abstract final class _C {
  static const ink = Color(0xFF080E0C); // screen background
  static const surface = Color(0xFF111A17); // raised panels
  static const brass = Color(0xFFD9A441); // primary accent (shutter, manual)
  static const signal = Color(0xFF52E0A4); // GPS locked / confirm
  static const text = Color(0xFFEAF1EE);
  static const textDim = Color(0xFF9DB0A8);
  static final hairline = Colors.white.withValues(alpha: 0.10);
  static final glass = const Color(0xFF05100C).withValues(alpha: 0.55);
}

const double _kFrameRadius = 28;

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
    // Release camera hardware via the stored reference, not ref.read.
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

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _controller?.stopCamera();
      },
      child: Scaffold(
        backgroundColor: _C.ink,
        appBar: AppBar(
          backgroundColor: _C.ink,
          foregroundColor: _C.text,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () async {
              await controllerNotifier.stopCamera();
              if (context.mounted) context.pop();
            },
          ),
          title: Text(
            l10n.captureTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              letterSpacing: -0.1,
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
    );
  }

  // ───────────────────────── Location pill ─────────────────────────

  Widget _locationPill(
    BuildContext context,
    ReportCaptureState state, {
    required bool review,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final loc = state.location;
    void open() => _showWaypointPicker(context, state);

    if (loc == null) {
      return _LocationPill(
        status: _LocStatus.searching,
        title: l10n.gpsAcquiring,
        onTap: open,
      );
    }

    final isGps = loc.source == LocationSource.gps;
    final km = 'Km ${(loc.kmMarker ?? 51.0).toStringAsFixed(1)}';
    final detail = review
        ? DhrWaypoints.getSectionName(loc.sectionId)
        : (isGps ? _kGpsLocked : _kSetManually);

    return _LocationPill(
      status: isGps ? _LocStatus.gps : _LocStatus.manual,
      title: loc.nearestStationName ?? 'DHR alignment',
      subtitle: '$km  ·  $detail',
      hint: isGps ? null : l10n.manualLocationNotice,
      onTap: open,
    );
  }

  // ───────────────────────── Photo review ─────────────────────────

  Widget _buildPhotoReview(BuildContext context, ReportCaptureState state) {
    if (state.capturedFile == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(reportCaptureControllerProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: _Frame(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: _C.surface),
                  Image.file(state.capturedFile!, fit: BoxFit.contain),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _locationPill(context, state, review: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.text,
                        side: BorderSide(color: _C.hairline, width: 1.5),
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: controller.retakePhoto,
                      child: Text(l10n.retake),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 56,
                    child: PrimaryButton(
                      text: l10n.confirmPhoto,
                      icon: Icons.check_rounded,
                      backgroundColor: _C.signal,
                      foregroundColor: _C.ink,
                      onPressed: () async {
                        final success =
                            await controller.confirmDraftAndProceed();
                        if (success && context.mounted) {
                          context.push('/gangman/report/review').then((_) {
                            if (mounted) _controller?.resumeCameraIfNeeded();
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

  // ───────────────────────── Camera preview ─────────────────────────

  Widget _buildCameraPreview(
    BuildContext context,
    ReportCaptureState state,
    CameraController? cameraController,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(reportCaptureControllerProvider.notifier);

    if (state.isCameraInitializing) {
      return const LoadingView(message: _kStartingCamera);
    }

    if (!state.isCameraReady ||
        cameraController == null ||
        !cameraController.value.isInitialized) {
      return _CameraErrorView(
        message: state.errorMessage ?? l10n.cameraUnavailable,
        galleryLabel: l10n.galleryFallback,
        onRetry: controller.initializeCamera,
        onGallery: controller.pickFromGallery,
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: _Frame(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CoverPreview(controller: cameraController),
                  // Focus-frame corners sit below the location pill.
                  const IgnorePointer(
                    child: CustomPaint(
                      painter: _CornersPainter(
                        inset: EdgeInsets.fromLTRB(22, 84, 22, 22),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _locationPill(context, state, review: false),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoundIconButton(
                  icon: Icons.photo_library_outlined,
                  tooltip: l10n.galleryFallback,
                  onPressed: controller.pickFromGallery,
                ),
                _ShutterButton(
                  busy: state.isCapturing,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    controller.capturePhoto();
                  },
                ),
                _RoundIconButton(
                  icon: Icons.cameraswitch_outlined,
                  tooltip: l10n.switchCamera,
                  onPressed: controller.hasMultipleCameras
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
}

// ───────────────────────── Components ─────────────────────────

enum _LocStatus { gps, manual, searching }

/// Floating glass pill that lives on the viewfinder. Replaces the old card.
class _LocationPill extends StatelessWidget {
  const _LocationPill({
    required this.status,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.hint,
  });

  final _LocStatus status;
  final String title;
  final String? subtitle;
  final String? hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = status == _LocStatus.gps ? _C.signal : _C.brass;

    return Semantics(
      button: true,
      label: [title, ?subtitle].join(', '),
      hint: hint,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Material(
            color: _C.glass,
            clipBehavior: Clip.antiAlias,
            shape: StadiumBorder(side: BorderSide(color: _C.hairline)),
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 9, 12, 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusDot(
                        color: color,
                        pulse: status != _LocStatus.manual,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _C.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: status == _LocStatus.manual
                                      ? _C.brass
                                      : _C.textDim,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: _C.textDim,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Status dot with an expanding ring while the fix is live or being acquired.
class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.color, required this.pulse});

  final Color color;
  final bool pulse;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _anim.repeat();
  }

  @override
  void didUpdateWidget(covariant _StatusDot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_anim.isAnimating) {
      _anim.repeat();
    } else if (!widget.pulse && _anim.isAnimating) {
      _anim.stop();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate = widget.pulse && !MediaQuery.of(context).disableAnimations;

    return SizedBox(
      width: 20,
      height: 20,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, _) {
          final t = animate ? Curves.easeOut.transform(_anim.value) : 0.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (animate)
                Container(
                  width: 9 + 11 * t,
                  height: 9 + 11 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.5 * (1 - t)),
                  ),
                ),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Rounded, hairline-bordered window used for both viewfinder and review.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_kFrameRadius);
    return Container(
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: _C.hairline),
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

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
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final r = Rect.fromLTRB(
      inset.left,
      inset.top,
      size.width - inset.right,
      size.height - inset.bottom,
    );
    const len = 26.0;

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

class _ShutterButton extends StatefulWidget {
  const _ShutterButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.busy;

    return Semantics(
      button: true,
      enabled: !busy,
      label: _kCapturePhoto,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: busy ? null : (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: busy ? null : widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3.5),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: busy ? Colors.white24 : _C.brass,
                boxShadow: busy
                    ? null
                    : [
                        BoxShadow(
                          color: _C.brass.withValues(alpha: 0.35),
                          blurRadius: 16,
                        ),
                      ],
              ),
              child: busy
                  ? const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed != null ? 1 : 0.35,
      child: Material(
        color: Colors.white.withValues(alpha: 0.07),
        clipBehavior: Clip.antiAlias,
        shape: CircleBorder(side: BorderSide(color: _C.hairline)),
        child: IconButton(
          iconSize: 26,
          constraints: const BoxConstraints.tightFor(width: 54, height: 54),
          icon: Icon(icon, color: _C.text),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({
    required this.message,
    required this.galleryLabel,
    required this.onRetry,
    required this.onGallery,
  });

  final String message;
  final String galleryLabel;
  final VoidCallback onRetry;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.surface,
                border: Border.all(color: _C.hairline),
              ),
              child: const Icon(
                Icons.no_photography_outlined,
                size: 42,
                color: _C.textDim,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _C.textDim,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: PrimaryButton(
                text: _kRetryCamera,
                icon: Icons.refresh_rounded,
                backgroundColor: _C.brass,
                foregroundColor: _C.ink,
                onPressed: onRetry,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(galleryLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _C.text,
                  side: BorderSide(color: _C.hairline, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onGallery,
              ),
            ),
          ],
        ),
      ),
    );
  }
}