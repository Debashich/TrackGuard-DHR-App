import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/utils/date_format_utils.dart';
import '../../l10n/app_localizations.dart';
import '../models/hazard_report.dart';
import '../models/sync_status.dart';
import 'sync_error_banner.dart';
import 'sync_status_badge.dart';

class SyncStatusCard extends StatelessWidget {
  final HazardReport report;
  final VoidCallback? onRetry;

  const SyncStatusCard({super.key, required this.report, this.onRetry});

  String _statusExplanation(AppLocalizations l10n) {
    switch (report.syncStatus) {
      case SyncStatus.synced:
        if (report.syncTimestamp != null) {
          return '${l10n.syncSavedAndSynced}. (${DateFormatUtils.formatSyncTime(report.syncTimestamp!, l10n)})';
        }
        return l10n.syncSavedAndSynced;
      case SyncStatus.pending:
        return '${l10n.syncSavedLocally}. ${l10n.syncWaitingForSignal}.';
      case SyncStatus.syncing:
        return l10n.syncReportsSyncing;
      case SyncStatus.failed:
        return l10n.syncFailedButSafe;
      case SyncStatus.conflict:
        return l10n.syncNeedsAttention;
      case SyncStatus.draft:
        return l10n.syncDraft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final explanation = _statusExplanation(l10n);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.cloud_sync_outlined,
                  size: 18,
                  color: AppTheme.primaryAmber,
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
                SyncStatusBadge(status: report.syncStatus),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              explanation,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
            if (report.syncStatus == SyncStatus.synced &&
                report.syncTimestamp != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppTheme.statusGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.syncLastSuccessful(
                      DateFormatUtils.formatSyncTime(
                        report.syncTimestamp!,
                        l10n,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.statusGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (report.syncStatus == SyncStatus.failed) ...[
              if (report.retryCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Retry attempts: ${report.retryCount}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (report.lastSyncError != null &&
                  report.lastSyncError!.isNotEmpty) ...[
                const SizedBox(height: 8),
                SyncErrorBanner(error: report.lastSyncError, onRetry: onRetry),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
