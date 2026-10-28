// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'ट्रैकगार्ड डीएचआर';

  @override
  String get tagline => 'दार्जिलिंग हिमालयन रेलवे ट्रैक निरीक्षण';

  @override
  String get gangman => 'गैंगमैन';

  @override
  String get admin => 'पर्यवेक्षक / एडमिन';

  @override
  String get signInTitle => 'ट्रैकगार्ड डीएचआर साइन इन';

  @override
  String get signInSubtitle => 'ट्रैक निरीक्षण और खतरा रिपोर्टिंग';

  @override
  String get signInGoogle => 'गूगल के साथ साइन इन करें';

  @override
  String get devSignInGangman => 'डेवलपर साइन इन (गैंगमैन)';

  @override
  String get devSignInAdmin => 'डेवलपर साइन इन (एडमिन)';

  @override
  String get signingIn => 'साइन इन हो रहा है...';

  @override
  String get signOut => 'साइन आउट';

  @override
  String signedInAs(String name) {
    return '$name के रूप में साइन इन हैं';
  }

  @override
  String get pendingAccessTitle => 'पहुंच स्वीकृति लंबित है';

  @override
  String get pendingAccessMessage =>
      'आपका खाता पंजीकृत हो गया है। फील्ड टूल्स का उपयोग करने से पहले अधिकृत पर्यवेक्षक को आपकी प्रोफाइल स्वीकृत करनी होगी।';

  @override
  String get inactiveAccountMessage =>
      'आपका खाता निष्क्रिय चिह्नित है। कृपया अपने अनुभाग अभियंता से संपर्क करें।';

  @override
  String get checkStatus => 'स्थिति जांचें';

  @override
  String get homeTitle => 'निरीक्षण डैशबोर्ड';

  @override
  String get newReport => 'नई रिपोर्ट';

  @override
  String get myReports => 'मेरी रिपोर्ट';

  @override
  String get pendingQueue => 'लंबित सिंक कतार';

  @override
  String pendingReportsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिपोर्ट लंबित',
      one: '1 रिपोर्ट लंबित',
      zero: '0 रिपोर्ट लंबित',
    );
    return '$_temp0';
  }

  @override
  String assignedSection(String section) {
    return 'आवंटित अनुभाग: $section';
  }

  @override
  String get unassignedSection => 'कोई अनुभाग आवंटित नहीं';

  @override
  String get onlineStatus => 'ऑनलाइन - क्लाउड सिंक तैयार';

  @override
  String get offlineStatus => 'ऑफलाइन - स्थानीय कतार सक्रिय';

  @override
  String get aiStatusReady => 'एआई विश्लेषण: तैयार (ऑफलाइन)';

  @override
  String get aiStatusHeuristic => 'एआई विश्लेषण: ह्यूरिस्टिक फॉलबैक';

  @override
  String get aiStatusUnavailable => 'एआई विश्लेषण: केवल मैन्युअल';

  @override
  String get offlineExplanation =>
      'सभी निरीक्षण रिपोर्ट आपके डिवाइस पर तुरंत सहेजी जाती हैं। जब आप कनेक्टिविटी वाले स्टेशन पर पहुंचेंगे, तो रिपोर्ट स्वचालित रूप से सिंक हो जाएंगी।';

  @override
  String get captureTitle => 'खतरे की तस्वीर लें';

  @override
  String get cameraPermissionTitle => 'कैमरा अनुमति आवश्यक';

  @override
  String get cameraPermissionMessage =>
      'ट्रैक खतरों और दीवारों के नुकसान को रिकॉर्ड करने के लिए ट्रैकगार्ड को कैमरा अनुमति चाहिए।';

  @override
  String get locationPermissionTitle => 'स्थान अनुमति आवश्यक';

  @override
  String get locationPermissionMessage =>
      'किलोमीटर मार्कर और ट्रैक अनुभाग का अनुमान लगाने के लिए सटीक जीपीएस की आवश्यकता है।';

  @override
  String get grantPermission => 'अनुमति दें';

  @override
  String get takePhoto => 'फोटो लें';

  @override
  String get retake => 'दोबारा लें';

  @override
  String get confirmPhoto => 'फोटो का उपयोग करें';

  @override
  String get switchCamera => 'कैमरा बदलें';

  @override
  String get galleryFallback => 'गैलरी से चुनें';

  @override
  String get cameraUnavailable =>
      'कैमरा अनुपलब्ध है। कृपया गैलरी का उपयोग करें।';

  @override
  String get processingImage => 'छवि संसाधित हो रही है...';

  @override
  String get locationTitle => 'स्थान और संरेखण';

  @override
  String get gpsAcquiring => 'जीपीएस सिग्नल प्राप्त हो रहा है...';

  @override
  String gpsLocked(String accuracy) {
    return 'जीपीएस लॉक (±$accuracyमी)';
  }

  @override
  String get gpsUnavailable => 'जीपीएस सिग्नल अनुपलब्ध';

  @override
  String get locationSourceGps => 'स्रोत: वास्तविक जीपीएस';

  @override
  String get locationSourceManual => 'स्रोत: मैन्युअल चयन';

  @override
  String get locationSourceFallback => 'स्रोत: अनुमानित फॉलबैक';

  @override
  String kmMarker(String marker) {
    return 'किमी $marker';
  }

  @override
  String nearestStation(String station) {
    return 'निकटतम स्टेशन: $station';
  }

  @override
  String get selectWaypoint => 'निकटतम डीएचआर स्टेशन / वेपॉइंट चुनें';

  @override
  String get editKm => 'किमी मार्कर संपादित करें';

  @override
  String get manualLocationNotice =>
      'चेतावनी: फॉलबैक निर्देशांक अनुमानित हैं। यदि आवश्यक हो तो किमी मार्कर मैन्युअल रूप से बदलें।';

  @override
  String get reviewTitle => 'समीक्षा और पुष्टि करें';

  @override
  String get aiSuggestionTitle => 'एआई सलाहकार सुझाव';

  @override
  String get aiDisclaimer =>
      'एआई सुझाव केवल सलाहकारी हैं। सहेजने से पहले वास्तविक खतरे और गंभीरता की पुष्टि अवश्य करें।';

  @override
  String get aiAnalyzing => 'ऑन-डिवाइस इंटेलिजेंस के साथ विश्लेषण हो रहा है...';

  @override
  String aiSuggestedHazard(String hazard) {
    return 'सुझाया गया खतरा: $hazard';
  }

  @override
  String aiSuggestedSeverity(String severity) {
    return 'सुझाई गई गंभीरता: $severity';
  }

  @override
  String aiNote(String note) {
    return 'एआई अवलोकन: $note';
  }

  @override
  String get humanConfirmationTitle => 'मानव पुष्टि (अनिवार्य)';

  @override
  String get hazardType => 'खतरे का प्रकार';

  @override
  String get severity => 'गंभीरता';

  @override
  String get gangmanNote => 'गैंगमैन फील्ड नोट';

  @override
  String get gangmanNoteHint => 'अवरोध, ट्रैक निकासी या ढलान का विवरण लिखें...';

  @override
  String get saveAndQueue => 'पुष्टि करें और स्थानीय रूप से सहेजें';

  @override
  String get saving => 'रिपोर्ट सहेजी जा रही है...';

  @override
  String get savedSuccessTitle => 'रिपोर्ट स्थानीय रूप से सहेजी गई!';

  @override
  String savedSuccessMessage(String id) {
    return 'रिपोर्ट आईडी $id के साथ सहेजी गई। यह स्थानीय कतार में जुड़ गई है और स्टेशन कनेक्टिविटी मिलने पर सिंक होगी।';
  }

  @override
  String get backToHome => 'होम पर वापस जाएं';

  @override
  String get viewQueue => 'कतार देखें';

  @override
  String get hazardSlip => 'भूस्खलन / कीचड़';

  @override
  String get hazardRockfall => 'चट्टान गिरना / मलबा';

  @override
  String get hazardBlockedDrain => 'अवरुद्ध नाली (कैचवाटर)';

  @override
  String get hazardDamagedWall => 'क्षतिग्रस्त रिटेनिंग वॉल';

  @override
  String get hazardTrackDefect => 'ट्रैक दोष / गेज प्रसार';

  @override
  String get hazardVegetation => 'वनस्पति / झाड़ी अतिवृद्धि';

  @override
  String get hazardOther => 'अन्य खतरा';

  @override
  String get severityLow => 'निम्न - निगरानी करें';

  @override
  String get severityMedium => 'मध्यम - रखरखाव आवश्यक';

  @override
  String get severityHigh => 'उच्च - गति प्रतिबंध आवश्यक';

  @override
  String get severityCritical => 'गंभीर - ट्रैक अवरोध / खतरा';

  @override
  String get statusOpen => 'खुला';

  @override
  String get statusAcknowledged => 'स्वीकृत';

  @override
  String get statusInspectionRequired => 'निरीक्षण आवश्यक';

  @override
  String get statusResolved => 'समाधान किया गया';

  @override
  String get syncDraft => 'प्रारूप';

  @override
  String get syncPending => 'सिंक लंबित';

  @override
  String get syncSyncing => 'सिंक हो रहा है...';

  @override
  String get syncSynced => 'सर्वर पर सिंक किया गया';

  @override
  String get syncFailed => 'सिंक विफल';

  @override
  String get syncConflict => 'विवाद';

  @override
  String get syncStatusDraft => 'प्रारूप';

  @override
  String get syncStatusPending => 'सिंक लंबित';

  @override
  String get syncStatusSyncing => 'सिंक हो रहा है...';

  @override
  String get syncStatusSynced => 'सिंक किया गया';

  @override
  String get syncStatusFailed => 'सिंक विफल';

  @override
  String get syncStatusConflict => 'विवाद';

  @override
  String get syncSummaryTitle => 'सिंक सारांश';

  @override
  String syncPendingReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिपोर्ट सिंक की प्रतीक्षा में',
      one: '1 रिपोर्ट सिंक की प्रतीक्षा में',
      zero: '0 रिपोर्ट प्रतीक्षारत',
    );
    return '$_temp0';
  }

  @override
  String syncFailedReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रिपोर्ट विफल',
      one: '1 रिपोर्ट विफल',
      zero: '0 रिपोर्ट विफल',
    );
    return '$_temp0';
  }

  @override
  String get syncReportsSyncing => 'रिपोर्ट सिंक हो रही हैं...';

  @override
  String get syncAllReportsSynced => 'सभी रिपोर्ट सिंक हो गईं';

  @override
  String syncLastSuccessful(String time) {
    return 'अंतिम सिंक: $time';
  }

  @override
  String get syncNoSuccessfulSync => 'अभी तक सिंक नहीं हुआ';

  @override
  String get syncOfflineSafe =>
      'ऑफ़लाइन — रिपोर्ट इस डिवाइस पर सुरक्षित रूप से संग्रहीत हैं।';

  @override
  String get syncWaitingForSignal => 'ऑफ़लाइन — स्टेशन सिग्नल की प्रतीक्षा में';

  @override
  String get syncStationSignalAvailable => 'स्टेशन सिग्नल उपलब्ध है';

  @override
  String get syncSavedLocally => 'इस डिवाइस पर स्थानीय रूप से सहेजा गया';

  @override
  String get syncSavedAndSynced => 'सहेजा गया और सर्वर पर सिंक किया गया';

  @override
  String get syncFailedButSafe =>
      'कुछ रिपोर्ट सिंक नहीं हो सकीं। वे स्थानीय रूप से सुरक्षित हैं।';

  @override
  String get syncNeedsAttention => 'इस रिपोर्ट पर ध्यान देने की आवश्यकता है';

  @override
  String get syncErrorOffline =>
      'कोई नेटवर्क कनेक्शन नहीं है। रिपोर्ट इस डिवाइस पर सुरक्षित है।';

  @override
  String get syncErrorTimeout =>
      'स्टेशन कनेक्शन में बहुत समय लगा। रिपोर्ट स्थानीय रूप से सहेजी गई है।';

  @override
  String get syncErrorServerUnavailable =>
      'नियंत्रण सेवा अस्थायी रूप से अनुपलब्ध है। कृपया बाद में पुनः प्रयास करें।';

  @override
  String get syncErrorUnauthorized =>
      'आपकी पहुंच समाप्त हो गई है या अनधिकृत है। कनेक्टिविटी उपलब्ध होने पर पुनः साइन इन करें।';

  @override
  String get syncErrorMediaUpload =>
      'रिपोर्ट विवरण तैयार किए गए थे, लेकिन फोटो अभी तक अपलोड नहीं हो सकी।';

  @override
  String get syncErrorConflict =>
      'यह रिपोर्ट कहीं और बदली गई थी और इसकी समीक्षा आवश्यक है।';

  @override
  String get syncErrorUnknown =>
      'रिपोर्ट सिंक नहीं की जा सकी। यह स्थानीय रूप से सुरक्षित रूप से संग्रहीत है।';

  @override
  String get aiProviderOfflineGemma => 'ऑफ़लाइन जेमा';

  @override
  String get aiProviderHeuristic => 'ह्यूरिस्टिक नियम';

  @override
  String get aiProviderManual => 'मैनुअल वर्गीकरण';

  @override
  String get aiProviderOnlineGemini => 'ऑनलाइन जेमिनी';

  @override
  String get aiModelLabel => 'एआई मॉडल';

  @override
  String get aiProviderLabel => 'एआई प्रदाता';

  @override
  String get aiLanguageLabel => 'एआई भाषा';

  @override
  String get aiConfidenceLabel => 'विश्वास स्तर';

  @override
  String get aiAdvisoryNotice =>
      'एआई सुझाव केवल सलाहकारी है। गैंगमैन द्वारा निरीक्षण की पुष्टि की गई।';

  @override
  String get syncNow => 'अभी सिंक करें';

  @override
  String get syncSuccessMessage => 'सिंक्रनाइज़ेशन सफलतापूर्वक पूरा हुआ';

  @override
  String get retrySync => 'पुनः सिंक प्रयास करें';

  @override
  String get viewSyncDetails => 'विवरण देखें';

  @override
  String get today => 'आज';

  @override
  String get yesterday => 'कल';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get close => 'बंद करें';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get allFilter => 'सभी';

  @override
  String get noReportsMatchFilter =>
      'चयनित फ़िल्टर से कोई रिपोर्ट मेल नहीं खाती।';
}
