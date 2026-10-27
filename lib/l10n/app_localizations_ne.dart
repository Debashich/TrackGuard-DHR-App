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
}
