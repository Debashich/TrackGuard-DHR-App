import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/constants/dhr_waypoints.dart';
import '../../../core/utils/date_format_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/inspection_status.dart';
import '../../../shared/models/sync_status.dart';
import '../../../shared/widgets/ai_metadata_card.dart';
import '../../../shared/widgets/hazard_icon.dart';
import '../../../shared/widgets/logout_confirmation.dart';
import '../../../shared/widgets/severity_badge.dart';
import '../../../shared/widgets/sync_status_card.dart';
import '../../reports/domain/report_repository_provider.dart';

class GangmanReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;

  const GangmanReportDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<GangmanReportDetailScreen> createState() =>
      _GangmanReportDetailScreenState();
}

Widget _statusStep(String label, bool complete) => Column(mainAxisSize: MainAxisSize.min, children: [Icon(complete ? Icons.check_circle : Icons.radio_button_unchecked, color: complete ? AppTheme.statusGreen : AppTheme.borderDark), const SizedBox(height: 4), SizedBox(width: 82, child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)))]);

class _GangmanReportDetailScreenState
    extends ConsumerState<GangmanReportDetailScreen> {
  late Future<HazardReport?> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = ref
        .read(reportRepositoryProvider)
        .getReportById(widget.reportId);
  }

  @override
  void didUpdateWidget(covariant GangmanReportDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportId != widget.reportId) {
      _reportFuture = ref
          .read(reportRepositoryProvider)
          .getReportById(widget.reportId);
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

  void _showFullImage(BuildContext context, String photoPath) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                File(photoPath),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textPrimary, size: 30),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportDetailTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: l10n.navigationProfile,
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOut,
            onPressed: () => showLogoutConfirmationDialog(context, ref),
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
                      Icons.search_off,
                      size: 48,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.reportDetailUnavailable,
                      style: const TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final createdAtText = DateFormatUtils.formatDateTime(
            report.createdAt,
            l10n,
          );
          final updatedAtText = DateFormatUtils.formatDateTime(
            report.updatedAt,
            l10n,
          );

          final photoPath =
              report.originalPhotoPath ?? report.thumbnailPhotoPath;
          final hasValidFile =
              photoPath != null && File(photoPath).existsSync();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Captured Photo Card with Tap-to-Enlarge
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: hasValidFile
                        ? () => _showFullImage(context, photoPath)
                        : null,
                    child: SizedBox(
                      height: 220,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (hasValidFile)
                            Image.file(File(photoPath), fit: BoxFit.cover)
                          else
                            Container(
                              color: AppTheme.surfaceDarkElevated,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.broken_image_outlined,
                                    size: 48,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    photoPath == null
                                        ? 'No photo attached'
                                        : 'Photo not found on device',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (hasValidFile)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.fullscreen,
                                      size: 16,
                                      color: AppTheme.primaryAmber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.reportDetailViewImage,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text('${HazardIcon.getLocalizedLabel(context, report.confirmedHazardType)} Report', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _statusStep('Sent', report.syncStatus == SyncStatus.synced), const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                  _statusStep('Seen by Supervisor', report.inspectionStatus != InspectionStatus.open), const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                  _statusStep('Resolved', report.inspectionStatus == InspectionStatus.resolved),
                ]))),
                const SizedBox(height: 12),
                // Full Sync Status Card
                SyncStatusCard(
                  report: report,
                  onRetry: report.syncStatus == SyncStatus.failed
                      ? () => _triggerRetry(report)
                      : null,
                ),
                const SizedBox(height: 16),

                // Confirmed Classification Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.humanConfirmationTitle.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryAmber,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            HazardIcon(
                              hazardType: report.confirmedHazardType,
                              size: 24,
                              showLabel: true,
                            ),
                            SeverityBadge(
                              severity: report.confirmedSeverity,
                              isLarge: true,
                            ),
                          ],
                        ),
                        if (report.userNote.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            l10n.gangmanNote,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.userNote,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Location Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.reportDetailLocation.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryAmber,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${report.nearestStationName ?? "DHR Alignment"} • Km ${(report.kmMarker ?? 51.0).toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.assignedSection(
                            DhrWaypoints.getSectionName(report.sectionId),
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Source: ${report.locationSource.name.toUpperCase()} ${report.gpsAccuracyMeters != null ? "(±${report.gpsAccuracyMeters!.toStringAsFixed(1)}m)" : ""}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Card(child: ExpansionTile(title: const Text('Technical & AI Audit Details'), leading: const Icon(Icons.fact_check_outlined), children: [Padding(padding: const EdgeInsets.all(12), child: AiMetadataCard.fromReport(report))])),
                const SizedBox(height: 16),

                // Audit Timestamps Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'REPORT AUDIT INFORMATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryAmber,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.history,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.reportDetailCreated(createdAtText),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.update,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.reportDetailUpdated(updatedAtText),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Report ID: ${report.id}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
