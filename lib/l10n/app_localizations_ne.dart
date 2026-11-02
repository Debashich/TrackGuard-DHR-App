// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get appTitle => 'ट्र्याकगार्ड डीएचआर';

  @override
  String get tagline => 'दार्जिलिङ हिमालयन रेलवे ट्र्याक निरीक्षण';

  @override
  String get gangman => 'ग्याङम्यान';

  @override
  String get admin => 'सुपरभाइजर / एडमिन';

  @override
  String get signInTitle => 'ट्र्याकगार्ड डीएचआर साइन इन';

  @override
  String get signInSubtitle => 'ट्र्याक निरीक्षण तथा जोखिम रिपोर्टिङ';

  @override
  String get signInGoogle => 'गुगलबाट साइन इन गर्नुहोस्';

  @override
  String get offlineFieldLogin => 'फिल्ड निरीक्षण (अफलाइन मोड)';

  @override
  String get offlineFieldLoginSubtitle =>
      'अन-डिभाइस जेम्मा एआई प्रयोग गर्नुहोस् • इन्टरनेट आवश्यक छैन';

  @override
  String get offlineModeBadge => 'अफलाइन मोड (इन्टरनेट छैन)';

  @override
  String get onlineModeBadge => 'अनलाइन (क्लाउड सिंक तयार)';

  @override
  String get devSignInGangman => 'डेभलपर साइन इन (ग्याङम्यान)';

  @override
  String get devSignInAdmin => 'डेभलपर साइन इन (एडमिन)';

  @override
  String get signingIn => 'साइन इन हुँदैछ...';

  @override
  String get signOut => 'साइन आउट';

  @override
  String signedInAs(String name) {
    return '$name को रूपमा साइन इन हुनुहुन्छ';
  }

  @override
  String get pendingAccessTitle => 'अनुमति पर्खाइमा छ';

  @override
  String get pendingAccessMessage =>
      'तपाईंको खाता दर्ता भएको छ। फिल्ड उपकरणहरू प्रयोग गर्न आधिकारिक सुपरभाइजरले तपाईंको प्रोफाइल स्वीकृत गर्नुपर्छ।';

  @override
  String get inactiveAccountMessage =>
      'तपाईंको खाता निष्क्रिय छ। कृपया सेक्सन इन्जिनियरलाई सम्पर्क गर्नुहोस्।';

  @override
  String get checkStatus => 'स्थिति जाँच्नुहोस्';

  @override
  String get homeTitle => 'निरीक्षण ड्यासबोर्ड';

  @override
  String get newReport => 'नयाँ रिपोर्ट';

  @override
  String get myReports => 'मेरो रिपोर्टहरू';

  @override
  String get pendingQueue => 'बाँकी सिङ्क लाम';

  @override
  String pendingReportsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिपोर्ट बाँकी',
      one: '१ रिपोर्ट बाँकी',
      zero: '० रिपोर्ट बाँकी',
    );
    return '$_temp0';
  }

  @override
  String assignedSection(String section) {
    return 'तोकिएको सेक्सन: $section';
  }

  @override
  String get unassignedSection => 'कुनै सेक्सन तोकिएको छैन';

  @override
  String get onlineStatus => 'अनलाइन - क्लाउड सिङ्क तयार';

  @override
  String get offlineStatus => 'अफलाइन - स्थानीय लाम सक्रिय';

  @override
  String get aiStatusReady => 'एआई विश्लेषण: तयार (अफलाइन)';

  @override
  String get aiStatusHeuristic => 'एआई विश्लेषण: ह्युरिस्टिक विकल्प';

  @override
  String get aiStatusUnavailable => 'एआई विश्लेषण: म्यानुअल मात्र';

  @override
  String get offlineExplanation =>
      'सबै निरीक्षण रिपोर्टहरू तपाईंको डिभाइसमा तुरुन्त सुरक्षित हुन्छन्। कनेक्टिभिटी भएको स्टेसनमा पुग्दा स्वचालित रूपमा सिङ्क हुनेछ।';

  @override
  String get captureTitle => 'जोखिमको फोटो खिच्नुहोस्';

  @override
  String get cameraPermissionTitle => 'क्यामेरा अनुमति आवश्यक';

  @override
  String get cameraPermissionMessage =>
      'ट्र्याकका जोखिमहरू र पर्खालको क्षति दर्ता गर्न क्यामेरा अनुमति चाहिन्छ।';

  @override
  String get locationPermissionTitle => 'स्थान अनुमति आवश्यक';

  @override
  String get locationPermissionMessage =>
      'किलोमिटर मार्कर र ट्र्याक सेक्सन अनुमान गर्न सही जीपीएस चाहिन्छ।';

  @override
  String get grantPermission => 'अनुमति दिनुहोस्';

  @override
  String get takePhoto => 'फोटो खिच्नुहोस्';

  @override
  String get retake => 'पुनः खिच्नुहोस्';

  @override
  String get confirmPhoto => 'फोटो प्रयोग गर्नुहोस्';

  @override
  String get switchCamera => 'क्यामेरा फेर्नुहोस्';

  @override
  String get galleryFallback => 'ग्यालेरीबाट छान्नुहोस्';

  @override
  String get cameraUnavailable =>
      'क्यामेरा उपलब्ध भएन। कृपया ग्यालेरी प्रयोग गर्नुहोस्।';

  @override
  String get processingImage => 'फोटो प्रशोधन हुँदैछ...';

  @override
  String get locationTitle => 'स्थान र संरेखण';

  @override
  String get gpsAcquiring => 'जीपीएस सिग्नल खोजिँदैछ...';

  @override
  String gpsLocked(String accuracy) {
    return 'जीपीएस लक (±$accuracyमी)';
  }

  @override
  String get gpsUnavailable => 'जीपीएस सिग्नल उपलब्ध छैन';

  @override
  String get locationSourceGps => 'स्रोत: वास्तविक जीपीएस';

  @override
  String get locationSourceManual => 'स्रोत: म्यानुअल छनोट';

  @override
  String get locationSourceFallback => 'स्रोत: अनुमानित विकल्प';

  @override
  String kmMarker(String marker) {
    return 'किमी $marker';
  }

  @override
  String nearestStation(String station) {
    return 'नजिकको स्टेसन: $station';
  }

  @override
  String get selectWaypoint => 'नजिकको डीएचआर स्टेसन / वेपोइन्ट छान्नुहोस्';

  @override
  String stationName(String stationId) {
    String _temp0 = intl.Intl.selectLogic(stationId, {
      'kurseong': 'कुर्सियाङ स्टेसन',
      'tung': 'टुङ स्टेसन',
      'dilaram': 'दिलाराम पोइन्ट',
      'sonada': 'सोनादा स्टेसन',
      'rongbull': 'रोङबुल लूप',
      'jorebungalow': 'जोरेबङ्गलो',
      'ghum': 'घुम स्टेसन',
      'batasia': 'बतासिया लूप',
      'darjeeling': 'दार्जिलिङ स्टेसन',
      'other': 'stationId',
    });
    return '$_temp0';
  }

  @override
  String get editKm => 'किमी मार्कर सम्पादन गर्नुहोस्';

  @override
  String get manualLocationNotice =>
      'चेतावनी: विकल्प निर्देशाङ्कहरू अनुमानित हुन्। आवश्यक परे किमी मार्कर म्यानुअल रूपमा सच्याउनुहोस्।';

  @override
  String get reviewTitle => 'समीक्षा र पुष्टि गर्नुहोस्';

  @override
  String get aiSuggestionTitle => 'एआई सल्लाहकार सुझाव';

  @override
  String get aiDisclaimer =>
      'एआई सुझावहरू सल्लाहका लागि मात्र हुन्। सुरक्षित गर्नु अघि वास्तविक जोखिम र गम्भीरता पुष्टि गर्नुपर्छ।';

  @override
  String get aiAnalyzing => 'अन-डिभाइस इन्टेलिजेन्सद्वारा विश्लेषण हुँदैछ...';

  @override
  String aiSuggestedHazard(String hazard) {
    return 'सुझाइएको जोखिम: $hazard';
  }

  @override
  String aiSuggestedSeverity(String severity) {
    return 'सुझाइएको गम्भीरता: $severity';
  }

  @override
  String aiNote(String note) {
    return 'एआई अवलोकन: $note';
  }

  @override
  String get humanConfirmationTitle => 'मानव पुष्टि (अनिवार्य)';

  @override
  String get hazardType => 'जोखिमको प्रकार';

  @override
  String get severity => 'गम्भीरता';

  @override
  String get gangmanNote => 'ग्याङम्यानको फिल्ड नोट';

  @override
  String get gangmanNoteHint =>
      'अवरोध, ट्र्याक अवस्था वा माटो खसेको विवरण लेख्नुहोस्...';

  @override
  String get saveAndQueue => 'पुष्टि गरी स्थानीय रूपमा सुरक्षित गर्नुहोस्';

  @override
  String get saving => 'रिपोर्ट सुरक्षित गरिँदैछ...';

  @override
  String get savedSuccessTitle => 'रिपोर्ट स्थानीय रूपमा सुरक्षित भयो!';

  @override
  String savedSuccessMessage(String id) {
    return 'रिपोर्ट आईडी $id सुरक्षित भयो। यो स्थानीय लाममा थपिएको छ र स्टेसन नेटवर्क पाउँदा सिङ्क हुनेछ।';
  }

  @override
  String get backToHome => 'होममा फर्कनुहोस्';

  @override
  String get viewQueue => 'लाम हेर्नुहोस्';

  @override
  String get hazardSlip => 'पहिरो / हिलो';

  @override
  String get hazardRockfall => 'ढुङ्गा खसेको / भग्नावशेष';

  @override
  String get hazardBlockedDrain => 'थुनिएको नाली';

  @override
  String get hazardDamagedWall => 'क्षतिग्रस्त पर्खाल';

  @override
  String get hazardTrackDefect => 'ट्र्याक दोष / गेज समस्या';

  @override
  String get hazardVegetation => 'झाडी / बोटबिरुवा वृद्धि';

  @override
  String get hazardOther => 'अन्य जोखिम';

  @override
  String get severityLow => 'न्यून - निगरानी गर्नुहोस्';

  @override
  String get severityMedium => 'मध्यम - मर्मत आवश्यक';

  @override
  String get severityHigh => 'उच्च - गति नियन्त्रण आवश्यक';

  @override
  String get severityCritical => 'गम्भीर - ट्र्याक अवरोध / उच्च जोखिम';

  @override
  String get statusOpen => 'खुला';

  @override
  String get statusAcknowledged => 'स्वीकृत';

  @override
  String get statusInspectionRequired => 'निरीक्षण आवश्यक';

  @override
  String get statusResolved => 'समाधान भयो';

  @override
  String get syncDraft => 'ड्राफ्ट';

  @override
  String get syncPending => 'सिङ्क हुन बाँकी';

  @override
  String get syncSyncing => 'सिङ्क हुँदैछ...';

  @override
  String get syncSynced => 'सर्भरमा सिङ्क भयो';

  @override
  String get syncFailed => 'सिङ्क असफल';

  @override
  String get syncConflict => 'द्वन्द्व';

  @override
  String get syncStatusDraft => 'ड्राफ्ट';

  @override
  String get syncStatusPending => 'सिङ्क हुन बाँकी';

  @override
  String get syncStatusSyncing => 'सिङ्क हुँदैछ...';

  @override
  String get syncStatusSynced => 'सिङ्क भयो';

  @override
  String get syncStatusFailed => 'सिङ्क असफल';

  @override
  String get syncStatusConflict => 'द्वन्द्व';

  @override
  String get syncSummaryTitle => 'सिङ्क सारांश';

  @override
  String syncPendingReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिपोर्टहरू सिङ्क हुन बाँकी',
      one: '1 report waiting to sync',
      zero: '0 रिपोर्ट बाँकी',
    );
    return '$_temp0';
  }

  @override
  String syncFailedReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिपोर्टहरू असफल',
      one: '1 report failed',
      zero: '0 रिपोर्ट असफल',
    );
    return '$_temp0';
  }

  @override
  String get syncReportsSyncing => 'रिपोर्टहरू सिङ्क हुँदैछन्...';

  @override
  String get syncAllReportsSynced => 'सबै रिपोर्टहरू सिङ्क भए';

  @override
  String syncLastSuccessful(String time) {
    return 'अन्तिम सिङ्क: $time';
  }

  @override
  String get syncNoSuccessfulSync => 'अहिलेसम्म सिङ्क भएको छैन';

  @override
  String get syncOfflineSafe =>
      'अफलाइन — रिपोर्टहरू यस यन्त्रमा सुरक्षित भण्डारण गरिएका छन्।';

  @override
  String get syncWaitingForSignal => 'अफलाइन — स्टेसन सिग्नलको पर्खाइमा';

  @override
  String get syncStationSignalAvailable => 'स्टेसन सिग्नल उपलब्ध छ';

  @override
  String get syncSavedLocally => 'यस यन्त्रमा स्थानीय रूपमा सुरक्षित गरियो';

  @override
  String get syncSavedAndSynced => 'सुरक्षित गरियो र सर्भरमा सिङ्क भयो';

  @override
  String get syncFailedButSafe =>
      'केही रिपोर्टहरू सिङ्क हुन सकेनन्। तिनीहरू स्थानीय रूपमा सुरक्षित छन्।';

  @override
  String get syncNeedsAttention => 'यो रिपोर्टमा ध्यान दिन आवश्यक छ';

  @override
  String get syncErrorOffline =>
      'कुनै नेटवर्क जडान छैन। रिपोर्ट यस यन्त्रमा सुरक्षित छ।';

  @override
  String get syncErrorTimeout =>
      'स्टेसन जडानमा धेरै समय लाग्यो। रिपोर्ट स्थानीय रूपमा सुरक्षित छ।';

  @override
  String get syncErrorServerUnavailable =>
      'नियन्त्रण सेवा अस्थायी रूपमा अनुपलब्ध छ। कृपया पछि पुनः प्रयास गर्नुहोस्।';

  @override
  String get syncErrorUnauthorized =>
      'तपाईंको पहुँच समाप्त भएको छ वा अनधिकृत छ। जडान उपलब्ध भएपछि पुनः साइन इन गर्नुहोस्।';

  @override
  String get syncErrorMediaUpload =>
      'रिपोर्ट विवरण तयार थियो, तर तस्बिर अझै अपलोड हुन सकेन।';

  @override
  String get syncErrorConflict =>
      'यो रिपोर्ट अन्यत्र परिवर्तन गरिएको थियो र समीक्षा आवश्यक छ।';

  @override
  String get syncErrorUnknown =>
      'रिपोर्ट सिङ्क गर्न सकिएन। यो स्थानीय रूपमा सुरक्षित भण्डारण गरिएको छ।';

  @override
  String get aiProviderOfflineGemma => 'अफलाइन जेमा';

  @override
  String get aiProviderHeuristic => 'ह्युरिस्टिक नियमहरू';

  @override
  String get aiProviderManual => 'म्यानुअल वर्गीकरण';

  @override
  String get aiProviderOnlineGemini => 'अनलाइन जेमिनी';

  @override
  String get aiModelLabel => 'एआई मोडल';

  @override
  String get aiProviderLabel => 'एआई प्रदायक';

  @override
  String get aiLanguageLabel => 'एआई भाषा';

  @override
  String get aiConfidenceLabel => 'विश्वास स्तर';

  @override
  String get aiAdvisoryNotice =>
      'एआई सुझाव सल्लाहकार मात्र हो। ग्याङम्यान निरीक्षणद्वारा पुष्टि गरिएको।';

  @override
  String get syncNow => 'अहिले सिङ्क गर्नुहोस्';

  @override
  String get syncSuccessMessage => 'सिङ्क्रोनाइजेसन सफलतापूर्वक पूरा भयो';

  @override
  String get retrySync => 'पुनः सिङ्क प्रयास';

  @override
  String get viewSyncDetails => 'विवरण हेर्नुहोस्';

  @override
  String get today => 'आज';

  @override
  String get yesterday => 'हिजो';

  @override
  String get retry => 'पुनः प्रयास';

  @override
  String get cancel => 'रद्द';

  @override
  String get confirm => 'पुष्टि';

  @override
  String get close => 'बन्द';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा छान्नुहोस्';

  @override
  String get allFilter => 'सबै';

  @override
  String get noReportsMatchFilter =>
      'चयन गरिएको फिल्टरसँग कुनै रिपोर्ट मेल खाएन।';

  @override
  String get profileTitle => 'प्रयोगकर्ता प्रोफाइल';

  @override
  String get profileName => 'पूरा नाम';

  @override
  String get profileEmail => 'इमेल ठेगाना';

  @override
  String get profileRole => 'भूमिका';

  @override
  String get profileAssignedSection => 'तोकिएको खण्ड';

  @override
  String get profileLanguage => 'रुचाइएको भाषा';

  @override
  String get profileAccountStatus => 'खाता स्थिति';

  @override
  String get profileActive => 'सक्रिय';

  @override
  String get profileInactive => 'निष्क्रिय';

  @override
  String get profileBackToHome => 'ड्यासबोर्डमा फर्कनुहोस्';

  @override
  String get roleGangman => 'ग्याङम्यान';

  @override
  String get roleAdmin => 'सुपरभाइजर / प्रशासक';

  @override
  String get navigationHome => 'गृह';

  @override
  String get navigationMyReports => 'मेरा रिपोर्टहरू';

  @override
  String get navigationDashboard => 'ड्यासबोर्ड';

  @override
  String get navigationProfile => 'प्रोफाइल';

  @override
  String get navigationLogout => 'साइन आउट';

  @override
  String get navigationReports => 'रिपोर्टहरू';

  @override
  String get navigationUsers => 'प्रयोगकर्ताहरू';

  @override
  String get navigationBack => 'पछाडि';

  @override
  String get navigationRefresh => 'ताजा गर्नुहोस्';

  @override
  String get logoutTitle => 'साइन आउट पुष्टि गर्नुहोस्';

  @override
  String get logoutConfirmation => 'के तपाईं पक्का साइन आउट गर्न चाहनुहुन्छ?';

  @override
  String get logoutConfirm => 'साइन आउट गर्नुहोस्';

  @override
  String get logoutCancel => 'लगइन रहनुहोस्';

  @override
  String get logoutSigningOut => 'साइन आउट हुँदैछ...';

  @override
  String get logoutSuccess => 'सफलतापूर्वक साइन आउट भयो';

  @override
  String get logoutError => 'साइन आउट गर्न असफल। कृपया फेरि प्रयास गर्नुहोस्।';

  @override
  String logoutPendingReportsWarning(int count) {
    return 'तपाईंसँग सिङ्क हुन बाँकी $count रिपोर्टहरू छन्।';
  }

  @override
  String get logoutReportsRemainOnDevice =>
      'सिङ्क नभएका रिपोर्टहरू यस यन्त्रमा सुरक्षित रहनेछन् र हराउने छैनन्।';

  @override
  String get routeAccessDenied =>
      'तपाईंको भूमिकाको लागि पहुँच अस्वीकार गरिएको छ।';

  @override
  String get routeSessionRequired => 'जारी राख्न कृपया साइन इन गर्नुहोस्।';

  @override
  String get routeProfilePending =>
      'तपाईंको प्रोफाइल पर्यवेक्षकको स्वीकृतिको प्रतीक्षामा छ।';

  @override
  String get routeInactiveAccount => 'तपाईंको खाता हाल निष्क्रिय छ।';

  @override
  String get reportDetailTitle => 'निरीक्षण विवरण';

  @override
  String get reportDetailLocation => 'स्थान र ट्रयाक पङ्क्तिबद्धता';

  @override
  String reportDetailCreated(String time) {
    return 'सिर्जना: $time';
  }

  @override
  String reportDetailUpdated(String time) {
    return 'अद्यावधिक: $time';
  }

  @override
  String get reportDetailInspectionStatus => 'निरीक्षण स्थिति';

  @override
  String get reportDetailSyncStatus => 'सिङ्क स्थिति';

  @override
  String get reportDetailAiInformation => 'एआई सुझाव (सल्लाहकार)';

  @override
  String get reportDetailHumanConfirmed => 'निरीक्षकद्वारा पुष्टि गरिएको';

  @override
  String get reportDetailViewImage => 'पूर्ण तस्बिर हेर्नुहोस्';

  @override
  String get reportDetailRetrySync => 'सिङ्क्रोनाइजेसन पुनः प्रयास';

  @override
  String get reportDetailUnavailable => 'रिपोर्ट फेला परेन वा उपलब्ध छैन।';

  @override
  String get aiSettingsTitle => 'एआई र मोडल सेटिङहरू';

  @override
  String get aiModeAutomatic => 'स्वचालित (अफलाइन-पहिलो)';

  @override
  String get aiModeOfflineGemma => 'अफलाइन गेम्मा 4 E2B';

  @override
  String get aiModeOnlineGemini => 'अनलाइन जेमिनी क्लाउड';

  @override
  String get aiModeManual => 'म्यानुअल वर्गीकरण मात्र';

  @override
  String get aiOfflineGemma => 'अफलाइन गेम्मा इन्जिन';

  @override
  String get aiGemmaModelName => 'गेम्मा 4 E2B';

  @override
  String get aiGemmaReady => 'मोडल तयार (उपकरणमा)';

  @override
  String get aiGemmaLoading => 'गेम्मा मोडल लोड हुँदैछ...';

  @override
  String get aiGemmaUnavailable => 'अफलाइन मोडल उपलब्ध छैन';

  @override
  String get aiGemmaFailed => 'अफलाइन मोडल लोड हुन असफल';

  @override
  String get aiGemini => 'जेमिनी क्लाउड रिजनिङ';

  @override
  String get aiGeminiRequiresNetwork =>
      'अनलाइन जेमिनीका लागि सक्रिय नेटवर्क आवश्यक छ';

  @override
  String get aiGeminiUnavailable => 'अनलाइन जेमिनी सेवा अनुपलब्ध';

  @override
  String get aiProviderUsed => 'वास्तविक प्रदायक';

  @override
  String get aiRequestedProvider => 'अनुरोध गरिएको प्रदायक';

  @override
  String get aiModelName => 'मोडलको नाम';

  @override
  String get aiPromptLanguage => 'प्रम्प्ट भाषा';

  @override
  String get aiConfidence => 'मोडल विश्वास';

  @override
  String get aiFallbackReason => 'फलब्याकको कारण';

  @override
  String get aiHumanConfirmationRequired => 'मानव पुष्टि अनिवार्य';

  @override
  String get aiAnalyzingOffline => 'अफलाइन गेम्मा 4 E2B बाट विश्लेषण हुँदैछ...';

  @override
  String get aiAnalyzingOnline => 'अनलाइन जेमिनी क्लाउडबाट विश्लेषण हुँदैछ...';

  @override
  String get aiManualClassification =>
      'एआई बाइपास गरियो। म्यानुअल निरीक्षण मान लागू गरियो।';

  @override
  String get aiInvalidResult =>
      'एआई नतिजा प्रमाणीकरण हुन सकेन। कृपया म्यानुअल समीक्षा गर्नुहोस्।';

  @override
  String get aiValidationFailed =>
      'एआई आउटपुट सुरक्षा वा स्कीमा प्रमाणीकरणमा असफल भयो।';

  @override
  String get aiModelInitializationFailed =>
      'अफलाइन गेम्मा रनटाइम सुरु गर्न असफल भयो।';

  @override
  String get aiInferenceFailed => 'एआई मोडल अनुमान निष्पादन असफल भयो।';

  @override
  String get aiOnlineRequestFailed => 'अनलाइन एआई ब्याकइन्ड अनुरोध असफल भयो।';

  @override
  String get aiRateLimited =>
      'एआई सेवा दर सीमा पुग्यो। कृपया पछि पुनः प्रयास गर्नुहोस्।';

  @override
  String get aiTimeout =>
      'एआई विश्लेषण समय समाप्त भयो। रिपोर्ट म्यानुअल रूपमा वर्गीकृत गरिनेछ।';

  @override
  String get aiImageTooLarge =>
      'तस्बिर विश्लेषणका लागि धेरै ठूलो छ। कम्प्रेस गरिएको संस्करण प्रयोग गरिनेछ।';

  @override
  String get aiPrivacyNotice =>
      'अन-डिभाइस गेम्मा मोडलहरूले बाह्य क्लाउड सर्भरमा डेटा नपठाई स्थानीय रूपमा तस्बिरहरू प्रशोधन गर्छन्।';

  @override
  String get aiOfflineFirstNotice =>
      'उपलब्ध हुँदा निजी अन-डिभाइस गेम्मा, कनेक्ट हुँदा क्लाउड जेमिनी, वा ह्युरिस्टिक नियमहरू प्रयोग गर्दछ।';

  @override
  String get aiRetryAnalysis => 'एआई विश्लेषण पुनः प्रयास';

  @override
  String get aiUseManualClassification => 'म्यानुअलमा स्विच गर्नुहोस्';

  @override
  String get aiActualProvider => 'सक्रिय प्रदायक';

  @override
  String get offlineModelDownloadTitle => 'गेम्मा 4 E2B डाउनलोड';

  @override
  String get offlineModelDownload => 'मोडल डाउनलोड गर्नुहोस्';

  @override
  String get offlineModelNotDownloaded => 'मोडल डाउनलोड गरिएको छैन';

  @override
  String get offlineModelDownloading => 'गेम्मा 4 E2B डाउनलोड हुँदैछ';

  @override
  String get offlineModelDownloaded => 'गेम्मा 4 E2B डाउनलोड सम्पन्न';

  @override
  String get offlineModelReady => 'गेम्मा 4 E2B तयार छ';

  @override
  String get offlineModelInitializing => 'मोडल रनटाइम सुरु हुँदैछ...';

  @override
  String get offlineModelFailed => 'मोडल डाउनलोड असफल भयो';

  @override
  String get offlineModelUnsupported =>
      'यन्त्रले स्थानीय मोडल कार्यान्वयनलाई समर्थन गर्दैन';

  @override
  String offlineModelApproximateSize(String size) {
    return 'अनुमानित डाउनलोड आकार: $size';
  }

  @override
  String offlineModelStorageRequired(String size) {
    return 'आवश्यक खाली भण्डारण: $size';
  }

  @override
  String offlineModelStorageAvailable(String size) {
    return 'उपलब्ध खाली भण्डारण: $size';
  }

  @override
  String offlineModelDownloadProgress(
    String downloaded,
    String total,
    int percent,
  ) {
    return '$total मध्ये $downloaded ($percent%)';
  }

  @override
  String get offlineModelDownloadComplete => 'डाउनलोड सफलतापूर्वक सम्पन्न भयो';

  @override
  String get offlineModelDownloadFailed => 'मोडल फाइलहरू डाउनलोड गर्न असफल भयो';

  @override
  String get offlineModelInsufficientStorage =>
      'अफलाइन मोडल डाउनलोड गर्न पर्याप्त भण्डारण छैन। थप ठाउँ खाली गर्नुहोस् र पुनः प्रयास गर्नुहोस्।';

  @override
  String get offlineModelNetworkRequired =>
      'मोडल डाउनलोड गर्न नेटवर्क जडान आवश्यक छ';

  @override
  String get offlineModelWifiOnly => 'वाइफाइमा मात्र डाउनलोड गर्नुहोस्';

  @override
  String get offlineModelAllowMobileData =>
      'मोबाइल डेटामा डाउनलोड अनुमति दिनुहोस्';

  @override
  String get offlineModelMobileDataWarning =>
      'मोबाइल डेटामा ~१.२ जीबी डाउनलोड गर्दा डेटा शुल्क लाग्न सक्छ।';

  @override
  String get offlineModelCancelDownload => 'डाउनलोड रद्द गर्नुहोस्';

  @override
  String get offlineModelRetryDownload => 'डाउनलोड पुनः प्रयास गर्नुहोस्';

  @override
  String get offlineModelActivate => 'अफलाइन एआई सक्रिय गर्नुहोस्';

  @override
  String get offlineModelDelete => 'मोडल मेटाउनुहोस्';

  @override
  String get offlineModelDeleteTitle => 'गेम्मा 4 E2B मेटाउने?';

  @override
  String get offlineModelDeleteConfirmation =>
      'मोडल पुनः डाउनलोड नगरेसम्म अफलाइन एआई उपलब्ध हुने छैन। सुरक्षित गरिएका रिपोर्ट र तस्बिरहरू मेटिने छैनन्।';

  @override
  String get offlineModelDeleted => 'अफलाइन मोडल यन्त्रबाट मेटाइयो';

  @override
  String get offlineModelPrivacyNotice =>
      'तपाईंको फोनमा १००% स्थानीय रूपमा चल्छ। अफलाइन गेम्मा प्रयोग गर्दा कुनै पनि तस्बिर बाहिर जाँदैन।';

  @override
  String get offlineModelOfflineNotice =>
      'डाउनलोड भएपछि, अफलाइन गेम्माले जंगल र सुदूर ट्र्याक क्षेत्रमा शून्य नेटवर्कमा काम गर्दछ।';

  @override
  String get offlineModelReportsRemainSafe =>
      'सुरक्षित गरिएका रिपोर्ट, फोटो र ड्राफ्टहरू मोडल मेटाउँदा प्रभावित हुने छैनन्।';

  @override
  String get offlineModelUseManualFallback =>
      'मोडल अनुपलब्ध हुँदा म्यानुअल वर्गीकरण प्रयोग गर्नुहोस्।';

  @override
  String get offlineModelDownloadInProgress =>
      'मोडल डाउनलोड भइरहेको छ। कृपया एप बन्द नगर्नुहोस्।';

  @override
  String get offlineModelAlreadyDownloading => 'डाउनलोड पहिले नै जारी छ।';

  @override
  String get offlineModelCorrupted =>
      'मोडल फाइलहरू क्षतिग्रस्त देखिन्छन्। कृपया मोडल पुनः डाउनलोड गर्नुहोस्।';

  @override
  String offlineModelVersion(String version) {
    return 'संस्करण: $version';
  }

  @override
  String offlineModelDownloadedAt(String date) {
    return 'डाउनलोड गरिएको: $date';
  }

  @override
  String get offlineModelDownloadCancelled => 'मोडल डाउनलोड रद्द गरियो।';

  @override
  String get locationAccuracyPromptTitle => 'स्थान शुद्धता सुधार गर्नुहोस्';

  @override
  String get locationAccuracyPromptMessage =>
      'तपाईंको यन्त्रले सटीक स्थान जानकारी प्रदान गर्दा TrackGuard ले उत्तम काम गर्दछ।';

  @override
  String get locationAccuracyPromptSettingsHeading =>
      'आफ्नो स्थान सेटिङहरू जाँच गर्नुहोस्:';

  @override
  String get locationAccuracyPromptDeviceLocation =>
      '१. यन्त्रको स्थान (Device Location) अन गर्नुहोस्।';

  @override
  String get locationAccuracyPromptLocationAccuracy =>
      '२. उपलब्ध भएमा Google स्थान शुद्धता (Google Location Accuracy) सक्षम गर्नुहोस्।';

  @override
  String get locationAccuracyPromptExplanation =>
      'यसले खतराहरू रिपोर्ट गर्दा TrackGuard लाई अधिक सटीक स्थानहरू क्याप्चर गर्न मद्दत गर्दछ।';

  @override
  String get locationAccuracyPromptManageSettingsOr =>
      'तपाईं आफ्नो यन्त्रको स्थान सेटिङहरूमा यी सेटिङहरू व्यवस्थापन गर्न सक्नुहुन्छ।';

  @override
  String get locationAccuracyPromptNoThanks => 'अहिले होइन';

  @override
  String get locationAccuracyPromptTurnOn => 'जारी राख्नुहोस्';

  @override
  String get reportTrackHazardDescription =>
      'पहिरो, ढुङ्गा खसेको, बन्द नाली वा ट्र्याक समस्याको तस्बिर लिनुहोस्';

  @override
  String get sendNow => 'अहिले पठाउनुहोस्';

  @override
  String get viewMyReports => 'मेरा रिपोर्टहरू हेर्नुहोस्';

  @override
  String get willSendAtNextStation => 'अर्को स्टेशन सिग्नलमा स्वतः पठाइनेछ';

  @override
  String get allReportsSentToSupervisor =>
      'तपाईंका नवीनतम रिपोर्टहरू पर्यवेक्षककहाँ पुगेका छन्।';

  @override
  String get gpsLockedStatus => 'जीपीएस लक भयो';

  @override
  String get setManually => 'म्यानुअल रूपमा सेट गर्नुहोस्';

  @override
  String get startingCamera => 'क्यामेरा सुरु हुँदैछ…';

  @override
  String get retryCamera => 'क्यामेरा पुनः प्रयास गर्नुहोस्';

  @override
  String get dhrAlignment => 'डीएचआर पङ्क्तिबद्धता';

  @override
  String get savesSafelyOnPhoneFirst =>
      'पहिले तपाईंको फोनमा सुरक्षित रूपमा सुरक्षित हुन्छ।';

  @override
  String get draftMissing => 'ड्राफ्ट हराइरहेको छ';

  @override
  String get inspectionDraftCouldNotBeLoaded =>
      'निरीक्षण ड्राफ्ट लोड गर्न सकिएन।';

  @override
  String hazardReportTitle(String hazard) {
    return '$hazard रिपोर्ट';
  }

  @override
  String get statusStepSent => 'पठाइयो';

  @override
  String get statusStepSeenBySupervisor => 'पर्यवेक्षकले हेरेको';

  @override
  String get statusStepResolved => 'समाधान भयो';

  @override
  String get technicalAndAiAuditDetails => 'प्राविधिक र एआई अडिट विवरण';

  @override
  String get reportAuditInformation => 'रिपोर्ट अडिट जानकारी';

  @override
  String get noPhotoAttached => 'कुनै तस्बिर संलग्न छैन';

  @override
  String get photoNotFoundOnDevice => 'यन्त्रमा तस्बिर फेला परेन';

  @override
  String reportSource(String source, String accuracy) {
    return 'स्रोत: $source $accuracy';
  }

  @override
  String reportIdLabel(String id) {
    return 'रिपोर्ट आईडी: $id';
  }

  @override
  String get nearestWaypointBadge => 'निकटतम';

  @override
  String get allDhrAlignment => 'सबै डीएचआर पङ्क्तिबद्धता';

  @override
  String get profileIdentifier => 'प्रोफाइल पहिचानकर्ता';

  @override
  String get appAlignmentTitle => 'TrackGuard डीएचआर पङ्क्तिबद्धता';

  @override
  String get appEditionVersion => 'संस्करण १.०.० • फिल्ड अपरेसन संस्करण';

  @override
  String get adminDashboardTitle => 'TrackGuard प्रशासक';

  @override
  String get adminOverviewTab => 'सिंहावलोकन';

  @override
  String get adminReportsTab => 'रिपोर्टहरू';

  @override
  String get adminUsersTab => 'प्रयोगकर्ताहरू';

  @override
  String get adminReportOverview => 'रिपोर्ट सिंहावलोकन';

  @override
  String get adminSectionSummary => 'खण्ड सारांश';

  @override
  String get adminLatestReports => 'पछिल्ला रिपोर्टहरू';

  @override
  String get adminTotalReports => 'कुल रिपोर्टहरू';

  @override
  String get adminNoRemoteReportsFound => 'कुनै दुर्गम रिपोर्ट फेला परेन।';

  @override
  String get adminNoProfilesFound => 'कुनै प्रोफाइल फेला परेन।';

  @override
  String get adminProfileUpdated => 'प्रोफाइल अपडेट भयो';

  @override
  String adminUpdateFailed(String error) {
    return 'अपडेट असफल भयो: $error';
  }

  @override
  String get adminRoleLabel => 'भूमिका';

  @override
  String get adminAssignedSection => 'तोकिएको खण्ड';

  @override
  String get adminStatusUpdated =>
      'स्थिति अपडेट भयो। तल अडिट इतिहास हेर्नुहोस्।';

  @override
  String adminStatusUpdateFailed(String error) {
    return 'स्थिति अपडेट असफल भयो: $error';
  }

  @override
  String get adminReportDetailTitle => 'प्रशासक रिपोर्ट विवरण';

  @override
  String get adminReportNotFound =>
      'रिपोर्ट फेला परेन वा पहुँच अस्वीकार गरियो।';

  @override
  String adminSeverityLabel(String severity) {
    return 'गम्भीरता: $severity';
  }

  @override
  String adminSectionLabel(String section) {
    return 'खण्ड: $section';
  }

  @override
  String adminStationLabel(String station) {
    return 'स्टेशन: $station';
  }

  @override
  String adminKmMarkerLabel(String km) {
    return 'किमी मार्कर: $km';
  }

  @override
  String adminCreatedLabel(String created) {
    return 'सिर्जना गरिएको: $created';
  }

  @override
  String adminGpsLabel(String lat, String lng) {
    return 'जीपीएस: $lat, $lng';
  }

  @override
  String get adminUpdateStatusHeading => 'स्थिति अपडेट गर्नुहोस्';

  @override
  String get adminInspectionStatusLabel => 'निरीक्षण स्थिति';

  @override
  String get adminSaveStatusButton => 'स्थिति सुरक्षित गर्नुहोस्';

  @override
  String get adminSavingStatus => 'सुरक्षित गर्दै…';

  @override
  String get adminAuditHistoryHeading => 'अडिट इतिहास';

  @override
  String adminCouldNotLoadHistory(String error) {
    return 'इतिहास लोड गर्न सकिएन: $error';
  }

  @override
  String get adminNoStatusChangesYet =>
      'अहिलेसम्म कुनै स्थिति परिवर्तन रेकर्ड गरिएको छैन।';

  @override
  String get adminLoadingPhoto => 'निरीक्षण तस्बिर लोड हुँदैछ...';

  @override
  String get adminNoPhotoAvailable =>
      'यस रिपोर्टको लागि कुनै निरीक्षण तस्बिर उपलब्ध छैन';

  @override
  String get adminFailedToLoadImage => 'भण्डारणबाट छवि लोड गर्न असफल भयो';

  @override
  String get adminTapToEnlarge => 'ठूलो बनाउन ट्याप गर्नुहोस्';

  @override
  String get adminInspectionPhotoBadge => 'निरीक्षण तस्बिर';

  @override
  String get adminHazardPhotoTitle => 'खतरा तस्बिर';

  @override
  String get adminFailedToLoadFullImage => 'पूर्ण छवि लोड गर्न असफल भयो';

  @override
  String get adminNotSpecified => 'तोकिएको छैन';

  @override
  String get adminActiveStatus => 'सक्रिय';

  @override
  String get adminInactiveStatus => 'निष्क्रिय';

  @override
  String adminChangedBy(String user) {
    return '$user द्वारा परिवर्तन गरिएको';
  }

  @override
  String get smartPhotoHelperTitle => 'स्मार्ट तस्बिर सहायक';

  @override
  String get aiModeAutomaticHelper => 'स्वचालित तस्बिर सहायक (सिफारिस गरिएको)';

  @override
  String get aiModeAutomaticHelperDesc =>
      'तपाईंको तस्बिरबाट खतराको प्रकार र नोट सिफारिस गर्दछ, अनलाइन वा अफलाइन।';

  @override
  String get aiModeOnlineHelper => 'अनलाइन तस्बिर सहायक';

  @override
  String get aiModeOnlineHelperDesc =>
      'जडित अनलाइन भिजन मोडल प्रयोग गर्नुहोस्; नेटवर्क जडान आवश्यक छ।';

  @override
  String get aiModeOfflineHelper => 'अफलाइन तस्बिर सहायक';

  @override
  String get aiModeOfflineHelperDesc =>
      'नेटवर्क जडान बिना डाउनलोड गरिएको गेम्मा मोडल प्रयोग गर्नुहोस्।';

  @override
  String get aiModeManualOnly => 'म्यानुअल मात्र';

  @override
  String get aiModeManualOnlyDesc =>
      'तस्बिर सिफारिसहरू बन्द गर्नुहोस्; म आफैं खतरा छनौट गर्नेछु।';

  @override
  String get offlinePhotoHelperPackTitle => 'अफलाइन तस्बिर सहायक प्याक';

  @override
  String get offlinePhotoHelperPackSubtitle =>
      'वाइफाइमा एक पटक डाउनलोड गर्नुहोस् ताकि मोबाइल सिग्नल नहुँदा पनि एपले खतराहरू सिफारिस गर्न सकोस्।';

  @override
  String get downloadOnWifiButton => 'वाइफाइमा डाउनलोड गर्नुहोस्';

  @override
  String get stayOnPage => 'यसै पृष्ठमा रहनुहोस्';

  @override
  String get cancelDownloadAndLeave => 'डाउनलोड रद्द गर्नुहोस् र छोड्नुहोस्';

  @override
  String get cancelDownloadConfirmation =>
      'यो पृष्ठ छोड्दा हालको मोडल डाउनलोड रद्द हुनेछ। के तपाईं साँच्चै रद्द गरेर छोड्न चाहनुहुन्छ?';

  @override
  String get downloadPreferencesHeading => 'डाउनलोड प्राथमिकताहरू';

  @override
  String get preventsCellularUsage => 'सेलुलर डाटा प्रयोग रोक्छ';

  @override
  String get modelStatusAndActionsHeading => 'मोडल स्थिति र कार्यहरू';

  @override
  String get onlineReadyStatus => 'अनलाइन तयार';

  @override
  String get networkRequiredStatus => 'नेटवर्क आवश्यक';

  @override
  String get installedDateLabel => 'स्थापना मिति';

  @override
  String get sourceLabel => 'स्रोत';

  @override
  String get integrationLabel => 'एकीकरण';

  @override
  String get aiInferenceError => 'एआई अनुमान त्रुटि';

  @override
  String get aiAdvisoryMetadataHeading => 'एआई सल्लाहकार मेटाडेटा';

  @override
  String get accountInactive => 'खाता निष्क्रिय';

  @override
  String get permanentWayStaff => 'स्थायी-मार्ग कर्मचारी';
}
