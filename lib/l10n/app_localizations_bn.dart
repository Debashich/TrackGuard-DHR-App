// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'ট্র্যাকগার্ড ডিএইচআর';

  @override
  String get tagline => 'দার্জিলিং হিমালয়ান রেলওয়ে ট্র্যাক পরিদর্শন';

  @override
  String get gangman => 'গ্যাংম্যান';

  @override
  String get admin => 'সুপারভাইজার / অ্যাডমিন';

  @override
  String get signInTitle => 'ট্র্যাকগার্ড ডিএইচআর সাইন ইন';

  @override
  String get signInSubtitle => 'ট্র্যাক পরিদর্শন ও বিপদ রিপোর্টিং';

  @override
  String get signInGoogle => 'গুগল দিয়ে সাইন ইন করুন';

  @override
  String get devSignInGangman => 'ডেভেলপার সাইন ইন (গ্যাংম্যান)';

  @override
  String get devSignInAdmin => 'ডেভেলপার সাইন ইন (অ্যাডমিন)';

  @override
  String get signingIn => 'সাইন ইন হচ্ছে...';

  @override
  String get signOut => 'সাইন আউট';

  @override
  String signedInAs(String name) {
    return '$name হিসেবে সাইন ইন আছেন';
  }

  @override
  String get pendingAccessTitle => 'অনুমোদন অপেক্ষমাণ';

  @override
  String get pendingAccessMessage =>
      'আপনার অ্যাকাউন্ট তৈরি হয়েছে। ফিল্ড টুল ব্যবহারের জন্য অনুমোদিত ইঞ্জিনিয়ারের প্রোফাইল অনুমোদন প্রয়োজন।';

  @override
  String get inactiveAccountMessage =>
      'আপনার অ্যাকাউন্ট নিষ্ক্রিয় রাখা হয়েছে। দয়া করে সেকশন ইঞ্জিনিয়ারের সাথে যোগাযোগ করুন।';

  @override
  String get checkStatus => 'স্ট্যাটাস দেখুন';

  @override
  String get homeTitle => 'পরিদর্শন ড্যাশবোর্ড';

  @override
  String get newReport => 'নতুন রিপোর্ট';

  @override
  String get myReports => 'আমার রিপোর্ট';

  @override
  String get pendingQueue => 'অপেক্ষমাণ সিঙ্ক কিউ';

  @override
  String pendingReportsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি রিপোর্ট অপেক্ষমাণ',
      one: '১টি রিপোর্ট অপেক্ষমাণ',
      zero: '০টি রিপোর্ট অপেক্ষমাণ',
    );
    return '$_temp0';
  }

  @override
  String assignedSection(String section) {
    return 'বরাদ্দকৃত সেকশন: $section';
  }

  @override
  String get unassignedSection => 'কোনো সেকশন বরাদ্দ নেই';

  @override
  String get onlineStatus => 'অনলাইন - ক্লাউড সিঙ্ক প্রস্তুত';

  @override
  String get offlineStatus => 'অফলাইন - লোকাল কিউ সক্রিয়';

  @override
  String get aiStatusReady => 'এআই বিশ্লেষণ: প্রস্তুত (অফলাইন)';

  @override
  String get aiStatusHeuristic => 'এআই বিশ্লেষণ: হিউরিস্টিক ফলব্যাক';

  @override
  String get aiStatusUnavailable => 'এআই বিশ্লেষণ: শুধুমাত্র ম্যানুয়াল';

  @override
  String get offlineExplanation =>
      'সব পরিদর্শন রিপোর্ট ডিভাইসে সংরক্ষণ করা হয়। স্টেশনে নেটওয়ার্ক পেলে স্বয়ংক্রিয়ভাবে সিঙ্ক হবে।';

  @override
  String get captureTitle => 'বিপদের ছবি তুলুন';

  @override
  String get cameraPermissionTitle => 'ক্যামেরা অনুমতি প্রয়োজন';

  @override
  String get cameraPermissionMessage =>
      'ট্র্যাকের বিপদ ও প্রাচীরের ক্ষতি নথিভুক্ত করতে ক্যামেরার অনুমতি দিন।';

  @override
  String get locationPermissionTitle => 'অবস্থান অনুমতি প্রয়োজন';

  @override
  String get locationPermissionMessage =>
      'কিলোমিটার মার্কার ও সেকশন নির্ণয়ের জন্য সঠিক জিপিএস আবশ্যক।';

  @override
  String get grantPermission => 'অনুমতি দিন';

  @override
  String get takePhoto => 'ছবি তুলুন';

  @override
  String get retake => 'পুনরায় তুলুন';

  @override
  String get confirmPhoto => 'ছবি ব্যবহার করুন';

  @override
  String get switchCamera => 'ক্যামেরা পরিবর্তন';

  @override
  String get galleryFallback => 'গ্যালারি থেকে নিন';

  @override
  String get cameraUnavailable =>
      'ক্যামেরা পাওয়া যাচ্ছে না। গ্যালারি ব্যবহার করুন।';

  @override
  String get processingImage => 'ছবি প্রস্তুত হচ্ছে...';

  @override
  String get locationTitle => 'অবস্থান ও ট্র্যাক লাইন';

  @override
  String get gpsAcquiring => 'জিপিএস সিগন্যাল খোঁজা হচ্ছে...';

  @override
  String gpsLocked(String accuracy) {
    return 'জিপিএস লক (±$accuracyমি)';
  }

  @override
  String get gpsUnavailable => 'জিপিএস সিগন্যাল নেই';

  @override
  String get locationSourceGps => 'উৎস: সঠিক জিপিএস';

  @override
  String get locationSourceManual => 'উৎস: ম্যানুয়াল নির্বাচন';

  @override
  String get locationSourceFallback => 'উৎস: আনুমানিক ফলব্যাক';

  @override
  String kmMarker(String marker) {
    return 'কিমি $marker';
  }

  @override
  String nearestStation(String station) {
    return 'নিকটবর্তী স্টেশন: $station';
  }

  @override
  String get selectWaypoint =>
      'নিকটবর্তী ডিএইচআর স্টেশন / ওয়েপয়েন্ট নির্বাচন করুন';

  @override
  String get editKm => 'কিমি মার্কার পরিবর্তন করুন';

  @override
  String get manualLocationNotice =>
      'সতর্কতা: ফলব্যাক স্থানাঙ্ক আনুমানিক। প্রয়োজনে কিমি পরিবর্তন করুন।';

  @override
  String get reviewTitle => 'যাচাই ও নিশ্চিতকরণ';

  @override
  String get aiSuggestionTitle => 'এআই পরামর্শ';

  @override
  String get aiDisclaimer =>
      'এআই পরামর্শ শুধুমাত্র সহায়ক। সংরক্ষণের আগে অবশ্যই মানবিক যাচাই সম্পন্ন করুন।';

  @override
  String get aiAnalyzing => 'অন-ডিভাইস এআই দিয়ে বিশ্লেষণ করা হচ্ছে...';

  @override
  String aiSuggestedHazard(String hazard) {
    return 'প্রস্তাবিত বিপদ: $hazard';
  }

  @override
  String aiSuggestedSeverity(String severity) {
    return 'প্রস্তাবিত মাত্রা: $severity';
  }

  @override
  String aiNote(String note) {
    return 'এআই পর্যবেক্ষণ: $note';
  }

  @override
  String get humanConfirmationTitle => 'মানবিক নিশ্চিতকরণ (বাধ্যতামূলক)';

  @override
  String get hazardType => 'বিপদের ধরন';

  @override
  String get severity => 'বিপদের মাত্রা';

  @override
  String get gangmanNote => 'গ্যাংম্যানের নোট';

  @override
  String get gangmanNoteHint =>
      'বাধা, ট্র্যাকের অবস্থা বা মাটির স্থানান্তর বর্ণনা করুন...';

  @override
  String get saveAndQueue => 'নিশ্চিত করে সেভ করুন';

  @override
  String get saving => 'সংরক্ষণ করা হচ্ছে...';

  @override
  String get savedSuccessTitle => 'রিপোর্ট লোকাল কিউতে সংরক্ষিত!';

  @override
  String savedSuccessMessage(String id) {
    return 'রিপোর্ট আইডি $id সফলভাবে সংরক্ষিত। নেটওয়ার্ক পেলে স্বয়ংক্রিয়ভাবে সিঙ্ক হবে।';
  }

  @override
  String get backToHome => 'হোমে ফিরুন';

  @override
  String get viewQueue => 'কিউ দেখুন';

  @override
  String get hazardSlip => 'ভূমিধস / কাদা';

  @override
  String get hazardRockfall => 'পাথর ধস / ধ্বংসাবশেষ';

  @override
  String get hazardBlockedDrain => 'আবদ্ধ ড্রেন';

  @override
  String get hazardDamagedWall => 'ক্ষতিগ্রস্ত রিটেইনিং ওয়াল';

  @override
  String get hazardTrackDefect => 'ট্র্যাক ত্রুটি / গেজ স্প্রেড';

  @override
  String get hazardVegetation => 'অতিরিক্ত ঝোপঝাড়';

  @override
  String get hazardOther => 'অন্যান্য বিপদ';

  @override
  String get severityLow => 'কম - পর্যবেক্ষণ করুন';

  @override
  String get severityMedium => 'মাঝারি - রক্ষণাবেক্ষণ প্রয়োজন';

  @override
  String get severityHigh => 'উচ্চ - গতিসীমা নিয়ন্ত্রণ প্রয়োজন';

  @override
  String get severityCritical => 'সংকটপূর্ণ - ট্র্যাক বন্ধের আশঙ্কা';

  @override
  String get statusOpen => 'উন্মুক্ত';

  @override
  String get statusAcknowledged => 'গৃহীত';

  @override
  String get statusInspectionRequired => 'পরিদর্শন আবশ্যক';

  @override
  String get statusResolved => 'সমাধান হয়েছে';

  @override
  String get syncDraft => 'খসড়া';

  @override
  String get syncPending => 'সিঙ্ক অপেক্ষমাণ';

  @override
  String get syncSyncing => 'সিঙ্ক হচ্ছে...';

  @override
  String get syncSynced => 'সার্ভারে সিঙ্ক সম্পন্ন';

  @override
  String get syncFailed => 'সিঙ্ক ব্যর্থ';

  @override
  String get syncConflict => 'দ্বন্দ্ব';

  @override
  String get syncStatusDraft => 'খসড়া';

  @override
  String get syncStatusPending => 'সিঙ্ক অপেক্ষমাণ';

  @override
  String get syncStatusSyncing => 'সিঙ্ক হচ্ছে...';

  @override
  String get syncStatusSynced => 'সিঙ্ক সম্পন্ন';

  @override
  String get syncStatusFailed => 'সিঙ্ক ব্যর্থ';

  @override
  String get syncStatusConflict => 'দ্বন্দ্ব';

  @override
  String get syncSummaryTitle => 'সিঙ্ক সারাংশ';

  @override
  String syncPendingReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি রিপোর্ট সিঙ্কের অপেক্ষায়',
      one: '1 report waiting to sync',
      zero: '0 রিপোর্ট অপেক্ষমাণ',
    );
    return '$_temp0';
  }

  @override
  String syncFailedReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি রিপোর্ট ব্যর্থ',
      one: '1 report failed',
      zero: '0 রিপোর্ট ব্যর্থ',
    );
    return '$_temp0';
  }

  @override
  String get syncReportsSyncing => 'রিপোর্ট সিঙ্ক হচ্ছে...';

  @override
  String get syncAllReportsSynced => 'সমস্ত রিপোর্ট সিঙ্ক হয়েছে';

  @override
  String syncLastSuccessful(String time) {
    return 'সর্বশেষ সিঙ্ক: $time';
  }

  @override
  String get syncNoSuccessfulSync => 'এখনও সিঙ্ক হয়নি';

  @override
  String get syncOfflineSafe =>
      'অফলাইন — রিপোর্টগুলি এই ডিভাইসে নিরাপদে সংরক্ষিত আছে।';

  @override
  String get syncWaitingForSignal => 'অফলাইন — স্টেশন সিগন্যালের অপেক্ষায়';

  @override
  String get syncStationSignalAvailable => 'স্টেশন সিগন্যাল উপলব্ধ';

  @override
  String get syncSavedLocally => 'এই ডিভাইসে স্থানীয়ভাবে সংরক্ষিত';

  @override
  String get syncSavedAndSynced => 'সংরক্ষিত এবং সার্ভারে সিঙ্ক সম্পন্ন';

  @override
  String get syncFailedButSafe =>
      'কিছু রিপোর্ট সিঙ্ক করা যায়নি। সেগুলি স্থানীয়ভাবে নিরাপদ আছে।';

  @override
  String get syncNeedsAttention => 'এই রিপোর্টে মনোযোগ প্রয়োজন';

  @override
  String get syncErrorOffline =>
      'কোনো নেটওয়ার্ক সংযোগ নেই। রিপোর্টটি এই ডিভাইসে নিরাপদ।';

  @override
  String get syncErrorTimeout =>
      'স্টেশন সংযোগে খুব বেশি সময় লেগেছে। রিপোর্টটি স্থানীয়ভাবে সংরক্ষিত।';

  @override
  String get syncErrorServerUnavailable =>
      'নিয়ন্ত্রণ পরিষেবা সাময়িকভাবে অনুপলব্ধ। অনুগ্রহ করে পরে চেষ্টা করুন।';

  @override
  String get syncErrorUnauthorized =>
      'আপনার অ্যাক্সেসের মেয়াদ শেষ বা অননুমোদিত। সংযোগ উপলব্ধ হলে পুনরায় সাইন ইন করুন।';

  @override
  String get syncErrorMediaUpload =>
      'রিপোর্টের বিবরণ প্রস্তুত ছিল, কিন্তু ছবি এখনও আপলোড করা যায়নি।';

  @override
  String get syncErrorConflict =>
      'এই রিপোর্টটি অন্যত্র পরিবর্তিত হয়েছে এবং পর্যালোচনার প্রয়োজন।';

  @override
  String get syncErrorUnknown =>
      'রিপোর্টটি সিঙ্ক করা যায়নি। এটি স্থানীয়ভাবে নিরাপদে সংরক্ষিত।';

  @override
  String get aiProviderOfflineGemma => 'অফলাইন জেমা';

  @override
  String get aiProviderHeuristic => 'হিউরিস্টিক নিয়মাবলী';

  @override
  String get aiProviderManual => 'ম্যানুয়াল শ্রেণিবিভাগ';

  @override
  String get aiProviderOnlineGemini => 'অনলাইন জেমিনি';

  @override
  String get aiModelLabel => 'এআই মডেল';

  @override
  String get aiProviderLabel => 'এআই প্রদানকারী';

  @override
  String get aiLanguageLabel => 'এআই ভাষা';

  @override
  String get aiConfidenceLabel => 'আত্মবিশ্বাসের মাত্রা';

  @override
  String get aiAdvisoryNotice =>
      'এআই পরামর্শ শুধুমাত্র নির্দেশনামূলক। গ্যাংম্যান দ্বারা পরিদর্শন নিশ্চিত।';

  @override
  String get syncNow => 'এখনই সিঙ্ক করুন';

  @override
  String get syncSuccessMessage => 'সিঙ্ক্রোনাইজেশন সফলভাবে সম্পন্ন হয়েছে';

  @override
  String get retrySync => 'পুনরায় সিঙ্ক চেষ্টা করুন';

  @override
  String get viewSyncDetails => 'বিবরণ দেখুন';

  @override
  String get today => 'আজ';

  @override
  String get yesterday => 'গতকাল';

  @override
  String get retry => 'পুনরায় চেষ্টা';

  @override
  String get cancel => 'বাতিল';

  @override
  String get confirm => 'নিশ্চিত';

  @override
  String get close => 'বন্ধ';

  @override
  String get language => 'ভাষা';

  @override
  String get selectLanguage => 'ভাষা নির্বাচন করুন';

  @override
  String get allFilter => 'সব';

  @override
  String get noReportsMatchFilter =>
      'নির্বাচিত ফিল্টারের সাথে কোনো রিপোর্ট মেলে না।';

  @override
  String get profileTitle => 'ব্যবহারকারীর প্রোফাইল';

  @override
  String get profileName => 'সম্পূর্ণ নাম';

  @override
  String get profileEmail => 'ইমেল ঠিকানা';

  @override
  String get profileRole => 'ভূমিকা';

  @override
  String get profileAssignedSection => 'বরাদ্দকৃত সেকশন';

  @override
  String get profileLanguage => 'পছন্দের ভাষা';

  @override
  String get profileAccountStatus => 'অ্যাকাউন্টের অবস্থা';

  @override
  String get profileActive => 'সক্রিয়';

  @override
  String get profileInactive => 'নিষ্ক্রিয়';

  @override
  String get profileBackToHome => 'ড্যাশবোর্ডে ফিরে যান';

  @override
  String get roleGangman => 'গ্যাংম্যান';

  @override
  String get roleAdmin => 'সুপারভাইজার / অ্যাডমিন';

  @override
  String get navigationHome => 'হোম';

  @override
  String get navigationMyReports => 'আমার রিপোর্ট';

  @override
  String get navigationDashboard => 'ড্যাশবোর্ড';

  @override
  String get navigationProfile => 'প্রোফাইল';

  @override
  String get navigationLogout => 'সাইন আউট';

  @override
  String get navigationReports => 'রিপোর্টসমূহ';

  @override
  String get navigationUsers => 'ব্যবহারকারীগণ';

  @override
  String get navigationBack => 'পেছনে';

  @override
  String get navigationRefresh => 'রিফ্রেশ';

  @override
  String get logoutTitle => 'সাইন আউট নিশ্চিত করুন';

  @override
  String get logoutConfirmation => 'আপনি কি নিশ্চিতভাবে সাইন আউট করতে চান?';

  @override
  String get logoutConfirm => 'সাইন আউট করুন';

  @override
  String get logoutCancel => 'লগইন থাকুন';

  @override
  String get logoutSigningOut => 'সাইন আউট হচ্ছে...';

  @override
  String get logoutSuccess => 'সফলভাবে সাইন আউট হয়েছে';

  @override
  String get logoutError => 'সাইন আউট ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';

  @override
  String logoutPendingReportsWarning(int count) {
    return 'আপনার $countটি রিপোর্ট সিঙ্ক করার জন্য অপেক্ষারত রয়েছে।';
  }

  @override
  String get logoutReportsRemainOnDevice =>
      'আনসিঙ্ক রিপোর্টগুলি এই ডিভাইসে নিরাপদে সংরক্ষিত থাকবে এবং মুছে যাবে না।';

  @override
  String get routeAccessDenied =>
      'আপনার ভূমিকার জন্য প্রবেশাধিকার অস্বীকার করা হয়েছে।';

  @override
  String get routeSessionRequired => 'চালিয়ে যেতে দয়া করে সাইন ইন করুন।';

  @override
  String get routeProfilePending =>
      'আপনার প্রোফাইল সুপারভাইজারের অনুমোদনের অপেক্ষায় রয়েছে।';

  @override
  String get routeInactiveAccount => 'আপনার অ্যাকাউন্টটি বর্তমানে নিষ্ক্রিয়।';

  @override
  String get reportDetailTitle => 'পরিদর্শন বিবরণ';

  @override
  String get reportDetailLocation => 'অবস্থান এবং ট্র্যাক অ্যালাইনমেন্ট';

  @override
  String reportDetailCreated(String time) {
    return 'তৈরি: $time';
  }

  @override
  String reportDetailUpdated(String time) {
    return 'আপডেট: $time';
  }

  @override
  String get reportDetailInspectionStatus => 'পরিদর্শন স্থিতি';

  @override
  String get reportDetailSyncStatus => 'সিঙ্ক স্থিতি';

  @override
  String get reportDetailAiInformation => 'এআই পরামর্শ (পরামর্শমূলক)';

  @override
  String get reportDetailHumanConfirmed => 'পরিদর্শক দ্বারা নিশ্চিত';

  @override
  String get reportDetailViewImage => 'সম্পূর্ণ ছবি দেখুন';

  @override
  String get reportDetailRetrySync => 'পুনরায় সিঙ্ক করুন';

  @override
  String get reportDetailUnavailable => 'রিপোর্ট পাওয়া যায়নি বা অনুপলব্ধ।';
}
