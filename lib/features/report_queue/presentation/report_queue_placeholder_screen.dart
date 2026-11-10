import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/constants/dhr_waypoints.dart';
import '../../../core/sync/sync_error_message_mapper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/hazard_type.dart';
import '../../../shared/models/sync_status.dart';
import '../../../shared/widgets/severity_badge.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reportsAsync = ref.watch(localReportsProvider);
    final syncSummary = ref.watch(syncSummaryProvider);
    final isOnline = ref.watch(isOnlineProvider).value ?? false;

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
            l10n.myReports,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
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
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF074E95)),
            ),
            error: (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Symbols.error_rounded,
                      size: 44,
                      color: AppTheme.statusRed,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      SyncErrorMessageMapper.getLocalizedMessage(error, l10n),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF074E95),
                      ),
                      onPressed: () => ref.invalidate(localReportsProvider),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
            data: (reports) {
              final filteredReports = _filterReports(reports, _selectedFilter);
              final pendingCount = reports
                  .where(
                    (r) =>
                        r.syncStatus == SyncStatus.pending ||
                        r.syncStatus == SyncStatus.syncing,
                  )
                  .length;
              final failedCount =
                  reports.where((r) => r.syncStatus == SyncStatus.failed).length;
              final syncedCount =
                  reports.where((r) => r.syncStatus == SyncStatus.synced).length;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 6.0,
                ),
                children: [
                  // 1. Top "Sync Summary" Card (Equal height & width cards, zero overflow)
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.syncReportsSyncing),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
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
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // 2. Filter Tabs (Evenly distributed across the row, zero horizontal scroll/overflow)
                  Row(
                    children: [
                      Expanded(
                        child: _buildFilterTab(
                          QueueFilter.all,
                          'All',
                          reports.length,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildFilterTab(
                          QueueFilter.pending,
                          'Pending',
                          pendingCount,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildFilterTab(
                          QueueFilter.failed,
                          'Failed',
                          failedCount,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildFilterTab(
                          QueueFilter.synced,
                          'Synced',
                          syncedCount,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. Report Cards List (Home screen matched text sizes)
                  if (filteredReports.isEmpty)
                    _buildEmptyState(context, reports.isEmpty)
                  else
                    ...filteredReports.map(
                      (report) => _buildReportItem(context, report, l10n),
                    ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(QueueFilter filter, String title, int count) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 7.5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF074E95) : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? const Color(0xFF074E95) : const Color(0xFFE2E8F0),
            width: 1.1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF074E95).withValues(alpha: 0.22),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$title ($count)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ),
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
            .where(
              (r) =>
                  r.syncStatus == SyncStatus.pending ||
                  r.syncStatus == SyncStatus.syncing,
            )
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
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Symbols.inbox_rounded,
            size: 48,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            noReportsAtAll
                ? l10n.pendingReportsCount(0)
                : l10n.noReportsMatchFilter,
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            l10n.offlineExplanation,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(
    BuildContext context,
    HazardReport report,
    AppLocalizations l10n,
  ) {
    final kmText = report.kmMarker != null
        ? 'Km ${report.kmMarker!.toStringAsFixed(1)}'
        : 'Km 51.0';
    final rawStation = report.nearestStationName ??
        DhrWaypoints.getSectionName(report.sectionId);
    final stationName =
        rawStation.endsWith('Station') ? rawStation : '$rawStation Station';
    final createdDateText =
        DateFormat('d MMM yyyy, h:mm a').format(report.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/gangman/reports/${report.id}'),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Thumbnail + Titles & Details + Severity Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Thumbnail Image (62x62, matched to compact home design)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 62,
                        height: 62,
                        child: _buildThumbnail(report),
                      ),
                    ),
                    const SizedBox(width: 11),

                    // 2. Hazard Name & Location / Date Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getHazardDisplayTitle(report),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Symbols.location_on_rounded,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  '$kmText, $stationName',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Symbols.calendar_today_rounded,
                                size: 13,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                createdDateText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // 3. Top-Right Severity Badge
                    SeverityBadge(severity: report.confirmedSeverity),
                  ],
                ),
                const SizedBox(height: 10),

                // Thin Horizontal Divider
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 8),

                // Bottom Row: Status Pill (Synced / Pending / Failed) + Chevron Arrow
                Row(
                  children: [
                    _buildStatusPill(report.syncStatus),
                    const Spacer(),
                    const Icon(
                      Symbols.chevron_right_rounded,
                      size: 19,
                      color: Color(0xFF074E95),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getHazardDisplayTitle(HazardReport report) {
    switch (report.confirmedHazardType) {
      case HazardType.damagedWall:
        return 'Damaged\nRetaining Wall';
      case HazardType.rockfall:
        return 'Rockfall /\nFallen Debris';
      case HazardType.slip:
        return 'Landslip /\nMudslide';
      case HazardType.blockedDrain:
        return 'Blocked\nCatchwater Drain';
      case HazardType.trackDefect:
        return 'Track Defect /\nRail Gap';
      case HazardType.vegetation:
        return 'Track Obstruction /\nVegetation';
      case HazardType.other:
        return 'Track Issue /\nOther Hazard';
    }
  }

  Widget _buildStatusPill(SyncStatus status) {
    Color bg;
    Color border;
    Color fg;
    IconData icon;
    String text;

    switch (status) {
      case SyncStatus.synced:
        bg = const Color(0xFFDCFCE7);
        border = const Color(0xFFBBF7D0);
        fg = const Color(0xFF15803D);
        icon = Symbols.check_circle_rounded;
        text = 'Synced';
        break;
      case SyncStatus.pending:
      case SyncStatus.syncing:
        bg = const Color(0xFFFEF9C3);
        border = const Color(0xFFFEF08A);
        fg = const Color(0xFF854D0E);
        icon = Symbols.sync_rounded;
        text = 'Pending';
        break;
      case SyncStatus.failed:
      case SyncStatus.conflict:
        bg = const Color(0xFFFEE2E2);
        border = const Color(0xFFFECACA);
        fg = const Color(0xFF991B1B);
        icon = Symbols.error_rounded;
        text = 'Failed';
        break;
      case SyncStatus.draft:
        bg = const Color(0xFFF1F5F9);
        border = const Color(0xFFE2E8F0);
        fg = const Color(0xFF475569);
        icon = Symbols.edit_document_rounded;
        text = 'Draft';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(HazardReport report) {
    final imagePath = report.thumbnailPhotoPath ?? report.originalPhotoPath;
    final fileExists = imagePath != null && File(imagePath).existsSync();

    if (fileExists) {
      return Image.file(
        File(imagePath),
        width: 62,
        height: 62,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallbackThumbnail(report),
      );
    }

    return _buildFallbackThumbnail(report);
  }

  Widget _buildFallbackThumbnail(HazardReport report) {
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
        gradientColors = const [Color(0xFF1E293B), Color(0xFF0F172A)];
        iconData = Symbols.handyman_rounded;
        break;
      case HazardType.blockedDrain:
        gradientColors = const [Color(0xFF1E3A8A), Color(0xFF1D4ED8)];
        iconData = Symbols.water_drop_rounded;
        break;
      default:
        gradientColors = const [Color(0xFF1E293B), Color(0xFF334155)];
        iconData = Symbols.warning_rounded;
    }

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: 24,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
