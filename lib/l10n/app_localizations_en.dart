// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TrackGuard DHR';

  @override
  String get tagline => 'Darjeeling Himalayan Railway Alignment Inspection';

  @override
  String get gangman => 'Gangman';

  @override
  String get admin => 'Supervisor / Admin';

  @override
  String get signInTitle => 'TrackGuard DHR Sign In';

  @override
  String get signInSubtitle => 'Permanent-Way Inspection & Hazard Reporting';

  @override
  String get signInGoogle => 'Sign In with Google';

  @override
  String get offlineFieldLogin => 'Field Inspection (Offline Mode)';

  @override
  String get offlineFieldLoginSubtitle =>
      'Use on-device Gemma AI • No internet required';

  @override
  String get offlineModeBadge => 'Offline Mode (No Internet)';

  @override
  String get onlineModeBadge => 'Online (Cloud Sync Ready)';

  @override
  String get devSignInGangman => 'Developer Sign In (Gangman)';

  @override
  String get devSignInAdmin => 'Developer Sign In (Admin)';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get signOut => 'Sign Out';

  @override
  String signedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get pendingAccessTitle => 'Access Approval Pending';

  @override
  String get pendingAccessMessage =>
      'Your account has been registered. An authorized permanent-way supervisor must approve your profile before you can access field tools.';

  @override
  String get inactiveAccountMessage =>
      'Your account is marked inactive. Please contact your section engineer.';

  @override
  String get checkStatus => 'Check Status';

  @override
  String get homeTitle => 'Inspection Dashboard';

  @override
  String get newReport => 'New Report';

  @override
  String get myReports => 'My Reports';

  @override
  String get pendingQueue => 'Pending Sync Queue';

  @override
  String pendingReportsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports pending',
      one: '1 report pending',
      zero: '0 reports pending',
    );
    return '$_temp0';
  }

  @override
  String assignedSection(String section) {
    return 'Assigned Section: $section';
  }

  @override
  String get unassignedSection => 'No section assigned';

  @override
  String get onlineStatus => 'Online - Cloud Sync Ready';

  @override
  String get offlineStatus => 'Offline - Local Queue Active';

  @override
  String get aiStatusReady => 'AI Analysis: Ready (Offline)';

  @override
  String get aiStatusHeuristic => 'AI Analysis: Heuristic Fallback';

  @override
  String get aiStatusUnavailable => 'AI Analysis: Manual Only';

  @override
  String get offlineExplanation =>
      'All inspection reports are saved to your device immediately. When you reach a station with connectivity, queued reports will sync automatically.';

  @override
  String get captureTitle => 'Capture Hazard Photo';

  @override
  String get cameraPermissionTitle => 'Camera Permission Required';

  @override
  String get cameraPermissionMessage =>
      'TrackGuard needs camera access to capture track hazards and retaining wall defects.';

  @override
  String get locationPermissionTitle => 'Location Permission Required';

  @override
  String get locationPermissionMessage =>
      'Precise GPS location is needed to estimate alignment kilometre markers and track sections.';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get takePhoto => 'Capture Photo';

  @override
  String get retake => 'Retake';

  @override
  String get confirmPhoto => 'Use Photo';

  @override
  String get switchCamera => 'Switch Camera';

  @override
  String get galleryFallback => 'Select from Gallery';

  @override
  String get cameraUnavailable =>
      'Camera unavailable. Please use gallery fallback.';

  @override
  String get processingImage => 'Processing image...';

  @override
  String get locationTitle => 'Location & Alignment';

  @override
  String get gpsAcquiring => 'Acquiring GPS fix...';

  @override
  String gpsLocked(String accuracy) {
    return 'GPS Locked (±${accuracy}m)';
  }

  @override
  String get gpsUnavailable => 'GPS Signal Unavailable';

  @override
  String get locationSourceGps => 'Source: Real GPS';

  @override
  String get locationSourceManual => 'Source: Manual Selection';

  @override
  String get locationSourceFallback => 'Source: Estimated Fallback';

  @override
  String kmMarker(String marker) {
    return 'Km $marker';
  }

  @override
  String nearestStation(String station) {
    return 'Nearest Station: $station';
  }

  @override
  String get selectWaypoint => 'Select Nearest DHR Station / Waypoint';

  @override
  String stationName(String stationId) {
    String _temp0 = intl.Intl.selectLogic(stationId, {
      'kurseong': 'Kurseong Station',
      'tung': 'Tung Station',
      'dilaram': 'Dilaram Point',
      'sonada': 'Sonada Station',
      'rongbull': 'Rongbull Loop',
      'jorebungalow': 'Jorebungalow',
      'ghum': 'Ghum Station',
      'batasia': 'Batasia Loop',
      'darjeeling': 'Darjeeling Station',
      'other': 'stationId',
    });
    return '$_temp0';
  }

  @override
  String get editKm => 'Edit Km Marker';

  @override
  String get manualLocationNotice =>
      'Warning: Fallback coordinates are estimated. Adjust km marker manually if needed.';

  @override
  String get reviewTitle => 'Review & Confirm Report';

  @override
  String get aiSuggestionTitle => 'AI Advisory Suggestion';

  @override
  String get aiDisclaimer =>
      'AI suggestions are advisory only. Permanent-way staff must inspect and confirm the actual hazard and severity before saving.';

  @override
  String get aiAnalyzing => 'Analyzing image with on-device intelligence...';

  @override
  String aiSuggestedHazard(String hazard) {
    return 'Suggested Hazard: $hazard';
  }

  @override
  String aiSuggestedSeverity(String severity) {
    return 'Suggested Severity: $severity';
  }

  @override
  String aiNote(String note) {
    return 'AI Observation: $note';
  }

  @override
  String get humanConfirmationTitle => 'Human Confirmation (Required)';

  @override
  String get hazardType => 'Hazard Type';

  @override
  String get severity => 'Severity';

  @override
  String get gangmanNote => 'Gangman\'s Field Note';

  @override
  String get gangmanNoteHint =>
      'Describe obstruction, track clearance, or slope movement...';

  @override
  String get saveAndQueue => 'Confirm & Save Locally';

  @override
  String get saving => 'Saving report locally...';

  @override
  String get savedSuccessTitle => 'Report Saved Locally!';

  @override
  String savedSuccessMessage(String id) {
    return 'Report saved with ID: $id. It has been added to the local queue and will sync when station connectivity is reached.';
  }

  @override
  String get backToHome => 'Back to Home';

  @override
  String get viewQueue => 'View Queue';

  @override
  String get hazardSlip => 'Landslip / Mudslide';

  @override
  String get hazardRockfall => 'Rockfall / Fallen Debris';

  @override
  String get hazardBlockedDrain => 'Blocked Catchwater Drain';

  @override
  String get hazardDamagedWall => 'Damaged Retaining Wall';

  @override
  String get hazardTrackDefect => 'Track Defect / Gauge Spread';

  @override
  String get hazardVegetation => 'Vegetation Overgrowth';

  @override
  String get hazardOther => 'Other Hazard';

  @override
  String get severityLow => 'Low - Monitor';

  @override
  String get severityMedium => 'Medium - Maintenance Needed';

  @override
  String get severityHigh => 'High - Speed Restriction Required';

  @override
  String get severityCritical => 'Critical - Track Obstruction / Danger';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusAcknowledged => 'Acknowledged';

  @override
  String get statusInspectionRequired => 'Inspection Required';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get syncDraft => 'Draft';

  @override
  String get syncPending => 'Pending Sync';

  @override
  String get syncSyncing => 'Syncing...';

  @override
  String get syncSynced => 'Synced to Server';

  @override
  String get syncFailed => 'Sync Failed';

  @override
  String get syncConflict => 'Conflict';

  @override
  String get syncStatusDraft => 'Draft';

  @override
  String get syncStatusPending => 'Pending Sync';

  @override
  String get syncStatusSyncing => 'Syncing...';

  @override
  String get syncStatusSynced => 'Synced';

  @override
  String get syncStatusFailed => 'Sync Failed';

  @override
  String get syncStatusConflict => 'Conflict';

  @override
  String get syncSummaryTitle => 'Sync Summary';

  @override
  String syncPendingReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports waiting to sync',
      one: '1 report waiting to sync',
      zero: '0 reports waiting',
    );
    return '$_temp0';
  }

  @override
  String syncFailedReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports failed',
      one: '1 report failed',
      zero: '0 reports failed',
    );
    return '$_temp0';
  }

  @override
  String get syncReportsSyncing => 'Syncing reports...';

  @override
  String get syncAllReportsSynced => 'All reports synced';

  @override
  String syncLastSuccessful(String time) {
    return 'Last synced: $time';
  }

  @override
  String get syncNoSuccessfulSync => 'Not synced yet';

  @override
  String get syncOfflineSafe =>
      'Offline — reports remain safely stored on this device.';

  @override
  String get syncWaitingForSignal => 'Offline — waiting for station signal';

  @override
  String get syncStationSignalAvailable => 'Station signal available';

  @override
  String get syncSavedLocally => 'Saved locally on this device';

  @override
  String get syncSavedAndSynced => 'Saved and synced to server';

  @override
  String get syncFailedButSafe =>
      'Some reports could not sync. They remain safe locally.';

  @override
  String get syncNeedsAttention => 'This report needs attention';

  @override
  String get syncErrorOffline =>
      'No network connection. The report is safely stored on this device.';

  @override
  String get syncErrorTimeout =>
      'The station connection took too long. The report remains saved locally.';

  @override
  String get syncErrorServerUnavailable =>
      'The control service is temporarily unavailable. Please try again later.';

  @override
  String get syncErrorUnauthorized =>
      'Your access has expired or is unauthorized. Sign in again when connectivity is available.';

  @override
  String get syncErrorMediaUpload =>
      'The report details were prepared, but the photo could not be uploaded yet.';

  @override
  String get syncErrorConflict =>
      'This report was changed elsewhere and needs review.';

  @override
  String get syncErrorUnknown =>
      'The report could not be synchronized. It remains safely stored locally.';

  @override
  String get aiProviderOfflineGemma => 'Offline Gemma';

  @override
  String get aiProviderHeuristic => 'Heuristic Rules';

  @override
  String get aiProviderManual => 'Manual Classification';

  @override
  String get aiProviderOnlineGemini => 'Online Gemini';

  @override
  String get aiModelLabel => 'AI Model';

  @override
  String get aiProviderLabel => 'AI Provider';

  @override
  String get aiLanguageLabel => 'AI Language';

  @override
  String get aiConfidenceLabel => 'Confidence';

  @override
  String get aiAdvisoryNotice =>
      'AI suggestion is advisory only. Gangman inspection confirmed.';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get syncSuccessMessage => 'Synchronization completed successfully';

  @override
  String get retrySync => 'Retry Sync';

  @override
  String get viewSyncDetails => 'View Details';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get allFilter => 'All';

  @override
  String get noReportsMatchFilter => 'No reports match the selected filter.';

  @override
  String get profileTitle => 'User Profile';

  @override
  String get profileName => 'Full Name';

  @override
  String get profileEmail => 'Email Address';

  @override
  String get profileRole => 'Role';

  @override
  String get profileAssignedSection => 'Assigned Section';

  @override
  String get profileLanguage => 'Preferred Language';

  @override
  String get profileAccountStatus => 'Account Status';

  @override
  String get profileActive => 'Active';

  @override
  String get profileInactive => 'Inactive';

  @override
  String get profileBackToHome => 'Return to Dashboard';

  @override
  String get roleGangman => 'Gangman';

  @override
  String get roleAdmin => 'Supervisor / Admin';

  @override
  String get navigationHome => 'Home';

  @override
  String get navigationMyReports => 'My Reports';

  @override
  String get navigationDashboard => 'Dashboard';

  @override
  String get navigationProfile => 'Profile';

  @override
  String get navigationLogout => 'Sign Out';

  @override
  String get navigationReports => 'Reports';

  @override
  String get navigationUsers => 'Users';

  @override
  String get navigationBack => 'Back';

  @override
  String get navigationRefresh => 'Refresh';

  @override
  String get logoutTitle => 'Confirm Sign Out';

  @override
  String get logoutConfirmation =>
      'Are you sure you want to sign out of your account?';

  @override
  String get logoutConfirm => 'Sign Out';

  @override
  String get logoutCancel => 'Stay Signed In';

  @override
  String get logoutSigningOut => 'Signing out...';

  @override
  String get logoutSuccess => 'Signed out successfully';

  @override
  String get logoutError => 'Failed to sign out. Please try again.';

  @override
  String logoutPendingReportsWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending reports',
      one: '1 pending report',
    );
    return 'You have $_temp0 waiting to synchronize.';
  }

  @override
  String get logoutReportsRemainOnDevice =>
      'Unsynced reports remain safely stored on this device and will not be lost.';

  @override
  String get routeAccessDenied => 'Access denied for your role.';

  @override
  String get routeSessionRequired => 'Please sign in to continue.';

  @override
  String get routeProfilePending =>
      'Your profile is pending supervisor approval.';

  @override
  String get routeInactiveAccount => 'Your account is currently inactive.';

  @override
  String get reportDetailTitle => 'Inspection Detail';

  @override
  String get reportDetailLocation => 'Location & Track Alignment';

  @override
  String reportDetailCreated(String time) {
    return 'Created: $time';
  }

  @override
  String reportDetailUpdated(String time) {
    return 'Updated: $time';
  }

  @override
  String get reportDetailInspectionStatus => 'Inspection Status';

  @override
  String get reportDetailSyncStatus => 'Sync Status';

  @override
  String get reportDetailAiInformation => 'AI Suggestion (Advisory)';

  @override
  String get reportDetailHumanConfirmed => 'Confirmed by Inspector';

  @override
  String get reportDetailViewImage => 'View Full Image';

  @override
  String get reportDetailRetrySync => 'Retry Synchronization';

  @override
  String get reportDetailUnavailable => 'Report not found or unavailable.';

  @override
  String get aiSettingsTitle => 'AI & Model Settings';

  @override
  String get aiModeAutomatic => 'Automatic (Offline-First)';

  @override
  String get aiModeOfflineGemma => 'Offline Gemma 4 E2B';

  @override
  String get aiModeOnlineGemini => 'Online Gemini Cloud';

  @override
  String get aiModeManual => 'Manual Classification Only';

  @override
  String get aiOfflineGemma => 'Offline Gemma Engine';

  @override
  String get aiGemmaModelName => 'Gemma 4 E2B';

  @override
  String get aiGemmaReady => 'Model Ready (On-Device)';

  @override
  String get aiGemmaLoading => 'Initializing Gemma Model...';

  @override
  String get aiGemmaUnavailable => 'Offline Model Unavailable';

  @override
  String get aiGemmaFailed => 'Offline Model Initialization Failed';

  @override
  String get aiGemini => 'Gemini Cloud Reasoning';

  @override
  String get aiGeminiRequiresNetwork =>
      'Online Gemini requires active station or cellular network';

  @override
  String get aiGeminiUnavailable => 'Online Gemini service unavailable';

  @override
  String get aiProviderUsed => 'Actual Provider';

  @override
  String get aiRequestedProvider => 'Requested Provider';

  @override
  String get aiModelName => 'Model Name';

  @override
  String get aiPromptLanguage => 'Prompt Language';

  @override
  String get aiConfidence => 'Model Confidence';

  @override
  String get aiFallbackReason => 'Fallback Reason';

  @override
  String get aiHumanConfirmationRequired => 'Human Confirmation Mandatory';

  @override
  String get aiAnalyzingOffline => 'Analyzing with Offline Gemma 4 E2B...';

  @override
  String get aiAnalyzingOnline => 'Analyzing with Online Gemini Cloud...';

  @override
  String get aiManualClassification =>
      'AI bypassed. Manual field inspection values applied.';

  @override
  String get aiInvalidResult =>
      'The AI result could not be verified. Please review the fields manually.';

  @override
  String get aiValidationFailed =>
      'AI output failed safety or schema validation.';

  @override
  String get aiModelInitializationFailed =>
      'Failed to initialize offline Gemma runtime.';

  @override
  String get aiInferenceFailed => 'AI model inference execution failed.';

  @override
  String get aiOnlineRequestFailed => 'Online AI backend request failed.';

  @override
  String get aiRateLimited =>
      'AI service rate limit reached. Please retry later.';

  @override
  String get aiTimeout =>
      'AI analysis timed out. Your report will be classified manually.';

  @override
  String get aiImageTooLarge =>
      'The image is too large for analysis. A compressed version will be used.';

  @override
  String get aiPrivacyNotice =>
      'On-device Gemma models process images locally without uploading data to external cloud servers.';

  @override
  String get aiOfflineFirstNotice =>
      'Uses private on-device Gemma when available, cloud Gemini when connected, or heuristic rules.';

  @override
  String get aiRetryAnalysis => 'Retry AI Analysis';

  @override
  String get aiUseManualClassification => 'Switch to Manual';

  @override
  String get aiActualProvider => 'Active Provider';

  @override
  String get offlineModelDownloadTitle => 'Gemma 4 E2B Download';

  @override
  String get offlineModelDownload => 'Download Model';

  @override
  String get offlineModelNotDownloaded => 'Model is not downloaded';

  @override
  String get offlineModelDownloading => 'Downloading Gemma 4 E2B';

  @override
  String get offlineModelDownloaded => 'Gemma 4 E2B downloaded';

  @override
  String get offlineModelReady => 'Gemma 4 E2B Ready';

  @override
  String get offlineModelInitializing => 'Initializing model runtime...';

  @override
  String get offlineModelFailed => 'Model download failed';

  @override
  String get offlineModelUnsupported =>
      'Device does not support local model execution';

  @override
  String offlineModelApproximateSize(String size) {
    return 'Approximate download size: $size';
  }

  @override
  String offlineModelStorageRequired(String size) {
    return 'Required free storage: $size';
  }

  @override
  String offlineModelStorageAvailable(String size) {
    return 'Available storage: $size';
  }

  @override
  String offlineModelDownloadProgress(
    String downloaded,
    String total,
    int percent,
  ) {
    return '$downloaded of $total ($percent%)';
  }

  @override
  String get offlineModelDownloadComplete => 'Download completed successfully';

  @override
  String get offlineModelDownloadFailed => 'Failed to download model files';

  @override
  String get offlineModelInsufficientStorage =>
      'Not enough storage to download the offline model. Free additional space and try again.';

  @override
  String get offlineModelNetworkRequired =>
      'Network connection required to download the model';

  @override
  String get offlineModelWifiOnly => 'Download over Wi-Fi only';

  @override
  String get offlineModelAllowMobileData => 'Allow cellular data download';

  @override
  String get offlineModelMobileDataWarning =>
      'Downloading ~2.6 GB over mobile data may incur carrier charges or consume data limits.';

  @override
  String get offlineModelCancelDownload => 'Cancel Download';

  @override
  String get offlineModelRetryDownload => 'Retry Download';

  @override
  String get offlineModelActivate => 'Activate Offline AI';

  @override
  String get offlineModelDelete => 'Delete Model';

  @override
  String get offlineModelDeleteTitle => 'Delete Gemma 4 E2B?';

  @override
  String get offlineModelDeleteConfirmation =>
      'Offline AI will no longer be available until the model is downloaded again. Reports and saved photos will not be deleted.';

  @override
  String get offlineModelDeleted => 'Offline model deleted from storage';

  @override
  String get offlineModelPrivacyNotice =>
      'Runs 100% locally on your phone. No track photos or inspection notes leave your device when using offline Gemma.';

  @override
  String get offlineModelOfflineNotice =>
      'Once downloaded, offline Gemma functions with zero mobile connectivity along deep forest track sections.';

  @override
  String get offlineModelReportsRemainSafe =>
      'Saved reports, photos, and drafts will not be affected by model deletion.';

  @override
  String get offlineModelUseManualFallback =>
      'Use manual classification if model is unavailable.';

  @override
  String get offlineModelDownloadInProgress =>
      'Model download is currently in progress. Please do not close the app.';

  @override
  String get offlineModelAlreadyDownloading =>
      'A download is already in progress.';

  @override
  String get offlineModelCorrupted =>
      'Model files appear damaged. Please re-download the model.';

  @override
  String offlineModelVersion(String version) {
    return 'Version: $version';
  }

  @override
  String offlineModelDownloadedAt(String date) {
    return 'Downloaded: $date';
  }

  @override
  String get offlineModelDownloadCancelled => 'Model download was cancelled.';

  @override
  String get locationAccuracyPromptTitle => 'Improve Location Accuracy';

  @override
  String get locationAccuracyPromptMessage =>
      'TrackGuard works best when your device provides precise location information.';

  @override
  String get locationAccuracyPromptSettingsHeading =>
      'Check your location settings:';

  @override
  String get locationAccuracyPromptDeviceLocation =>
      '1. Turn on Device Location.';

  @override
  String get locationAccuracyPromptLocationAccuracy =>
      '2. Enable Google Location Accuracy, if available.';

  @override
  String get locationAccuracyPromptExplanation =>
      'This helps TrackGuard capture more accurate locations when reporting hazards.';

  @override
  String get locationAccuracyPromptManageSettingsOr =>
      'You can manage these settings in your device\'s Location settings.';

  @override
  String get locationAccuracyPromptNoThanks => 'Not now';

  @override
  String get locationAccuracyPromptTurnOn => 'Continue';

  @override
  String get reportTrackHazardDescription =>
      'Take a photo of a slip, rockfall, drain, or track issue';

  @override
  String get sendNow => 'Send Now';

  @override
  String get viewMyReports => 'View My Reports';

  @override
  String get willSendAtNextStation =>
      'Will send automatically at next station signal';

  @override
  String get allReportsSentToSupervisor =>
      'Your latest reports have reached the supervisor.';

  @override
  String get gpsLockedStatus => 'GPS locked';

  @override
  String get setManually => 'Set manually';

  @override
  String get startingCamera => 'Starting camera…';

  @override
  String get retryCamera => 'Retry Camera';

  @override
  String get dhrAlignment => 'DHR alignment';

  @override
  String get savesSafelyOnPhoneFirst => 'Saves safely on your phone first.';

  @override
  String get draftMissing => 'Draft Missing';

  @override
  String get inspectionDraftCouldNotBeLoaded =>
      'Inspection draft could not be loaded.';

  @override
  String hazardReportTitle(String hazard) {
    return '$hazard Report';
  }

  @override
  String get statusStepSent => 'Sent';

  @override
  String get statusStepSeenBySupervisor => 'Seen by Supervisor';

  @override
  String get statusStepResolved => 'Resolved';

  @override
  String get technicalAndAiAuditDetails => 'Technical & AI Audit Details';

  @override
  String get reportAuditInformation => 'REPORT AUDIT INFORMATION';

  @override
  String get noPhotoAttached => 'No photo attached';

  @override
  String get photoNotFoundOnDevice => 'Photo not found on device';

  @override
  String reportSource(String source, String accuracy) {
    return 'Source: $source $accuracy';
  }

  @override
  String reportIdLabel(String id) {
    return 'Report ID: $id';
  }

  @override
  String get nearestWaypointBadge => 'Nearest';

  @override
  String get allDhrAlignment => 'All DHR Alignment';

  @override
  String get profileIdentifier => 'Profile Identifier';

  @override
  String get appAlignmentTitle => 'TrackGuard DHR Alignment';

  @override
  String get appEditionVersion => 'Version 1.0.0 • Field Operations Edition';

  @override
  String get adminDashboardTitle => 'TrackGuard Admin';

  @override
  String get adminOverviewTab => 'Overview';

  @override
  String get adminReportsTab => 'Reports';

  @override
  String get adminUsersTab => 'Users';

  @override
  String get adminReportOverview => 'REPORT OVERVIEW';

  @override
  String get adminSectionSummary => 'SECTION SUMMARY';

  @override
  String get adminLatestReports => 'LATEST REPORTS';

  @override
  String get adminTotalReports => 'Total reports';

  @override
  String get adminNoRemoteReportsFound => 'No remote reports found.';

  @override
  String get adminNoProfilesFound => 'No profiles found.';

  @override
  String get adminProfileUpdated => 'Profile updated';

  @override
  String adminUpdateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String get adminRoleLabel => 'Role';

  @override
  String get adminAssignedSection => 'Assigned section';

  @override
  String get adminStatusUpdated => 'Status updated. Check audit history below.';

  @override
  String adminStatusUpdateFailed(String error) {
    return 'Status update failed: $error';
  }

  @override
  String get adminReportDetailTitle => 'Admin report detail';

  @override
  String get adminReportNotFound => 'Report not found or access denied.';

  @override
  String adminSeverityLabel(String severity) {
    return 'Severity: $severity';
  }

  @override
  String adminSectionLabel(String section) {
    return 'Section: $section';
  }

  @override
  String adminStationLabel(String station) {
    return 'Station: $station';
  }

  @override
  String adminKmMarkerLabel(String km) {
    return 'Km marker: $km';
  }

  @override
  String adminCreatedLabel(String created) {
    return 'Created: $created';
  }

  @override
  String adminGpsLabel(String lat, String lng) {
    return 'GPS: $lat, $lng';
  }

  @override
  String get adminUpdateStatusHeading => 'UPDATE STATUS';

  @override
  String get adminInspectionStatusLabel => 'Inspection status';

  @override
  String get adminSaveStatusButton => 'Save status';

  @override
  String get adminSavingStatus => 'Saving…';

  @override
  String get adminAuditHistoryHeading => 'AUDIT HISTORY';

  @override
  String adminCouldNotLoadHistory(String error) {
    return 'Could not load history: $error';
  }

  @override
  String get adminNoStatusChangesYet => 'No status changes recorded yet.';

  @override
  String get adminLoadingPhoto => 'Loading inspection photo...';

  @override
  String get adminNoPhotoAvailable =>
      'No inspection photo available for this report';

  @override
  String get adminFailedToLoadImage => 'Failed to load image from storage';

  @override
  String get adminTapToEnlarge => 'Tap to enlarge';

  @override
  String get adminInspectionPhotoBadge => 'INSPECTION PHOTO';

  @override
  String get adminHazardPhotoTitle => 'Hazard Photo';

  @override
  String get adminFailedToLoadFullImage => 'Failed to load full image';

  @override
  String get adminNotSpecified => 'Not specified';

  @override
  String get adminActiveStatus => 'ACTIVE';

  @override
  String get adminInactiveStatus => 'INACTIVE';

  @override
  String adminChangedBy(String user) {
    return 'Changed by $user';
  }

  @override
  String get smartPhotoHelperTitle => 'Smart Photo Helper';

  @override
  String get aiModeAutomaticHelper => 'Automatic Photo Helper (Recommended)';

  @override
  String get aiModeAutomaticHelperDesc =>
      'Suggests a hazard type and note from your photo, online or offline.';

  @override
  String get aiModeOnlineHelper => 'Online Photo Helper';

  @override
  String get aiModeOnlineHelperDesc =>
      'Use the connected online vision model; needs a network connection.';

  @override
  String get aiModeOfflineHelper => 'Offline Photo Helper';

  @override
  String get aiModeOfflineHelperDesc =>
      'Use the downloaded Gemma model without a network connection.';

  @override
  String get aiModeManualOnly => 'Manual Only';

  @override
  String get aiModeManualOnlyDesc =>
      'Turn off photo suggestions; I will choose the hazard myself.';

  @override
  String get offlinePhotoHelperPackTitle => 'Offline Photo Helper Pack';

  @override
  String get offlinePhotoHelperPackSubtitle =>
      'Download once on Wi-Fi so the app can suggest hazards from your photos when there is no mobile signal.';

  @override
  String get downloadOnWifiButton => 'Download on Wi-Fi';

  @override
  String get stayOnPage => 'Stay on Page';

  @override
  String get cancelDownloadAndLeave => 'Cancel Download & Leave';

  @override
  String get cancelDownloadConfirmation =>
      'Leaving this page will cancel the current model download. Are you sure you want to cancel and leave?';

  @override
  String get downloadPreferencesHeading => 'DOWNLOAD PREFERENCES';

  @override
  String get preventsCellularUsage => 'Prevents cellular data usage';

  @override
  String get modelStatusAndActionsHeading => 'MODEL STATUS & ACTIONS';

  @override
  String get onlineReadyStatus => 'Online Ready';

  @override
  String get networkRequiredStatus => 'Network Required';

  @override
  String get installedDateLabel => 'Installed Date';

  @override
  String get sourceLabel => 'Source';

  @override
  String get integrationLabel => 'Integration';

  @override
  String get aiInferenceError => 'AI Inference Error';

  @override
  String get aiAdvisoryMetadataHeading => 'AI ADVISORY METADATA';

  @override
  String get accountInactive => 'Account Inactive';

  @override
  String get permanentWayStaff => 'Permanent-Way Staff';
}
