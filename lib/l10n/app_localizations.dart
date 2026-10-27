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
