import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/dhr_waypoints.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/widgets/hazard_icon.dart';
import '../../../shared/widgets/severity_badge.dart';
import '../../reports/domain/report_repository_provider.dart';

class GangmanReportDetailScreen extends ConsumerWidget {
  final String reportId;

  const GangmanReportDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(reportRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Report ${reportId.length >= 8 ? reportId.substring(0, 8) : reportId}',
        ),
      ),
      body: FutureBuilder<HazardReport?>(
        future: repo.getReportById(reportId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final report = snapshot.data;
          if (report == null) {
            return const Center(
              child: Text(
                'Report not found',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Original Photo
                if (report.originalPhotoPath != null)
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

                // Status & Sync State Banner
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.primaryAmber.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        'STATUS: ${report.inspectionStatus.name.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryAmber,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDarkElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: Text(
                        'SYNC: ${report.syncStatus.name.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Confirmed Classification Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CONFIRMED CLASSIFICATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryAmber,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            HazardIcon(
                              hazardType: report.confirmedHazardType,
                              size: 24,
                              showLabel: true,
                            ),
                            const Spacer(),
                            SeverityBadge(
                              severity: report.confirmedSeverity,
                              isLarge: true,
                            ),
                          ],
                        ),
                        if (report.userNote.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          const Text(
                            "Gangman's Note:",
                            style: TextStyle(
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
                          'Section: ${DhrWaypoints.getSectionName(report.sectionId)}',
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

                // AI Suggestion Audit Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.psychology,
                              size: 18,
                              color: AppTheme.primaryAmber,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'AI SUGGESTION AUDIT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryAmber,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              report.aiProvider.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (report.aiSuggestedHazardType != null)
                          Text(
                            'Suggested: ${report.aiSuggestedHazardType!.name} (${report.aiSuggestedSeverity?.name ?? "unknown"})',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        if (report.aiNote != null &&
                            report.aiNote!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            report.aiNote!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
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
