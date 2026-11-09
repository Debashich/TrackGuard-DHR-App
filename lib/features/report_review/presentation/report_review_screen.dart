import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/constants/dhr_waypoints.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/hazard_type.dart';
import '../../../shared/models/location_source.dart';
import '../../../shared/models/severity.dart';
import '../../../shared/models/sync_status.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/sync_status_badge.dart';
import '../../../shared/widgets/trackguard_dialog.dart';
import '../../ai/domain/ai_settings.dart';
import '../../auth/presentation/auth_controller.dart';
import 'report_review_controller.dart';
import 'widgets/ai_suggestion_card.dart';
import 'widgets/hazard_selector.dart';
import 'widgets/severity_selector.dart';

enum _ReviewExitAction { discard }

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
    Future.microtask(
      () => ref
          .read(reportReviewControllerProvider.notifier)
          .loadDraftAndAnalyze(),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _kmController.dispose();
    super.dispose();
  }

  Future<bool> _handleBackPressed() async {
    final reviewState = ref.read(reportReviewControllerProvider);

    if (reviewState.draft == null) return true;
    if (reviewState.isSaving) return false;

    final action = await showDialog<_ReviewExitAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => TrackGuardDialog(
        icon: Icons.edit_note_rounded,
        iconBgColor: TrackGuardDialog.brandBlueSoft,
        iconColor: TrackGuardDialog.brandBlue,
        title: 'Leave report?',
        message: 'You have an unfinished report. Would you like to discard it?',
        primaryLabel: 'Discard Report',
        primaryIcon: Icons.delete_outline_rounded,
        primaryColor: TrackGuardDialog.red,
        onPrimaryPressed: () =>
            Navigator.of(dialogContext).pop(_ReviewExitAction.discard),
        cancelLabel: 'Keep Editing',
        onCancelPressed: () => Navigator.of(dialogContext).pop(),
      ),
    );

    if (!mounted || action == null) return false;

    final controller = ref.read(reportReviewControllerProvider.notifier);

    final discarded = await controller.discardDraft();
    if (!mounted) return false;
    if (!discarded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not discard report. Please try again.'),
        ),
      );
      return false;
    }

    context.go('/gangman/home');
    return false;
  }

  void _showSuccessDialog(BuildContext context, String reportId) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TrackGuardDialog(
        icon: Symbols.check_circle_rounded,
        iconBgColor: TrackGuardDialog.greenSoft,
        iconColor: TrackGuardDialog.green,
        title: l10n.savedSuccessTitle,
        message: l10n.savedSuccessMessage(reportId.substring(0, 8)),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        primaryLabel: l10n.viewQueue,
        primaryIcon: Icons.list_alt_rounded,
        primaryColor: TrackGuardDialog.brandBlue,
        onPrimaryPressed: () {
          Navigator.of(ctx).pop();
          context.go('/gangman/reports');
        },
        cancelLabel: l10n.backToHome,
        onCancelPressed: () {
          Navigator.of(ctx).pop();
          context.go('/gangman/home');
        },
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
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            l10n.reviewTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          centerTitle: true,
        ),
        body: LoadingView(message: l10n.processingImage),
      );
    }

    if (reviewState.draft == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            l10n.reviewTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          centerTitle: true,
        ),
        body: ErrorView(
          title: l10n.draftMissing,
          message:
              reviewState.errorMessage ?? l10n.inspectionDraftCouldNotBeLoaded,
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

    if (_noteController.text.isEmpty && reviewState.gangmanNote.isNotEmpty) {
      _noteController.text = reviewState.gangmanNote;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _handleBackPressed();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        },
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
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(
                Symbols.arrow_back_rounded,
                color: Color(0xFF0F172A),
                size: 22,
              ),
              tooltip: 'Back',
              onPressed: () async {
                final shouldPop = await _handleBackPressed();
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: const Text(
              'Review & Confirm Report',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            centerTitle: true,
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info banner: Saves safely on your phone first
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Symbols.phone_android_rounded,
                          size: 16,
                          color: Color(0xFF074E95),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Saves safely on your phone first.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Confirm & Save Locally Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF074E95),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: reviewState.isSaving
                          ? null
                          : () async {
                              final success = await controller
                                  .confirmAndSaveReport(userId);
                              if (!context.mounted) return;
                              final savedId = ref
                                  .read(reportReviewControllerProvider)
                                  .savedReportId;
                              if (success && savedId != null) {
                                _showSuccessDialog(context, savedId);
                              }
                            },
                      child: reviewState.isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Symbols.save_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Confirm & Save Locally',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
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
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photo Card Preview with Source Badge
                  Container(
                    height: 210,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(draft.photoPath), fit: BoxFit.cover),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xCC0F172A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Symbols.location_on_rounded,
                                  color: Color(0xFF22C55E),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  loc.source == LocationSource.gps
                                      ? 'Source: Real GPS'
                                      : 'Source: Fallback Location',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Location Details Card
                  Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Symbols.location_on_rounded,
                            color: Color(0xFF074E95),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.nearestStationName ?? 'Kurseong Station',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Km ${reviewState.kmMarker.toStringAsFixed(1)} • ${DhrWaypoints.getSectionName(DhrWaypoints.estimateSection(reviewState.kmMarker))}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // AI Suggestion Card
                  AiSuggestionCard(
                    aiResult: reviewState.aiResult,
                    errorMessage: reviewState.aiErrorMessage,
                    isAnalyzing: reviewState.isAnalyzing,
                    currentMode: ref.watch(aiSettingsProvider).mode,
                    onRetry: () => controller.runAnalysis(),
                    onSwitchToManual: () => controller.switchToManual(),
                    onDownloadModel: () =>
                        context.push('/settings/ai/download'),
                  ),
                  const SizedBox(height: 14),

                  // Field Verification Form Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form Header: [shield] Field Verification   [REQUIRED]
                        Row(
                          children: [
                            const Icon(
                              Symbols.verified_user_rounded,
                              color: Color(0xFF074E95),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Field Verification',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFECACA),
                                ),
                              ),
                              child: const Text(
                                'REQUIRED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFDC2626),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 14),

                        // 1. HAZARD CLASSIFICATION
                        const Text(
                          '1. HAZARD CLASSIFICATION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        HazardSelector(
                          selectedHazard: reviewState.confirmedHazard,
                          onSelected: (HazardType h) =>
                              controller.setConfirmedHazard(h),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 14),

                        // 2. VERIFIED SEVERITY TIER
                        const Text(
                          '2. VERIFIED SEVERITY TIER',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SeveritySelector(
                          selectedSeverity: reviewState.confirmedSeverity,
                          onSelected: (Severity s) =>
                              controller.setConfirmedSeverity(s),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 14),

                        // 3. KILOMETER MARKER
                        Row(
                          children: [
                            const Text(
                              '3. KILOMETER MARKER',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                                letterSpacing: 0.4,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F1FA),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: const Text(
                                'AUTO-MATCHED GPS',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF074E95),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _kmController,
                          onTapOutside: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          onSubmitted: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            prefixIcon: const Icon(
                              Symbols.location_on_rounded,
                              color: Color(0xFF074E95),
                              size: 20,
                            ),
                            suffixText: 'km',
                            suffixStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF074E95),
                                width: 1.5,
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val);
                            if (parsed != null) {
                              controller.setKmMarker(parsed);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 14),

                        // 4. FIELD OBSERVATION NOTE
                        const Text(
                          '4. FIELD OBSERVATION NOTE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _noteController,
                          onTapOutside: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          maxLines: 3,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF0F172A),
                            height: 1.35,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            hintText: 'e.g. Outer bolt missing, 2 sleepers loose, track clear...',
                            hintStyle: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF94A3B8),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF074E95),
                                width: 1.5,
                              ),
                            ),
                          ),
                          onChanged: (val) => controller.setGangmanNote(val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Offline / Connectivity readiness banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOnline
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOnline
                              ? Symbols.wifi_rounded
                              : Symbols.wifi_off_rounded,
                          size: 20,
                          color: isOnline
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isOnline
                                ? l10n.syncStationSignalAvailable
                                : l10n.syncOfflineSafe,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOnline
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFB45309),
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
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Symbols.error_rounded,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              reviewState.errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
