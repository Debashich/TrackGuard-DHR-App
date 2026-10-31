import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/constants/dhr_waypoints.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/hazard_type.dart';
import '../../../shared/models/location_source.dart';
import '../../../shared/models/severity.dart';
import '../../../shared/models/sync_status.dart';
import '../../../shared/widgets/ai_metadata_card.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/sync_status_badge.dart';
import '../../ai/domain/ai_settings.dart';
import '../../auth/presentation/auth_controller.dart';
import 'report_review_controller.dart';
import 'widgets/ai_suggestion_card.dart';
import 'widgets/hazard_selector.dart';
import 'widgets/severity_selector.dart';

class ReportReviewScreen extends ConsumerStatefulWidget {
  const ReportReviewScreen({super.key});

  @override
  ConsumerState<ReportReviewScreen> createState() => _ReportReviewScreenState();
}

class _ReportReviewScreenState extends ConsumerState<ReportReviewScreen> {
  late TextEditingController _noteController;
  late TextEditingController _kmController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _kmController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _kmController.dispose();
    super.dispose();
  }

  void _showSuccessDialog(BuildContext context, String reportId) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppTheme.statusGreen,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.savedSuccessTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.savedSuccessMessage(reportId.substring(0, 8)),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDarkElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [SyncStatusBadge(status: SyncStatus.pending)],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.syncWaitingForSignal,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/gangman/home');
            },
            child: Text(l10n.backToHome),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/gangman/reports');
            },
            child: Text(l10n.viewQueue),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reviewState = ref.watch(reportReviewControllerProvider);
    final controller = ref.read(reportReviewControllerProvider.notifier);
    final authState = ref.watch(authControllerProvider);
    final userId = authState.user?.id ?? 'dhr-gangman-001';
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.value ?? false;

    if (reviewState.isLoadingDraft) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.reviewTitle)),
        body: LoadingView(message: l10n.processingImage),
      );
    }

    if (reviewState.draft == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.reviewTitle)),
        body: ErrorView(
          title: 'Draft Missing',
          message:
              reviewState.errorMessage ??
              'Inspection draft could not be loaded.',
          onRetry: () => controller.loadDraftAndAnalyze(),
        ),
      );
    }

    final draft = reviewState.draft!;
    final loc = draft.location;

    // Synchronize initial text fields once if empty
    if (_kmController.text.isEmpty) {
      _kmController.text = reviewState.kmMarker.toStringAsFixed(1);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Thumbnail Preview Card
              Card(
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(draft.photoPath), fit: BoxFit.cover),
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
                          child: Text(
                            loc.source == LocationSource.gps
                                ? l10n.locationSourceGps
                                : l10n.locationSourceFallback,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: loc.source == LocationSource.gps
                                  ? AppTheme.statusGreen
                                  : AppTheme.primaryAmber,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Location details card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.place,
                        color: AppTheme.primaryAmber,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.nearestStationName ??
                                  'Darjeeling Himalayan Railway',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Km ${reviewState.kmMarker.toStringAsFixed(1)} • ${DhrWaypoints.getSectionName(DhrWaypoints.estimateSection(reviewState.kmMarker))}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // AI Suggestion Card
              AiSuggestionCard(
                aiResult: reviewState.aiResult,
                errorMessage: reviewState.aiErrorMessage,
                isAnalyzing: reviewState.isAnalyzing,
                currentMode: ref.watch(aiSettingsProvider).mode,
                onRetry: () => controller.runAnalysis(),
                onSwitchToManual: () => controller.switchToManual(),
                onDownloadModel: () => context.push('/settings/ai/download'),
              ),
              if (reviewState.aiResult != null && !reviewState.isAnalyzing) ...[
                const SizedBox(height: 12),
                AiMetadataCard(result: reviewState.aiResult),
              ],
              const SizedBox(height: 20),

              // Human Confirmation Section Header
              Text(
                l10n.humanConfirmationTitle.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryAmber,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),

              // Hazard Type Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.hazardType,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      HazardSelector(
                        selectedHazard: reviewState.confirmedHazard,
                        onSelected: (HazardType h) =>
                            controller.setConfirmedHazard(h),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Severity Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.severity,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SeveritySelector(
                        selectedSeverity: reviewState.confirmedSeverity,
                        onSelected: (Severity s) =>
                            controller.setConfirmedSeverity(s),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Km Marker & Gangman field note
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _kmController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.editKm,
                          prefixIcon: const Icon(
                            Icons.linear_scale,
                            color: AppTheme.primaryAmber,
                          ),
                          suffixText: 'km',
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) {
                            controller.setKmMarker(parsed);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l10n.gangmanNote,
                          hintText: l10n.gangmanNoteHint,
                          alignLabelWithHint: true,
                        ),
                        onChanged: (val) => controller.setGangmanNote(val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Offline / Sync readiness banner before saving
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOnline ? Icons.wifi : Icons.wifi_off,
                      size: 20,
                      color: isOnline
                          ? AppTheme.statusGreen
                          : AppTheme.primaryAmber,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isOnline
                            ? l10n.syncStationSignalAvailable
                            : l10n.syncOfflineSafe,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Show local save error if any
              if (reviewState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.statusRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.statusRed),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.statusRed,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          reviewState.errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Confirm and Save Button
              PrimaryButton(
                text: l10n.saveAndQueue.toUpperCase(),
                icon: Icons.save,
                isLoading: reviewState.isSaving,
                onPressed: reviewState.isSaving
                    ? null
                    : () async {
                        final success = await controller.confirmAndSaveReport(
                          userId,
                        );
                        if (!context.mounted) return;
                        final savedId = ref
                            .read(reportReviewControllerProvider)
                            .savedReportId;
                        if (success && savedId != null) {
                          _showSuccessDialog(context, savedId);
                        }
                      },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
