import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('hi'),
    Locale('ne'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'TrackGuard DHR'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Darjeeling Himalayan Railway Alignment Inspection'**
  String get tagline;

  /// No description provided for @gangman.
  ///
  /// In en, this message translates to:
  /// **'Gangman'**
  String get gangman;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Supervisor / Admin'**
  String get admin;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'TrackGuard DHR Sign In'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanent-Way Inspection & Hazard Reporting'**
  String get signInSubtitle;

  /// No description provided for @signInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Google'**
  String get signInGoogle;

  /// No description provided for @devSignInGangman.
  ///
  /// In en, this message translates to:
  /// **'Developer Sign In (Gangman)'**
  String get devSignInGangman;

  /// No description provided for @devSignInAdmin.
  ///
  /// In en, this message translates to:
  /// **'Developer Sign In (Admin)'**
  String get devSignInAdmin;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String signedInAs(String name);

  /// No description provided for @pendingAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Approval Pending'**
  String get pendingAccessTitle;

  /// No description provided for @pendingAccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been registered. An authorized permanent-way supervisor must approve your profile before you can access field tools.'**
  String get pendingAccessMessage;

  /// No description provided for @inactiveAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account is marked inactive. Please contact your section engineer.'**
  String get inactiveAccountMessage;

  /// No description provided for @checkStatus.
  ///
  /// In en, this message translates to:
  /// **'Check Status'**
  String get checkStatus;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Inspection Dashboard'**
  String get homeTitle;

  /// No description provided for @newReport.
  ///
  /// In en, this message translates to:
  /// **'New Report'**
  String get newReport;

  /// No description provided for @myReports.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get myReports;

  /// No description provided for @pendingQueue.
  ///
  /// In en, this message translates to:
  /// **'Pending Sync Queue'**
  String get pendingQueue;

  /// No description provided for @pendingReportsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 reports pending} =1{1 report pending} other{{count} reports pending}}'**
  String pendingReportsCount(int count);

  /// No description provided for @assignedSection.
  ///
  /// In en, this message translates to:
  /// **'Assigned Section: {section}'**
  String assignedSection(String section);

  /// No description provided for @unassignedSection.
  ///
  /// In en, this message translates to:
  /// **'No section assigned'**
  String get unassignedSection;

  /// No description provided for @onlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Online - Cloud Sync Ready'**
  String get onlineStatus;

  /// No description provided for @offlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Offline - Local Queue Active'**
  String get offlineStatus;

  /// No description provided for @aiStatusReady.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis: Ready (Offline)'**
  String get aiStatusReady;

  /// No description provided for @aiStatusHeuristic.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis: Heuristic Fallback'**
  String get aiStatusHeuristic;

  /// No description provided for @aiStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis: Manual Only'**
  String get aiStatusUnavailable;

  /// No description provided for @offlineExplanation.
  ///
  /// In en, this message translates to:
  /// **'All inspection reports are saved to your device immediately. When you reach a station with connectivity, queued reports will sync automatically.'**
  String get offlineExplanation;

  /// No description provided for @captureTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture Hazard Photo'**
  String get captureTitle;

  /// No description provided for @cameraPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera Permission Required'**
  String get cameraPermissionTitle;

  /// No description provided for @cameraPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'TrackGuard needs camera access to capture track hazards and retaining wall defects.'**
  String get cameraPermissionMessage;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Precise GPS location is needed to estimate alignment kilometre markers and track sections.'**
  String get locationPermissionMessage;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Capture Photo'**
  String get takePhoto;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @confirmPhoto.
  ///
  /// In en, this message translates to:
  /// **'Use Photo'**
  String get confirmPhoto;

  /// No description provided for @switchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch Camera'**
  String get switchCamera;

  /// No description provided for @galleryFallback.
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get galleryFallback;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable. Please use gallery fallback.'**
  String get cameraUnavailable;

  /// No description provided for @processingImage.
  ///
  /// In en, this message translates to:
  /// **'Processing image...'**
  String get processingImage;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location & Alignment'**
  String get locationTitle;

  /// No description provided for @gpsAcquiring.
  ///
  /// In en, this message translates to:
  /// **'Acquiring GPS fix...'**
  String get gpsAcquiring;

  /// No description provided for @gpsLocked.
  ///
  /// In en, this message translates to:
  /// **'GPS Locked (±{accuracy}m)'**
  String gpsLocked(String accuracy);

  /// No description provided for @gpsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'GPS Signal Unavailable'**
  String get gpsUnavailable;

  /// No description provided for @locationSourceGps.
  ///
  /// In en, this message translates to:
  /// **'Source: Real GPS'**
  String get locationSourceGps;

  /// No description provided for @locationSourceManual.
  ///
  /// In en, this message translates to:
  /// **'Source: Manual Selection'**
  String get locationSourceManual;

  /// No description provided for @locationSourceFallback.
  ///
  /// In en, this message translates to:
  /// **'Source: Estimated Fallback'**
  String get locationSourceFallback;

  /// No description provided for @kmMarker.
  ///
  /// In en, this message translates to:
  /// **'Km {marker}'**
  String kmMarker(String marker);

  /// No description provided for @nearestStation.
  ///
  /// In en, this message translates to:
  /// **'Nearest Station: {station}'**
  String nearestStation(String station);

  /// No description provided for @selectWaypoint.
  ///
  /// In en, this message translates to:
  /// **'Select Nearest DHR Station / Waypoint'**
  String get selectWaypoint;

  /// No description provided for @editKm.
  ///
  /// In en, this message translates to:
  /// **'Edit Km Marker'**
  String get editKm;

  /// No description provided for @manualLocationNotice.
  ///
  /// In en, this message translates to:
  /// **'Warning: Fallback coordinates are estimated. Adjust km marker manually if needed.'**
  String get manualLocationNotice;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review & Confirm Report'**
  String get reviewTitle;

  /// No description provided for @aiSuggestionTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Advisory Suggestion'**
  String get aiSuggestionTitle;

  /// No description provided for @aiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI suggestions are advisory only. Permanent-way staff must inspect and confirm the actual hazard and severity before saving.'**
  String get aiDisclaimer;

  /// No description provided for @aiAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing image with on-device intelligence...'**
  String get aiAnalyzing;

  /// No description provided for @aiSuggestedHazard.
  ///
  /// In en, this message translates to:
  /// **'Suggested Hazard: {hazard}'**
  String aiSuggestedHazard(String hazard);

  /// No description provided for @aiSuggestedSeverity.
  ///
  /// In en, this message translates to:
  /// **'Suggested Severity: {severity}'**
  String aiSuggestedSeverity(String severity);

  /// No description provided for @aiNote.
  ///
  /// In en, this message translates to:
  /// **'AI Observation: {note}'**
  String aiNote(String note);

  /// No description provided for @humanConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Human Confirmation (Required)'**
  String get humanConfirmationTitle;

  /// No description provided for @hazardType.
  ///
  /// In en, this message translates to:
  /// **'Hazard Type'**
  String get hazardType;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @gangmanNote.
  ///
  /// In en, this message translates to:
  /// **'Gangman\'s Field Note'**
  String get gangmanNote;

  /// No description provided for @gangmanNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Describe obstruction, track clearance, or slope movement...'**
  String get gangmanNoteHint;

  /// No description provided for @saveAndQueue.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Save Locally'**
  String get saveAndQueue;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving report locally...'**
  String get saving;

  /// No description provided for @savedSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Saved Locally!'**
  String get savedSuccessTitle;

  /// No description provided for @savedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Report saved with ID: {id}. It has been added to the local queue and will sync when station connectivity is reached.'**
  String savedSuccessMessage(String id);

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @viewQueue.
  ///
  /// In en, this message translates to:
  /// **'View Queue'**
  String get viewQueue;

  /// No description provided for @hazardSlip.
  ///
  /// In en, this message translates to:
  /// **'Landslip / Mudslide'**
  String get hazardSlip;

  /// No description provided for @hazardRockfall.
  ///
  /// In en, this message translates to:
  /// **'Rockfall / Fallen Debris'**
  String get hazardRockfall;

  /// No description provided for @hazardBlockedDrain.
  ///
  /// In en, this message translates to:
  /// **'Blocked Catchwater Drain'**
  String get hazardBlockedDrain;

  /// No description provided for @hazardDamagedWall.
  ///
  /// In en, this message translates to:
  /// **'Damaged Retaining Wall'**
  String get hazardDamagedWall;

  /// No description provided for @hazardTrackDefect.
  ///
  /// In en, this message translates to:
  /// **'Track Defect / Gauge Spread'**
  String get hazardTrackDefect;

  /// No description provided for @hazardVegetation.
  ///
  /// In en, this message translates to:
  /// **'Vegetation Overgrowth'**
  String get hazardVegetation;

  /// No description provided for @hazardOther.
  ///
  /// In en, this message translates to:
  /// **'Other Hazard'**
  String get hazardOther;

  /// No description provided for @severityLow.
  ///
  /// In en, this message translates to:
  /// **'Low - Monitor'**
  String get severityLow;

  /// No description provided for @severityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium - Maintenance Needed'**
  String get severityMedium;

  /// No description provided for @severityHigh.
  ///
  /// In en, this message translates to:
  /// **'High - Speed Restriction Required'**
  String get severityHigh;

  /// No description provided for @severityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical - Track Obstruction / Danger'**
  String get severityCritical;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get statusAcknowledged;

  /// No description provided for @statusInspectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Inspection Required'**
  String get statusInspectionRequired;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @syncDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get syncDraft;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Sync'**
  String get syncPending;

  /// No description provided for @syncSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncSyncing;

  /// No description provided for @syncSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced to Server'**
  String get syncSynced;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync Failed'**
  String get syncFailed;

  /// No description provided for @syncConflict.
  ///
  /// In en, this message translates to:
  /// **'Conflict'**
  String get syncConflict;

  /// No description provided for @syncStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get syncStatusDraft;

  /// No description provided for @syncStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Sync'**
  String get syncStatusPending;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncStatusSynced;

  /// No description provided for @syncStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync Failed'**
  String get syncStatusFailed;

  /// No description provided for @syncStatusConflict.
  ///
  /// In en, this message translates to:
  /// **'Conflict'**
  String get syncStatusConflict;

  /// No description provided for @syncSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Summary'**
  String get syncSummaryTitle;

  /// No description provided for @syncPendingReports.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 reports waiting} =1{1 report waiting to sync} other{{count} reports waiting to sync}}'**
  String syncPendingReports(int count);

  /// No description provided for @syncFailedReports.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 reports failed} =1{1 report failed} other{{count} reports failed}}'**
  String syncFailedReports(int count);

  /// No description provided for @syncReportsSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing reports...'**
  String get syncReportsSyncing;

  /// No description provided for @syncAllReportsSynced.
  ///
  /// In en, this message translates to:
  /// **'All reports synced'**
  String get syncAllReportsSynced;

  /// No description provided for @syncLastSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Last synced: {time}'**
  String syncLastSuccessful(String time);

  /// No description provided for @syncNoSuccessfulSync.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get syncNoSuccessfulSync;

  /// No description provided for @syncOfflineSafe.
  ///
  /// In en, this message translates to:
  /// **'Offline — reports remain safely stored on this device.'**
  String get syncOfflineSafe;

  /// No description provided for @syncWaitingForSignal.
  ///
  /// In en, this message translates to:
  /// **'Offline — waiting for station signal'**
  String get syncWaitingForSignal;

  /// No description provided for @syncStationSignalAvailable.
  ///
  /// In en, this message translates to:
  /// **'Station signal available'**
  String get syncStationSignalAvailable;

  /// No description provided for @syncSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Saved locally on this device'**
  String get syncSavedLocally;

  /// No description provided for @syncSavedAndSynced.
  ///
  /// In en, this message translates to:
  /// **'Saved and synced to server'**
  String get syncSavedAndSynced;

  /// No description provided for @syncFailedButSafe.
  ///
  /// In en, this message translates to:
  /// **'Some reports could not sync. They remain safe locally.'**
  String get syncFailedButSafe;

  /// No description provided for @syncNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'This report needs attention'**
  String get syncNeedsAttention;

  /// No description provided for @syncErrorOffline.
  ///
  /// In en, this message translates to:
  /// **'No network connection. The report is safely stored on this device.'**
  String get syncErrorOffline;

  /// No description provided for @syncErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The station connection took too long. The report remains saved locally.'**
  String get syncErrorTimeout;

  /// No description provided for @syncErrorServerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The control service is temporarily unavailable. Please try again later.'**
  String get syncErrorServerUnavailable;

  /// No description provided for @syncErrorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your access has expired or is unauthorized. Sign in again when connectivity is available.'**
  String get syncErrorUnauthorized;

  /// No description provided for @syncErrorMediaUpload.
  ///
  /// In en, this message translates to:
  /// **'The report details were prepared, but the photo could not be uploaded yet.'**
  String get syncErrorMediaUpload;

  /// No description provided for @syncErrorConflict.
  ///
  /// In en, this message translates to:
  /// **'This report was changed elsewhere and needs review.'**
  String get syncErrorConflict;

  /// No description provided for @syncErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'The report could not be synchronized. It remains safely stored locally.'**
  String get syncErrorUnknown;

  /// No description provided for @aiProviderOfflineGemma.
  ///
  /// In en, this message translates to:
  /// **'Offline Gemma'**
  String get aiProviderOfflineGemma;

  /// No description provided for @aiProviderHeuristic.
  ///
  /// In en, this message translates to:
  /// **'Heuristic Rules'**
  String get aiProviderHeuristic;

  /// No description provided for @aiProviderManual.
  ///
  /// In en, this message translates to:
  /// **'Manual Classification'**
  String get aiProviderManual;

  /// No description provided for @aiProviderOnlineGemini.
  ///
  /// In en, this message translates to:
  /// **'Online Gemini'**
  String get aiProviderOnlineGemini;

  /// No description provided for @aiModelLabel.
  ///
  /// In en, this message translates to:
  /// **'AI Model'**
  String get aiModelLabel;

  /// No description provided for @aiProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'AI Provider'**
  String get aiProviderLabel;

  /// No description provided for @aiLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'AI Language'**
  String get aiLanguageLabel;

  /// No description provided for @aiConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get aiConfidenceLabel;

  /// No description provided for @aiAdvisoryNotice.
  ///
  /// In en, this message translates to:
  /// **'AI suggestion is advisory only. Gangman inspection confirmed.'**
  String get aiAdvisoryNotice;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @syncSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Synchronization completed successfully'**
  String get syncSuccessMessage;

  /// No description provided for @retrySync.
  ///
  /// In en, this message translates to:
  /// **'Retry Sync'**
  String get retrySync;

  /// No description provided for @viewSyncDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewSyncDetails;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @noReportsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No reports match the selected filter.'**
  String get noReportsMatchFilter;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get profileTitle;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profileName;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get profileEmail;

  /// No description provided for @profileRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRole;

  /// No description provided for @profileAssignedSection.
  ///
  /// In en, this message translates to:
  /// **'Assigned Section'**
  String get profileAssignedSection;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get profileLanguage;

  /// No description provided for @profileAccountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get profileAccountStatus;

  /// No description provided for @profileActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get profileActive;

  /// No description provided for @profileInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get profileInactive;

  /// No description provided for @profileBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Return to Dashboard'**
  String get profileBackToHome;

  /// No description provided for @roleGangman.
  ///
  /// In en, this message translates to:
  /// **'Gangman'**
  String get roleGangman;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Supervisor / Admin'**
  String get roleAdmin;

  /// No description provided for @navigationHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navigationHome;

  /// No description provided for @navigationMyReports.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get navigationMyReports;

  /// No description provided for @navigationDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navigationDashboard;

  /// No description provided for @navigationProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navigationProfile;

  /// No description provided for @navigationLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get navigationLogout;

  /// No description provided for @navigationReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navigationReports;

  /// No description provided for @navigationUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get navigationUsers;

  /// No description provided for @navigationBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get navigationBack;

  /// No description provided for @navigationRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get navigationRefresh;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Sign Out'**
  String get logoutTitle;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out of your account?'**
  String get logoutConfirmation;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get logoutConfirm;

  /// No description provided for @logoutCancel.
  ///
  /// In en, this message translates to:
  /// **'Stay Signed In'**
  String get logoutCancel;

  /// No description provided for @logoutSigningOut.
  ///
  /// In en, this message translates to:
  /// **'Signing out...'**
  String get logoutSigningOut;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed out successfully'**
  String get logoutSuccess;

  /// No description provided for @logoutError.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign out. Please try again.'**
  String get logoutError;

  /// No description provided for @logoutPendingReportsWarning.
  ///
  /// In en, this message translates to:
  /// **'You have {count, plural, =1{1 pending report} other{{count} pending reports}} waiting to synchronize.'**
  String logoutPendingReportsWarning(int count);

  /// No description provided for @logoutReportsRemainOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Unsynced reports remain safely stored on this device and will not be lost.'**
  String get logoutReportsRemainOnDevice;

  /// No description provided for @routeAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied for your role.'**
  String get routeAccessDenied;

  /// No description provided for @routeSessionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue.'**
  String get routeSessionRequired;

  /// No description provided for @routeProfilePending.
  ///
  /// In en, this message translates to:
  /// **'Your profile is pending supervisor approval.'**
  String get routeProfilePending;

  /// No description provided for @routeInactiveAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account is currently inactive.'**
  String get routeInactiveAccount;

  /// No description provided for @reportDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Inspection Detail'**
  String get reportDetailTitle;

  /// No description provided for @reportDetailLocation.
  ///
  /// In en, this message translates to:
  /// **'Location & Track Alignment'**
  String get reportDetailLocation;

  /// No description provided for @reportDetailCreated.
  ///
  /// In en, this message translates to:
  /// **'Created: {time}'**
  String reportDetailCreated(String time);

  /// No description provided for @reportDetailUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated: {time}'**
  String reportDetailUpdated(String time);

  /// No description provided for @reportDetailInspectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Inspection Status'**
  String get reportDetailInspectionStatus;

  /// No description provided for @reportDetailSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get reportDetailSyncStatus;

  /// No description provided for @reportDetailAiInformation.
  ///
  /// In en, this message translates to:
  /// **'AI Suggestion (Advisory)'**
  String get reportDetailAiInformation;

  /// No description provided for @reportDetailHumanConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by Inspector'**
  String get reportDetailHumanConfirmed;

  /// No description provided for @reportDetailViewImage.
  ///
  /// In en, this message translates to:
  /// **'View Full Image'**
  String get reportDetailViewImage;

  /// No description provided for @reportDetailRetrySync.
  ///
  /// In en, this message translates to:
  /// **'Retry Synchronization'**
  String get reportDetailRetrySync;

  /// No description provided for @reportDetailUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Report not found or unavailable.'**
  String get reportDetailUnavailable;

  /// No description provided for @aiSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI & Model Settings'**
  String get aiSettingsTitle;

  /// No description provided for @aiModeAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic (Offline-First)'**
  String get aiModeAutomatic;

  /// No description provided for @aiModeOfflineGemma.
  ///
  /// In en, this message translates to:
  /// **'Offline Gemma 4 E2B'**
  String get aiModeOfflineGemma;

  /// No description provided for @aiModeOnlineGemini.
  ///
  /// In en, this message translates to:
  /// **'Online Gemini Cloud'**
  String get aiModeOnlineGemini;

  /// No description provided for @aiModeManual.
  ///
  /// In en, this message translates to:
  /// **'Manual Classification Only'**
  String get aiModeManual;

  /// No description provided for @aiOfflineGemma.
  ///
  /// In en, this message translates to:
  /// **'Offline Gemma Engine'**
  String get aiOfflineGemma;

  /// No description provided for @aiGemmaModelName.
  ///
  /// In en, this message translates to:
  /// **'Gemma 4 E2B'**
  String get aiGemmaModelName;

  /// No description provided for @aiGemmaReady.
  ///
  /// In en, this message translates to:
  /// **'Model Ready (On-Device)'**
  String get aiGemmaReady;

  /// No description provided for @aiGemmaLoading.
  ///
  /// In en, this message translates to:
  /// **'Initializing Gemma Model...'**
  String get aiGemmaLoading;

  /// No description provided for @aiGemmaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Offline Model Unavailable'**
  String get aiGemmaUnavailable;

  /// No description provided for @aiGemmaFailed.
  ///
  /// In en, this message translates to:
  /// **'Offline Model Initialization Failed'**
  String get aiGemmaFailed;

  /// No description provided for @aiGemini.
  ///
  /// In en, this message translates to:
  /// **'Gemini Cloud Reasoning'**
  String get aiGemini;

  /// No description provided for @aiGeminiRequiresNetwork.
  ///
  /// In en, this message translates to:
  /// **'Online Gemini requires active station or cellular network'**
  String get aiGeminiRequiresNetwork;

  /// No description provided for @aiGeminiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Online Gemini service unavailable'**
  String get aiGeminiUnavailable;

  /// No description provided for @aiProviderUsed.
  ///
  /// In en, this message translates to:
  /// **'Actual Provider'**
  String get aiProviderUsed;

  /// No description provided for @aiRequestedProvider.
  ///
  /// In en, this message translates to:
  /// **'Requested Provider'**
  String get aiRequestedProvider;

  /// No description provided for @aiModelName.
  ///
  /// In en, this message translates to:
  /// **'Model Name'**
  String get aiModelName;

  /// No description provided for @aiPromptLanguage.
  ///
  /// In en, this message translates to:
  /// **'Prompt Language'**
  String get aiPromptLanguage;

  /// No description provided for @aiConfidence.
  ///
  /// In en, this message translates to:
  /// **'Model Confidence'**
  String get aiConfidence;

  /// No description provided for @aiFallbackReason.
  ///
  /// In en, this message translates to:
  /// **'Fallback Reason'**
  String get aiFallbackReason;

  /// No description provided for @aiHumanConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'Human Confirmation Mandatory'**
  String get aiHumanConfirmationRequired;

  /// No description provided for @aiAnalyzingOffline.
  ///
  /// In en, this message translates to:
  /// **'Analyzing with Offline Gemma 4 E2B...'**
  String get aiAnalyzingOffline;

  /// No description provided for @aiAnalyzingOnline.
  ///
  /// In en, this message translates to:
  /// **'Analyzing with Online Gemini Cloud...'**
  String get aiAnalyzingOnline;

  /// No description provided for @aiManualClassification.
  ///
  /// In en, this message translates to:
  /// **'AI bypassed. Manual field inspection values applied.'**
  String get aiManualClassification;

  /// No description provided for @aiInvalidResult.
  ///
  /// In en, this message translates to:
  /// **'The AI result could not be verified. Please review the fields manually.'**
  String get aiInvalidResult;

  /// No description provided for @aiValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'AI output failed safety or schema validation.'**
  String get aiValidationFailed;

  /// No description provided for @aiModelInitializationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize offline Gemma runtime.'**
  String get aiModelInitializationFailed;

  /// No description provided for @aiInferenceFailed.
  ///
  /// In en, this message translates to:
  /// **'AI model inference execution failed.'**
  String get aiInferenceFailed;

  /// No description provided for @aiOnlineRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Online AI backend request failed.'**
  String get aiOnlineRequestFailed;

  /// No description provided for @aiRateLimited.
  ///
  /// In en, this message translates to:
  /// **'AI service rate limit reached. Please retry later.'**
  String get aiRateLimited;

  /// No description provided for @aiTimeout.
  ///
  /// In en, this message translates to:
  /// **'AI analysis timed out. Your report will be classified manually.'**
  String get aiTimeout;

  /// No description provided for @aiImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The image is too large for analysis. A compressed version will be used.'**
  String get aiImageTooLarge;

  /// No description provided for @aiPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'On-device Gemma models process images locally without uploading data to external cloud servers.'**
  String get aiPrivacyNotice;

  /// No description provided for @aiOfflineFirstNotice.
  ///
  /// In en, this message translates to:
  /// **'Uses private on-device Gemma when available, cloud Gemini when connected, or heuristic rules.'**
  String get aiOfflineFirstNotice;

  /// No description provided for @aiRetryAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Retry AI Analysis'**
  String get aiRetryAnalysis;

  /// No description provided for @aiUseManualClassification.
  ///
  /// In en, this message translates to:
  /// **'Switch to Manual'**
  String get aiUseManualClassification;

  /// No description provided for @aiActualProvider.
  ///
  /// In en, this message translates to:
  /// **'Active Provider'**
  String get aiActualProvider;

  /// No description provided for @offlineModelDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Gemma 4 E2B Download'**
  String get offlineModelDownloadTitle;

  /// No description provided for @offlineModelDownload.
  ///
  /// In en, this message translates to:
  /// **'Download Model'**
  String get offlineModelDownload;

  /// No description provided for @offlineModelNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Model is not downloaded'**
  String get offlineModelNotDownloaded;

  /// No description provided for @offlineModelDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading Gemma 4 E2B'**
  String get offlineModelDownloading;

  /// No description provided for @offlineModelDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Gemma 4 E2B downloaded'**
  String get offlineModelDownloaded;

  /// No description provided for @offlineModelReady.
  ///
  /// In en, this message translates to:
  /// **'Gemma 4 E2B Ready'**
  String get offlineModelReady;

  /// No description provided for @offlineModelInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing model runtime...'**
  String get offlineModelInitializing;

  /// No description provided for @offlineModelFailed.
  ///
  /// In en, this message translates to:
  /// **'Model download failed'**
  String get offlineModelFailed;

  /// No description provided for @offlineModelUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Device does not support local model execution'**
  String get offlineModelUnsupported;

  /// No description provided for @offlineModelApproximateSize.
  ///
  /// In en, this message translates to:
  /// **'Approximate download size: {size}'**
  String offlineModelApproximateSize(String size);

  /// No description provided for @offlineModelStorageRequired.
  ///
  /// In en, this message translates to:
  /// **'Required free storage: {size}'**
  String offlineModelStorageRequired(String size);

  /// No description provided for @offlineModelStorageAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available storage: {size}'**
  String offlineModelStorageAvailable(String size);

  /// No description provided for @offlineModelDownloadProgress.
  ///
  /// In en, this message translates to:
  /// **'{downloaded} of {total} ({percent}%)'**
  String offlineModelDownloadProgress(
    String downloaded,
    String total,
    int percent,
  );

  /// No description provided for @offlineModelDownloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download completed successfully'**
  String get offlineModelDownloadComplete;

  /// No description provided for @offlineModelDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download model files'**
  String get offlineModelDownloadFailed;

  /// No description provided for @offlineModelInsufficientStorage.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage to download the offline model. Free additional space and try again.'**
  String get offlineModelInsufficientStorage;

  /// No description provided for @offlineModelNetworkRequired.
  ///
  /// In en, this message translates to:
  /// **'Network connection required to download the model'**
  String get offlineModelNetworkRequired;

  /// No description provided for @offlineModelWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Download over Wi-Fi only'**
  String get offlineModelWifiOnly;

  /// No description provided for @offlineModelAllowMobileData.
  ///
  /// In en, this message translates to:
  /// **'Allow cellular data download'**
  String get offlineModelAllowMobileData;

  /// No description provided for @offlineModelMobileDataWarning.
  ///
  /// In en, this message translates to:
  /// **'Downloading ~1.2 GB over mobile data may incur carrier charges or consume data limits.'**
  String get offlineModelMobileDataWarning;

  /// No description provided for @offlineModelCancelDownload.
  ///
  /// In en, this message translates to:
  /// **'Cancel Download'**
  String get offlineModelCancelDownload;

  /// No description provided for @offlineModelRetryDownload.
  ///
  /// In en, this message translates to:
  /// **'Retry Download'**
  String get offlineModelRetryDownload;

  /// No description provided for @offlineModelActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate Offline AI'**
  String get offlineModelActivate;

  /// No description provided for @offlineModelDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Model'**
  String get offlineModelDelete;

  /// No description provided for @offlineModelDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Gemma 4 E2B?'**
  String get offlineModelDeleteTitle;

  /// No description provided for @offlineModelDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Offline AI will no longer be available until the model is downloaded again. Reports and saved photos will not be deleted.'**
  String get offlineModelDeleteConfirmation;

  /// No description provided for @offlineModelDeleted.
  ///
  /// In en, this message translates to:
  /// **'Offline model deleted from storage'**
  String get offlineModelDeleted;

  /// No description provided for @offlineModelPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Runs 100% locally on your phone. No track photos or inspection notes leave your device when using offline Gemma.'**
  String get offlineModelPrivacyNotice;

  /// No description provided for @offlineModelOfflineNotice.
  ///
  /// In en, this message translates to:
  /// **'Once downloaded, offline Gemma functions with zero mobile connectivity along deep forest track sections.'**
  String get offlineModelOfflineNotice;

  /// No description provided for @offlineModelReportsRemainSafe.
  ///
  /// In en, this message translates to:
  /// **'Saved reports, photos, and drafts will not be affected by model deletion.'**
  String get offlineModelReportsRemainSafe;

  /// No description provided for @offlineModelUseManualFallback.
  ///
  /// In en, this message translates to:
  /// **'Use manual classification if model is unavailable.'**
  String get offlineModelUseManualFallback;

  /// No description provided for @offlineModelDownloadInProgress.
  ///
  /// In en, this message translates to:
  /// **'Model download is currently in progress. Please do not close the app.'**
  String get offlineModelDownloadInProgress;

  /// No description provided for @offlineModelAlreadyDownloading.
  ///
  /// In en, this message translates to:
  /// **'A download is already in progress.'**
  String get offlineModelAlreadyDownloading;

  /// No description provided for @offlineModelCorrupted.
  ///
  /// In en, this message translates to:
  /// **'Model files appear damaged. Please re-download the model.'**
  String get offlineModelCorrupted;

  /// No description provided for @offlineModelVersion.
  ///
  /// In en, this message translates to:
  /// **'Version: {version}'**
  String offlineModelVersion(String version);

  /// No description provided for @offlineModelDownloadedAt.
  ///
  /// In en, this message translates to:
  /// **'Downloaded: {date}'**
  String offlineModelDownloadedAt(String date);

  /// No description provided for @offlineModelDownloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Model download was cancelled.'**
  String get offlineModelDownloadCancelled;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en', 'hi', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
