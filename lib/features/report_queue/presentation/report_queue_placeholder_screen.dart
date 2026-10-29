import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/constants/dhr_waypoints.dart';
import '../../../core/sync/sync_error_message_mapper.dart';
import '../../../core/utils/date_format_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/ai_provider.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/sync_status.dart';
import '../../../shared/widgets/hazard_icon.dart';
import '../../../shared/widgets/logout_confirmation.dart';
import '../../../shared/widgets/severity_badge.dart';
import '../../../shared/widgets/sync_error_banner.dart';
import '../../../shared/widgets/sync_status_badge.dart';
import '../../../shared/widgets/sync_summary_card.dart';
import '../../reports/domain/report_repository_provider.dart';

enum QueueFilter { all, pending, failed, synced }

class ReportQueueScreen extends ConsumerStatefulWidget {
  const ReportQueueScreen({super.key});

  @override
  ConsumerState<ReportQueueScreen> createState() => _ReportQueueScreenState();
}

class _ReportQueueScreenState extends ConsumerState<ReportQueueScreen> {
  QueueFilter _selectedFilter = QueueFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reportsAsync = ref.watch(localReportsProvider);
    final syncSummary = ref.watch(syncSummaryProvider);
    final isOnline = ref.watch(isOnlineProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pendingQueue),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: l10n.syncNow,
            onPressed:
                (isOnline &&
                    (syncSummary.pendingCount > 0 ||
                        syncSummary.failedCount > 0) &&
                    !syncSummary.isSyncing)
                ? () async {
                    final syncService = ref.read(reportSyncServiceProvider);
                    if (syncService == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.syncErrorServerUnavailable),
                          backgroundColor: AppTheme.statusRed,
                        ),
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.syncReportsSyncing),
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    try {
                      await syncService.syncPendingReports();
                      ref.invalidate(localReportsProvider);
                      ref.invalidate(pendingReportsCountProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.syncAllReportsSynced),
                            backgroundColor: AppTheme.statusGreen,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              SyncErrorMessageMapper.getLocalizedMessage(
                                e,
                                l10n,
                              ),
                            ),
                            backgroundColor: AppTheme.statusRed,
                          ),
                        );
                      }
                    }
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: l10n.navigationProfile,
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: l10n.signOut,
            onPressed: () => showLogoutConfirmationDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final syncService = ref.read(reportSyncServiceProvider);
          if (syncService != null && isOnline) {
            try {
              await syncService.syncPendingReports();
            } catch (_) {}
          }
          ref.invalidate(localReportsProvider);
          ref.invalidate(pendingReportsCountProvider);
          await ref.read(localReportsProvider.future);
        },
        child: reportsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.statusRed,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    SyncErrorMessageMapper.getLocalizedMessage(error, l10n),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(localReportsProvider),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
          data: (reports) {
            final filteredReports = _filterReports(reports, _selectedFilter);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Top Sync Summary Card
                SyncSummaryCard(
                  summary: syncSummary,
                  onSyncNow:
                      (isOnline &&
                          (syncSummary.pendingCount > 0 ||
                              syncSummary.failedCount > 0) &&
                          !syncSummary.isSyncing)
                      ? () async {
                          final syncService = ref.read(
                            reportSyncServiceProvider,
                          );
                          if (syncService != null) {
                            try {
                              await syncService.syncPendingReports();
                              ref.invalidate(localReportsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.syncAllReportsSynced),
                                    backgroundColor: AppTheme.statusGreen,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      SyncErrorMessageMapper.getLocalizedMessage(
                                        e,
                                        l10n,
                                      ),
                                    ),
                                    backgroundColor: AppTheme.statusRed,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 16),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        QueueFilter.all,
                        '${l10n.allFilter} (${reports.length})',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        QueueFilter.pending,
                        '${l10n.syncStatusPending} (${reports.where((r) => r.syncStatus == SyncStatus.pending).length})',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        QueueFilter.failed,
                        '${l10n.syncStatusFailed} (${reports.where((r) => r.syncStatus == SyncStatus.failed).length})',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        QueueFilter.synced,
                        '${l10n.syncStatusSynced} (${reports.where((r) => r.syncStatus == SyncStatus.synced).length})',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (filteredReports.isEmpty)
                  _buildEmptyState(context, reports.isEmpty)
                else
                  ...filteredReports.map(
                    (report) => _buildReportItem(context, report),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(QueueFilter filter, String label) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryAmber,
      backgroundColor: AppTheme.surfaceDark,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
        color: isSelected ? Colors.black : Colors.white70,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryAmber : AppTheme.borderDark,
      ),
      onSelected: (_) {
        setState(() {
          _selectedFilter = filter;
        });
      },
    );
  }

  List<HazardReport> _filterReports(
    List<HazardReport> reports,
    QueueFilter filter,
  ) {
    switch (filter) {
      case QueueFilter.all:
        return reports;
      case QueueFilter.pending:
        return reports
            .where((r) => r.syncStatus == SyncStatus.pending)
            .toList();
      case QueueFilter.failed:
        return reports.where((r) => r.syncStatus == SyncStatus.failed).toList();
      case QueueFilter.synced:
        return reports.where((r) => r.syncStatus == SyncStatus.synced).toList();
    }
  }

  Widget _buildEmptyState(BuildContext context, bool noReportsAtAll) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            noReportsAtAll
                ? l10n.pendingReportsCount(0)
                : l10n.noReportsMatchFilter,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.offlineExplanation,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(BuildContext context, HazardReport report) {
    final l10n = AppLocalizations.of(context)!;
    final kmText = report.kmMarker != null
        ? 'Km ${report.kmMarker!.toStringAsFixed(1)}'
        : 'Km 51.0';
    final sectionName = DhrWaypoints.getSectionName(report.sectionId);
    final stationName = report.nearestStationName ?? sectionName;
    final createdText = DateFormatUtils.formatDateTime(report.createdAt, l10n);

    // AI Provider/Model description
    final aiText = report.aiProvider == AiProvider.offlineGemma
        ? (report.aiModel ?? 'Gemma 4 E2B')
        : report.aiProvider == AiProvider.heuristic
        ? l10n.aiProviderHeuristic
        : report.aiProvider == AiProvider.onlineGemini
        ? 'Gemini Cloud'
        : l10n.aiProviderManual;

    final hasThumbnail =
        report.thumbnailPhotoPath != null &&
        File(report.thumbnailPhotoPath!).existsSync();
    final hasOriginal =
        report.originalPhotoPath != null &&
        File(report.originalPhotoPath!).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/gangman/reports/${report.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Photo/Icon + Hazard + Severity Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: hasThumbnail
                          ? Image.file(
                              File(report.thumbnailPhotoPath!),
                              fit: BoxFit.cover,
                            )
                          : hasOriginal
                          ? Image.file(
                              File(report.originalPhotoPath!),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: AppTheme.surfaceDarkElevated,
                              child: Center(
                                child: HazardIcon(
                                  hazardType: report.confirmedHazardType,
                                  size: 26,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          HazardIcon.getLocalizedLabel(
                            context,
                            report.confirmedHazardType,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$kmText • $stationName',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SeverityBadge(severity: report.confirmedSeverity),
                ],
              ),
              const SizedBox(height: 10),

              // AI metadata & timestamp chips
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDarkElevated,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.psychology_outlined,
                          size: 12,
                          color: AppTheme.primaryAmber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          aiText,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    createdText,
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                  const Spacer(),
                  SyncStatusBadge(status: report.syncStatus, compact: true),
                ],
              ),

              // Sync error banner if sync failed
              if (report.syncStatus == SyncStatus.failed &&
                  report.lastSyncError != null) ...[
                const SizedBox(height: 10),
                SyncErrorBanner(
                  error: report.lastSyncError,
                  onRetry: () async {
                    final syncService = ref.read(reportSyncServiceProvider);
                    if (syncService != null) {
                      try {
                        await syncService.syncPendingReports();
                        ref.invalidate(localReportsProvider);
                      } catch (_) {}
                    }
                  },
                ),
              ],

              // Synced timestamp note
              if (report.syncStatus == SyncStatus.synced &&
                  report.syncTimestamp != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${l10n.syncStatusSynced}: ${DateFormatUtils.formatDateTime(report.syncTimestamp!, l10n)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.statusGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
