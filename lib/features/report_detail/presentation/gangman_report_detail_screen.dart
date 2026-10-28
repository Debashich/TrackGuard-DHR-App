import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/dhr_waypoints.dart';
import '../../../core/utils/date_format_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/sync_status.dart';
import '../../../shared/widgets/ai_metadata_card.dart';
import '../../../shared/widgets/hazard_icon.dart';
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

class _GangmanReportDetailScreenState
    extends ConsumerState<GangmanReportDetailScreen> {
  Future<void> _triggerRetry(HazardReport report) async {
    final syncService = ref.read(reportSyncServiceProvider);
    if (syncService != null) {
      try {
        await syncService.syncPendingReports();
        ref.invalidate(localReportsProvider);
        if (mounted) {
          setState(() {});
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.watch(reportRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.reviewTitle} ${widget.reportId.length >= 8 ? widget.reportId.substring(0, 8) : widget.reportId}',
        ),
      ),
      body: FutureBuilder<HazardReport?>(
        future: repo.getReportById(widget.reportId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final report = snapshot.data;
          if (report == null) {
            return Center(
              child: Text(
                'Report not found',
                style: const TextStyle(color: Colors.white70),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Original Photo
                if (report.originalPhotoPath != null) ...[
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      height: 220,
                      child: Image.file(
                        File(report.originalPhotoPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.white38,
                              ),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

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
                              color: Colors.white60,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.userNote,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
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
                        const Text(
                          'LOCATION & DHR ALIGNMENT',
                          style: TextStyle(
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
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Source: ${report.locationSource.name.toUpperCase()} ${report.gpsAccuracyMeters != null ? "(±${report.gpsAccuracyMeters!.toStringAsFixed(1)}m)" : ""}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // AI Suggestion and Audit Card
                AiMetadataCard.fromReport(report),
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
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Created: $createdAtText',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
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
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Updated: $updatedAtText',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
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
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Report ID: ${report.id}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white38,
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
