import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/utils/date_format_utils.dart';
import '../../l10n/app_localizations.dart';
import '../models/sync_summary.dart';

class SyncSummaryCard extends StatelessWidget {
  final SyncSummary summary;
  final VoidCallback? onSyncNow;
  final VoidCallback? onViewQueue;
  final bool isSyncing;

  const SyncSummaryCard({
    super.key,
    required this.summary,
    this.onSyncNow,
    this.onViewQueue,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOnline = summary.isOnline;
    final currentlySyncing = isSyncing || summary.isSyncing;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Title + Connectivity Badge
            Row(
              children: [
                Icon(
                  isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: isOnline
                      ? AppTheme.statusGreen
                      : AppTheme.primaryAmber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.syncSummaryTitle.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryAmber,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (isOnline ? AppTheme.statusGreen : AppTheme.borderDark)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: (isOnline ? AppTheme.statusGreen : AppTheme.borderDark)
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline
                              ? AppTheme.statusGreen
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline
                            ? l10n.syncStationSignalAvailable.toUpperCase()
                            : l10n.offlineStatus
                                  .split('-')
                                  .first
                                  .trim()
                                  .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isOnline
                              ? AppTheme.statusGreen
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Statistics Metrics Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Pending',
                    count: summary.pendingCount,
                    icon: Icons.schedule_rounded,
                    color: AppTheme.primaryAmber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Failed',
                    count: summary.failedCount,
                    icon: Icons.error_outline_rounded,
                    color: summary.failedCount > 0
                        ? AppTheme.statusRed
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Synced',
                    count: summary.syncedCount,
                    icon: Icons.check_circle_outline_rounded,
                    color: AppTheme.statusGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dynamic Context Message
            if (currentlySyncing) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF64B5F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF64B5F6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.syncReportsSyncing,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!isOnline) ...[
              Text(
                l10n.syncOfflineSafe,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
            ] else if (summary.failedCount > 0) ...[
              Text(
                l10n.syncFailedButSafe,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.statusOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (summary.allSynced) ...[
              Row(
                children: [
                  const Icon(
                    Icons.cloud_done,
                    size: 14,
                    color: AppTheme.statusGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.syncAllReportsSynced,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.statusGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                l10n.syncPendingReports(summary.pendingCount),
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],

            // Last successful sync timestamp if available
            if (summary.lastSuccessfulSync != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.syncLastSuccessful(
                  DateFormatUtils.formatSyncTime(
                    summary.lastSuccessfulSync!,
                    l10n,
                  ),
                ),
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],

            // Action Buttons Row (Sync Now / View Queue)
            if (onSyncNow != null || onViewQueue != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onViewQueue != null)
                    TextButton(
                      onPressed: onViewQueue,
                      child: Text(
                        l10n.viewQueue,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (onSyncNow != null &&
                      isOnline &&
                      summary.hasPendingOrFailed) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: currentlySyncing ? null : onSyncNow,
                      icon: const Icon(Icons.sync, size: 16),
                      label: Text(l10n.syncNow),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAmber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        minimumSize: const Size(48, 36),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDarkElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
