import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/dhr_waypoints.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../shared/models/ai_analysis_result.dart';
import '../../../shared/models/ai_provider.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/hazard_type.dart';
import '../../../shared/models/inspection_status.dart';
import '../../../shared/models/report_draft.dart';
import '../../../shared/models/severity.dart';
import '../../../shared/models/sync_status.dart';
import '../../ai/domain/ai_service_provider.dart';
import '../../ai/domain/ai_settings.dart';
import '../../reports/domain/report_repository_provider.dart';

class ReportReviewState {
  final ReportDraft? draft;
  final bool isLoadingDraft;
  final bool isAnalyzing;
  final AiAnalysisResult? aiResult;
  final HazardType confirmedHazard;
  final Severity confirmedSeverity;
  final double kmMarker;
  final String gangmanNote;
  final bool isSaving;
  final String? savedReportId;
  final String? errorMessage;
  final String? aiErrorMessage;

  const ReportReviewState({
    this.draft,
    this.isLoadingDraft = true,
    this.isAnalyzing = false,
    this.aiResult,
    this.confirmedHazard = HazardType.other,
    this.confirmedSeverity = Severity.medium,
    this.kmMarker = 51.0,
    this.gangmanNote = '',
    this.isSaving = false,
    this.savedReportId,
    this.errorMessage,
    this.aiErrorMessage,
  });

  ReportReviewState copyWith({
    ReportDraft? draft,
    bool? isLoadingDraft,
    bool? isAnalyzing,
    AiAnalysisResult? aiResult,
    HazardType? confirmedHazard,
    Severity? confirmedSeverity,
    double? kmMarker,
    String? gangmanNote,
    bool? isSaving,
    String? savedReportId,
    String? errorMessage,
    String? aiErrorMessage,
    bool clearAiError = false,
  }) {
    return ReportReviewState(
      draft: draft ?? this.draft,
      isLoadingDraft: isLoadingDraft ?? this.isLoadingDraft,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      aiResult: aiResult ?? this.aiResult,
      confirmedHazard: confirmedHazard ?? this.confirmedHazard,
      confirmedSeverity: confirmedSeverity ?? this.confirmedSeverity,
      kmMarker: kmMarker ?? this.kmMarker,
      gangmanNote: gangmanNote ?? this.gangmanNote,
      isSaving: isSaving ?? this.isSaving,
      savedReportId: savedReportId ?? this.savedReportId,
      errorMessage: errorMessage,
      aiErrorMessage: clearAiError ? null : (aiErrorMessage ?? this.aiErrorMessage),
    );
  }
}

class ReportReviewController extends Notifier<ReportReviewState> {
  static const _uuid = Uuid();

  @override
  ReportReviewState build() {
    Future.microtask(() => loadDraftAndAnalyze());
    return const ReportReviewState();
  }

  Future<void> loadDraftAndAnalyze() async {
    state = state.copyWith(isLoadingDraft: true);
    final repo = ref.read(reportRepositoryProvider);
    final draft = await repo.getDraft();

    if (draft == null) {
      state = state.copyWith(
        isLoadingDraft: false,
        errorMessage: 'Inspection draft not found.',
      );
      return;
    }

    final initialKm = draft.location.kmMarker ?? 51.0;
    state = state.copyWith(
      draft: draft,
      isLoadingDraft: false,
      kmMarker: initialKm,
    );

    await runAnalysis();
  }

  Future<void> runAnalysis([AiMode? requestedMode]) async {
    final draft = state.draft;
    if (draft == null) return;

    state = state.copyWith(isAnalyzing: true, clearAiError: true);
    final aiService = ref.read(aiAnalysisServiceProvider);
    final language = ref.read(appLanguageProvider);
    final mode = requestedMode ?? ref.read(aiSettingsProvider).mode;

    try {
      final result = await aiService.analyze(
        image: File(draft.photoPath),
        location: draft.location,
        language: language,
        requestedMode: mode,
      );

      state = state.copyWith(
        isAnalyzing: false,
        aiResult: result,
        clearAiError: true,
        confirmedHazard: result.hazardType ?? state.confirmedHazard,
        confirmedSeverity: result.severity ?? state.confirmedSeverity,
      );
    } catch (e) {
      debugPrint('AI Analysis Failed: $e');
      state = state.copyWith(
        isAnalyzing: false,
        aiResult: null,
        aiErrorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void switchToManual() {
    runAnalysis(AiMode.manual);
  }

  void setConfirmedHazard(HazardType hazard) {
    state = state.copyWith(confirmedHazard: hazard);
  }

  void setConfirmedSeverity(Severity severity) {
    state = state.copyWith(confirmedSeverity: severity);
  }

  void setKmMarker(double km) {
    state = state.copyWith(kmMarker: km);
  }

  void setGangmanNote(String note) {
    state = state.copyWith(gangmanNote: note);
  }

  Future<bool> confirmAndSaveReport(String createdByUserId) async {
    final draft = state.draft;
    if (draft == null) return false;

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final reportId = _uuid.v4();
      final now = DateTime.now();
      final loc = draft.location;
      final sectionId = DhrWaypoints.estimateSection(state.kmMarker);

      final report = HazardReport(
        id: reportId,
        createdBy: createdByUserId,
        createdAt: now,
        updatedAt: now,
        latitude: loc.latitude,
        longitude: loc.longitude,
        gpsAccuracyMeters: loc.accuracyMeters,
        locationSource: loc.source,
        locationCapturedAt: loc.capturedAt,
        distanceToAlignmentKm: loc.distanceToAlignmentKm,
        kmMarker: state.kmMarker,
        sectionId: sectionId,
        nearestStationName: loc.nearestStationName,
        confirmedHazardType: state.confirmedHazard,
        confirmedSeverity: state.confirmedSeverity,
        userNote: state.gangmanNote.trim(),
        aiSuggestedHazardType: state.aiResult?.hazardType,
        aiSuggestedSeverity: state.aiResult?.severity,
        aiNote: state.aiResult?.note,
        aiProvider: state.aiResult?.provider ?? AiProvider.manual,
        aiModel: state.aiResult?.modelName,
        aiLanguage: state.aiResult?.language,
        aiConfidence: state.aiResult?.confidence,
        inspectionStatus: InspectionStatus.open,
        syncStatus: SyncStatus.pending,
        syncVersion: 1,
        retryCount: 0,
        originalPhotoPath: draft.photoPath,
        thumbnailPhotoPath: draft.thumbnailPath,
      );

      final repo = ref.read(reportRepositoryProvider);

      // Save locally first so a network failure never loses the report.
      await repo.saveReport(report);
      await repo.clearDraft();

      ref.invalidate(pendingReportsCountProvider);

      // Attempt remote sync if Supabase is configured and authenticated.
      try {
        final client = ref.read(supabaseClientProvider);

        debugPrint('Supabase client available: ${client != null}');
        debugPrint(
          'Supabase user: ${client?.auth.currentUser?.id ?? "NOT SIGNED IN"}',
        );

        final syncService = ref.read(reportSyncServiceProvider);
        debugPrint('Sync service available: ${syncService != null}');

        if (syncService != null) {
          await syncService.syncPendingReports();
          debugPrint('Sync attempt completed');
        }
      } catch (error, stackTrace) {
        debugPrint('Report sync failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      ref.invalidate(pendingReportsCountProvider);

      state = state.copyWith(isSaving: false, savedReportId: reportId);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save report locally: $e',
      );
      return false;
    }
  }
}

final reportReviewControllerProvider =
    NotifierProvider<ReportReviewController, ReportReviewState>(() {
      return ReportReviewController();
    });
