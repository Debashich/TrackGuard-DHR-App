import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/dhr_waypoints.dart';
import '../../../core/utils/date_format_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/ai_provider.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/hazard_type.dart';
import '../../../shared/models/inspection_status.dart';
import '../../../shared/models/sync_status.dart';
import '../../../shared/widgets/severity_badge.dart';
import '../../reports/domain/report_repository_provider.dart';

class GangmanReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;

  const GangmanReportDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<GangmanReportDetailScreen> createState() =>
      _GangmanReportDetailScreenState();
}

class _GangmanReportDetailScreenState
    extends ConsumerState<GangmanReportDetailScreen> {
  late Future<HazardReport?> _reportFuture;
  bool _isAiAuditExpanded = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _reportFuture = ref
        .read(reportRepositoryProvider)
        .getReportById(widget.reportId);
    unawaited(_refreshInspectionStatus());
  }

  @override
  void didUpdateWidget(covariant GangmanReportDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportId != widget.reportId) {
      _reportFuture = ref
          .read(reportRepositoryProvider)
          .getReportById(widget.reportId);
      unawaited(_refreshInspectionStatus());
    }
  }

  Future<void> _refreshInspectionStatus() async {
    final reportId = widget.reportId;
    final syncService = ref.read(reportSyncServiceProvider);

    if (syncService == null) return;

    try {
      final refreshed = await syncService.refreshInspectionStatus(reportId);

      if (!mounted || refreshed == null || widget.reportId != reportId) {
        return;
      }

      setState(() {
        _reportFuture = Future.value(refreshed);
      });
    } catch (error) {
      debugPrint('[ReportDetail] Status refresh failed: $error');
    }
  }

  Future<void> _triggerRetry(HazardReport report) async {
    final syncService = ref.read(reportSyncServiceProvider);
    if (syncService != null) {
      try {
        await syncService.syncPendingReports();
        ref.invalidate(localReportsProvider);
        if (mounted) {
          setState(() {
            _reportFuture = ref
                .read(reportRepositoryProvider)
                .getReportById(widget.reportId);
          });
        }
      } catch (_) {}
    }
  }

  void _showFullImage(
    BuildContext context,
    HazardReport report,
    String photoPath,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        fullscreenDialog: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImageViewer(
            photoPath: photoPath,
            report: report,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  String _getHazardReportTitle(HazardReport report) {
    switch (report.confirmedHazardType) {
      case HazardType.damagedWall:
        return 'Damaged Retaining Wall Report';
      case HazardType.rockfall:
        return 'Rockfall / Fallen Debris Report';
      case HazardType.slip:
        return 'Landslip / Mudslide Report';
      case HazardType.blockedDrain:
        return 'Blocked Catchwater Drain Report';
      case HazardType.trackDefect:
        return 'Track Defect / Rail Gap Report';
      case HazardType.vegetation:
        return 'Track Obstruction / Vegetation Report';
      case HazardType.other:
        return 'Track Issue / Other Hazard Report';
    }
  }

  String _providerDisplayName(AiProvider provider) {
    switch (provider) {
      case AiProvider.onlineGemini:
        return 'Online Gemini';
      case AiProvider.offlineGemma:
        return 'Offline Gemma';
      case AiProvider.heuristic:
        return 'Heuristic Fallback';
      case AiProvider.manual:
        return 'Manual Inspection';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Symbols.arrow_back_rounded,
              color: Color(0xFF0F172A),
              size: 22,
            ),
            tooltip: 'Back',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/gangman/home');
              }
            },
          ),
          title: Text(
            l10n.reportDetailTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Symbols.person_rounded,
                color: Color(0xFF0F172A),
                size: 22,
              ),
              tooltip: l10n.navigationProfile,
              onPressed: () => context.push('/profile'),
            ),
          ],
        ),
        body: FutureBuilder<HazardReport?>(
          future: _reportFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final report = snapshot.data;
            if (report == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Symbols.search_off_rounded,
                        size: 48,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.reportDetailUnavailable,
                        style: const TextStyle(color: Color(0xFF64748B)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hero Captured Photo
                  _buildHeroPhoto(report),
                  const SizedBox(height: 14),

                  // 2. Report Header Row: Hazard Title, Location/Date, Severity Badge
                  _buildHeaderSection(report),
                  const SizedBox(height: 14),

                  // 3. Report Status Stepper Card
                  _buildReportStatusCard(report, l10n),
                  const SizedBox(height: 14),

                  // 4. Sync Summary Card
                  _buildSyncSummaryCard(report, l10n),
                  const SizedBox(height: 14),

                  // 5. AI Advisory Suggestion (AI-generated observation note)
                  if (report.aiNote != null && report.aiNote!.trim().isNotEmpty) ...[
                    _buildAiSuggestionCard(report, l10n),
                    const SizedBox(height: 14),
                  ],

                  // 6. Gangman Observation Note (if present)
                  if (report.userNote.trim().isNotEmpty) ...[
                    _buildUserNoteCard(report, l10n),
                    const SizedBox(height: 14),
                  ],

                  // 6. Location & Track Alignment Card
                  _buildLocationCard(report, l10n),
                  const SizedBox(height: 14),

                  // 7. Technical & AI Audit Details Collapsible Card
                  _buildAiAuditCard(report, l10n),
                  const SizedBox(height: 14),

                  // 8. Report Audit Information Card
                  _buildReportAuditCard(report, l10n),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 1. Hero Photo Card
  Widget _buildHeroPhoto(HazardReport report) {
    final photoPath = report.originalPhotoPath ?? report.thumbnailPhotoPath;
    final hasValidFile = photoPath != null && File(photoPath).existsSync();

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasValidFile)
            Image.file(
              File(photoPath),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallbackPhoto(report),
            )
          else
            _buildFallbackPhoto(report),

          // "View Full Image" Pill Button
          if (hasValidFile)
            Positioned(
              bottom: 12,
              right: 12,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showFullImage(context, report, photoPath),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Symbols.crop_free_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B), // Primary Amber
                        ),
                        SizedBox(width: 6),
                        Text(
                          'View Full Image',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
    );
  }

  Widget _buildFallbackPhoto(HazardReport report) {
    List<Color> gradientColors;
    IconData iconData;

    switch (report.confirmedHazardType) {
      case HazardType.damagedWall:
        gradientColors = const [Color(0xFF334155), Color(0xFF475569)];
        iconData = Symbols.construction_rounded;
        break;
      case HazardType.rockfall:
      case HazardType.slip:
        gradientColors = const [Color(0xFF422006), Color(0xFF713F12)];
        iconData = Symbols.landscape_rounded;
        break;
      case HazardType.vegetation:
        gradientColors = const [Color(0xFF064E3B), Color(0xFF047857)];
        iconData = Symbols.park_rounded;
        break;
      case HazardType.trackDefect:
        gradientColors = const [Color(0xFF1E293B), Color(0xFF334155)];
        iconData = Symbols.handyman_rounded;
        break;
      case HazardType.blockedDrain:
        gradientColors = const [Color(0xFF1E3A5F), Color(0xFF074E95)];
        iconData = Symbols.water_drop_rounded;
        break;
      default:
        gradientColors = const [Color(0xFF1E293B), Color(0xFF475569)];
        iconData = Symbols.warning_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 48, color: Colors.white70),
            const SizedBox(height: 8),
            Text(
              report.originalPhotoPath == null
                  ? 'No Photo Attached'
                  : 'Photo Stored on Local Device',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Report Header Row
  Widget _buildHeaderSection(HazardReport report) {
    final kmText =
        'Km ${(report.kmMarker ?? 51.0).toStringAsFixed(1)}, ${report.nearestStationName ?? "Kurseong Station"}';
    final createdDateText = DateFormatUtils.formatReportDate(report.createdAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hazard Title + Location + Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getHazardReportTitle(report),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Symbols.location_on_rounded,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      kmText,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Symbols.calendar_today_rounded,
                    size: 13,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    createdDateText,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Severity Badge Top-Right
        SeverityBadge(severity: report.confirmedSeverity),
      ],
    );
  }

  // 3. Report Status Stepper Card
  Widget _buildReportStatusCard(HazardReport report, AppLocalizations l10n) {
    final isSent = report.syncStatus == SyncStatus.synced;
    final isSeen =
        report.inspectionStatus == InspectionStatus.acknowledged ||
        report.inspectionStatus == InspectionStatus.inspectionRequired ||
        report.inspectionStatus == InspectionStatus.resolved;
    final isResolved = report.inspectionStatus == InspectionStatus.resolved;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Title
          const Row(
            children: [
              Icon(
                Symbols.layers_rounded,
                color: Color(0xFF074E95),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Report Status',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stepper: 3-step timeline (Sent -> Seen by Supervisor -> Resolved)
          LayoutBuilder(
            builder: (context, constraints) {
              final stepWidth = constraints.maxWidth / 3;

              return Stack(
                children: [
                  // Connecting Lines
                  Positioned(
                    top: 13,
                    left: stepWidth / 2,
                    right: stepWidth / 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 2.5,
                            color: isSeen
                                ? const Color(0xFF074E95)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 2.5,
                            color: isResolved
                                ? const Color(0xFF074E95)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3 Steps
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step 1: Sent
                      Expanded(
                        child: Column(
                          children: [
                            _buildStepCircle(isSent),
                            const SizedBox(height: 8),
                            Text(
                              l10n.statusStepSent,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSent
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Step 2: Seen by Supervisor
                      Expanded(
                        child: Column(
                          children: [
                            _buildStepCircle(isSeen),
                            const SizedBox(height: 8),
                            Text(
                              l10n.statusStepSeenBySupervisor.replaceFirst(
                                ' ',
                                '\n',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSeen
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Step 3: Resolved
                      Expanded(
                        child: Column(
                          children: [
                            _buildStepCircle(isResolved),
                            const SizedBox(height: 8),
                            Text(
                              l10n.statusStepResolved,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isResolved
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(bool isActive) {
    if (isActive) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: Color(0xFF22C55E), // Solid Green
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 16,
        ),
      );
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 2,
        ),
      ),
    );
  }

  // 4. Sync Summary Card
  Widget _buildSyncSummaryCard(HazardReport report, AppLocalizations l10n) {
    final isSynced = report.syncStatus == SyncStatus.synced;
    final isFailed = report.syncStatus == SyncStatus.failed;


    Color badgeBg;
    Color badgeBorder;
    Color badgeFg;
    String badgeText;
    IconData badgeIcon;

    if (isSynced) {
      badgeBg = const Color(0xFFF0FDF4);
      badgeBorder = const Color(0xFF86EFAC);
      badgeFg = const Color(0xFF16A34A);
      badgeText = 'Synced';
      badgeIcon = Symbols.check_circle_rounded;
    } else if (isFailed) {
      badgeBg = const Color(0xFFFEF2F2);
      badgeBorder = const Color(0xFFFECACA);
      badgeFg = const Color(0xFFDC2626);
      badgeText = 'Failed';
      badgeIcon = Symbols.cancel_rounded;
    } else {
      badgeBg = const Color(0xFFFEF9C3);
      badgeBorder = const Color(0xFFFEF08A);
      badgeFg = const Color(0xFF854D0E);
      badgeText = 'Pending';
      badgeIcon = Symbols.sync_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Cloud Icon + Title + Status Pill
          Row(
            children: [
              const Icon(
                Symbols.cloud_upload_rounded,
                color: Color(0xFF074E95),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sync Summary',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeFg),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: badgeFg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Subtitle
          Text(
            isSynced
                ? 'Saved locally and synchronized with central server.'
                : (isFailed
                    ? 'Sync failed. Tap to retry.'
                    : 'Queued locally for automatic sync at next station.'),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),

          // Bottom Soft Banner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: isSynced
                  ? const Color(0xFFDCFCE7)
                  : (isFailed
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFFEF9C3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isSynced
                      ? Symbols.cloud_done_rounded
                      : (isFailed
                          ? Symbols.error_rounded
                          : Symbols.schedule_rounded),
                  size: 16,
                  color: isSynced
                      ? const Color(0xFF16A34A)
                      : (isFailed
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFCA8A04)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSynced
                        ? 'Cloud sync verified • Up to date with server'
                        : (isFailed
                            ? 'Error: ${report.lastSyncError ?? "Network error"}'
                            : 'Pending cloud sync at next station'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSynced
                          ? const Color(0xFF15803D)
                          : (isFailed
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF854D0E)),
                    ),
                  ),
                ),
                if (isFailed)
                  InkWell(
                    onTap: () => _triggerRetry(report),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. AI Advisory Suggestion Card (AI-generated observation note)
  Widget _buildAiSuggestionCard(HazardReport report, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.smart_toy_rounded,
                color: Color(0xFF074E95),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.aiSuggestionTitle,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            report.aiNote!.trim(),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // 6. Gangman Observation Note Card (if present)
  Widget _buildUserNoteCard(HazardReport report, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.description_rounded,
                color: Color(0xFF074E95),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.gangmanNote,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            report.userNote,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // 6. Location & Track Alignment Card
  Widget _buildLocationCard(HazardReport report, AppLocalizations l10n) {
    final stationName = report.nearestStationName ?? 'Kurseong Station';
    final kmNumber = (report.kmMarker ?? 51.0).toStringAsFixed(1);
    final sectionName = DhrWaypoints.getSectionName(report.sectionId);
    final sourceAccuracy = report.gpsAccuracyMeters != null
        ? '(\u00B1${report.gpsAccuracyMeters!.toStringAsFixed(1)}m)'
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          const Row(
            children: [
              Icon(
                Symbols.location_on_rounded,
                color: Color(0xFF074E95),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Location & Track Alignment',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Item 1: Station • Km
          Row(
            children: [
              const Icon(
                Symbols.location_on_rounded,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$stationName • Km $kmNumber',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Item 2: Assigned Section
          Row(
            children: [
              const Icon(
                Symbols.alt_route_rounded,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Assigned Section: $sectionName',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Item 3: Source GPS
          Row(
            children: [
              const Icon(
                Symbols.near_me_rounded,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Source: ${report.locationSource.name.toUpperCase()} $sourceAccuracy'
                      .trim(),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7. Technical & AI Audit Details Collapsible Card
  Widget _buildAiAuditCard(HazardReport report, AppLocalizations l10n) {
    final providerTitle = _providerDisplayName(report.aiProvider);
    final displayModel = report.aiModel ?? 'nvidia/nemotron-3.5-super-vl:free';
    final languageName = report.aiLanguage?.displayName ?? 'English';
    final confidencePct =
        '${((report.aiConfidence ?? 0.75) * 100).toStringAsFixed(0)}%';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Collapsible Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _isAiAuditExpanded = !_isAiAuditExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Symbols.fact_check_rounded,
                      color: Color(0xFF074E95),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Technical & AI Audit Details',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Icon(
                      _isAiAuditExpanded
                          ? Symbols.keyboard_arrow_up_rounded
                          : Symbols.keyboard_arrow_down_rounded,
                      color: const Color(0xFF074E95),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expanded Content
          if (_isAiAuditExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub-Header: Cloud Icon + "AI Advisory Metadata"
                    const Row(
                      children: [
                        Icon(
                          Symbols.cloud_rounded,
                          color: Color(0xFF074E95),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI Advisory Metadata',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // AI Provider Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1FA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Symbols.layers_rounded,
                            color: Color(0xFF074E95),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            const Text(
                              'AI Provider',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              providerTitle,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                    const Divider(
                      height: 20,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),

                    // AI Model Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1FA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Symbols.memory_rounded,
                            color: Color(0xFF074E95),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI Model',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayModel,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      height: 20,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),

                    // AI Language & Confidence (Two Columns)
                    Row(
                      children: [
                        // Left: AI Language
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F1FA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Symbols.translate_rounded,
                                  color: Color(0xFF074E95),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'AI Language',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    languageName,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            ],
                          ),
                        ),

                        // Right: Confidence
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F1FA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Symbols.verified_user_rounded,
                                  color: Color(0xFF074E95),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Confidence',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    confidencePct,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Advisory Disclaimer Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Symbols.info_rounded,
                            size: 16,
                            color: Color(0xFF074E95),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI suggestion is advisory only. Gangman inspection confirmed.',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF074E95),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 8. Report Audit Information Card
  Widget _buildReportAuditCard(HazardReport report, AppLocalizations l10n) {
    final hasBeenModified =
        report.updatedAt.difference(report.createdAt).inMinutes >= 5;
    final updatedText = DateFormatUtils.formatReportDate(report.updatedAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          const Row(
            children: [
              Icon(
                Symbols.assignment_rounded,
                color: Color(0xFF074E95),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Report Audit Information',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Report ID Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1.0),
                child: Icon(
                  Symbols.badge_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Report ID: ${report.id}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const Divider(
            height: 18,
            thickness: 1,
            color: Color(0xFFF1F5F9),
          ),

          // Source Row
          Row(
            children: [
              const Icon(
                Symbols.devices_rounded,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Source: Gangman Mobile Unit (${report.locationSource.name.toUpperCase()})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const Divider(
            height: 18,
            thickness: 1,
            color: Color(0xFFF1F5F9),
          ),

          // Audit / Status Row
          Row(
            children: [
              Icon(
                hasBeenModified
                    ? Symbols.update_rounded
                    : Symbols.verified_rounded,
                size: 16,
                color: hasBeenModified
                    ? const Color(0xFF64748B)
                    : const Color(0xFF16A34A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasBeenModified
                      ? 'Last Modified: $updatedText'
                      : 'Audit: Original submission (Unmodified)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: hasBeenModified
                        ? const Color(0xFF475569)
                        : const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


/// Immersive edge-to-edge dark image viewer with clean native AppBar,
/// interactive zoom, and double-tap gestures.
class _FullScreenImageViewer extends StatefulWidget {
  final String photoPath;
  final HazardReport report;

  const _FullScreenImageViewer({
    required this.photoPath,
    required this.report,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _showOverlays = true;

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      _transformationController.value = Matrix4.identity()
        ..translateByDouble(-position.dx * 1.5, -position.dy * 1.5, 0.0, 1.0)
        ..scaleByDouble(2.5, 2.5, 1.0, 1.0);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  String _getReportTitle() {
    switch (widget.report.confirmedHazardType) {
      case HazardType.damagedWall:
        return 'Damaged Retaining Wall Photo';
      case HazardType.rockfall:
        return 'Rockfall / Fallen Debris Photo';
      case HazardType.slip:
        return 'Landslip / Mudslide Photo';
      case HazardType.blockedDrain:
        return 'Blocked Catchwater Drain Photo';
      case HazardType.trackDefect:
        return 'Track Defect / Rail Gap Photo';
      case HazardType.vegetation:
        return 'Track Obstruction / Vegetation Photo';
      case HazardType.other:
        return 'Track Issue Photo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final kmText =
        'Km ${(widget.report.kmMarker ?? 51.0).toStringAsFixed(1)} • ${widget.report.nearestStationName ?? "Kurseong Station"}';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: _showOverlays
            ? AppBar(
                backgroundColor: Colors.black.withValues(alpha: 0.75),
                elevation: 0,
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  statusBarBrightness: Brightness.dark,
                ),
                leading: IconButton(
                  icon: const Icon(
                    Symbols.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                titleSpacing: 0,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getReportTitle(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kmText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
            : null,
        body: GestureDetector(
          onDoubleTapDown: (details) => _doubleTapDetails = details,
          onDoubleTap: _handleDoubleTap,
          onTap: () {
            setState(() {
              _showOverlays = !_showOverlays;
            });
          },
          child: Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 5.0,
              clipBehavior: Clip.none,
              child: Center(
                child: Image.file(
                  File(widget.photoPath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Symbols.broken_image_rounded,
                          size: 64,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Photo could not be loaded from device',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
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
