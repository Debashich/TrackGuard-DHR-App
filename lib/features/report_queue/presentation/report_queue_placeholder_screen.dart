import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/sync_status.dart';
import '../../../shared/widgets/hazard_icon.dart';
import '../../../shared/widgets/severity_badge.dart';
import '../../reports/domain/report_repository_provider.dart';

class ReportQueueScreen extends ConsumerWidget {
  const ReportQueueScreen({super.key});

  Color _syncColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return AppTheme.statusGreen;
      case SyncStatus.pending:
      case SyncStatus.syncing:
        return AppTheme.statusAmber;
      case SyncStatus.failed:
      case SyncStatus.conflict:
        return AppTheme.statusRed;
      case SyncStatus.draft:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.watch(reportRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pendingQueue)),
      body: FutureBuilder<List<HazardReport>>(
        future: repo.getLocalReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.pendingReportsCount(0),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.offlineExplanation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final syncColor = _syncColor(report.syncStatus);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: HazardIcon(
                    hazardType: report.confirmedHazardType,
                    size: 24,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          HazardIcon.getLocalizedLabel(
                            context,
                            report.confirmedHazardType,
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SeverityBadge(severity: report.confirmedSeverity),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        'Km ${(report.kmMarker ?? 51.0).toStringAsFixed(1)} • ${report.nearestStationName ?? "DHR"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: syncColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: syncColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              report.syncStatus.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: syncColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'ID: ${report.id.substring(0, 8)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    context.push('/gangman/reports/${report.id}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
