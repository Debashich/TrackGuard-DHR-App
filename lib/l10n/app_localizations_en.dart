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
}
