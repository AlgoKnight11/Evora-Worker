// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Evora-Workers';

  @override
  String get appSubtitle => 'फील्ड संचालन पोर्टल';

  @override
  String get brandTagline => 'हरित विकल्प। स्वस्थ शहर।';

  @override
  String get splashBadge => 'नगर निगम फ़ील्ड संचालन';

  @override
  String get splashMission =>
      'नागरिक समाधान • त्वरित प्रतिक्रिया • संधारणीय शहर';

  @override
  String get splashInitializing => 'नगर निगम डिस्पैच से जुड़ रहा है...';

  @override
  String get languageSelectTitle => 'अपनी भाषा चुनें';

  @override
  String get languageSelectSubtitle =>
      'Evora-Workers के लिए अपनी पसंदीदा भाषा चुनें। आप इसे कभी भी प्रोफ़ाइल और सहायता में बदल सकते हैं।';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageEnglishSub => 'Continue in English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageHindiSub => 'हिन्दी में जारी रखें';

  @override
  String get languageContinue => 'जारी रखें';

  @override
  String get languageSettingsTitle => 'ऐप की भाषा';

  @override
  String get languageSettingsSubtitle => 'अंग्रेज़ी और हिन्दी के बीच बदलें';

  @override
  String languageChangedNotice(String language) {
    return 'भाषा $language में बदल दी गई है';
  }

  @override
  String get navOverview => 'अवलोकन';

  @override
  String get navOverviewFull => 'मेरा अवलोकन';

  @override
  String get navTasks => 'कार्य';

  @override
  String get navTasksFull => 'मेरे कार्य';

  @override
  String get navMap => 'मानचित्र';

  @override
  String get navMapFull => 'कार्य मानचित्र';

  @override
  String get navNotifications => 'सूचनाएँ';

  @override
  String get navNotificationsFull => 'सूचनाएँ';

  @override
  String get navHistory => 'इतिहास';

  @override
  String get navHistoryFull => 'कार्य इतिहास';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get navProfileFull => 'प्रोफ़ाइल और सहायता';

  @override
  String get syncOnline => 'ऑनलाइन';

  @override
  String get syncOffline => 'ऑफ़लाइन';

  @override
  String get syncSyncing => 'सिंक हो रहा है...';

  @override
  String syncPendingCount(int count) {
    return '$count लंबित';
  }

  @override
  String syncLastUpdated(String time) {
    return 'अंतिम सिंक $time';
  }

  @override
  String get statusAssigned => 'आवंटित';

  @override
  String get statusAccepted => 'स्वीकृत';

  @override
  String get statusInProgress => 'प्रगति पर';

  @override
  String get statusBlocked => 'अवरुद्ध';

  @override
  String get statusSubmittedForReview => 'समीक्षा हेतु लंबित';

  @override
  String get statusReturned => 'वापस भेजा गया';

  @override
  String get statusApproved => 'अनुमोदित';

  @override
  String get statusCancelled => 'रद्द';

  @override
  String get statusReassigned => 'पुनः आवंटित';

  @override
  String get priorityP1 => 'P1 अति आवश्यक';

  @override
  String get priorityP2 => 'P2 उच्च';

  @override
  String get priorityP3 => 'P3 सामान्य';

  @override
  String get priorityP4 => 'P4 निम्न';

  @override
  String get stateLoadingTitle => 'डेटा लोड हो रहा है...';

  @override
  String get stateLoadingSubtitle =>
      'आपके नवीनतम नगरपालिका कार्य अपडेट प्राप्त किए जा रहे हैं।';

  @override
  String get stateEmptyTitle => 'यहाँ अभी कुछ नहीं है';

  @override
  String get stateEmptySubtitle => 'कार्य आवंटित होने पर वे यहाँ दिखाई देंगे।';

  @override
  String get stateErrorTitle => 'कुछ गड़बड़ हो गई';

  @override
  String get stateErrorSubtitle =>
      'अभी रिकॉर्ड लोड नहीं हो सके। कृपया पुनः प्रयास करें।';

  @override
  String get stateOfflineTitle => 'ऑफ़लाइन कार्य मोड';

  @override
  String get stateOfflineSubtitle =>
      'अधिकृत कैश डेटा दिखाया जा रहा है। नेटवर्क आने पर कार्य स्वतः सिंक हो जाएंगे।';

  @override
  String get statePermissionDeniedTitle => 'पहुँच प्रतिबंधित';

  @override
  String get statePermissionDeniedSubtitle =>
      'आपको इस क्षेत्र को देखने की अनुमति नहीं है। अपने सुपरवाइज़र से संपर्क करें।';

  @override
  String get stateStaleDataTitle => 'कैश किया गया डेटा';

  @override
  String get stateStaleDataSubtitle =>
      'डेटा पुराना हो सकता है। ऑनलाइन होने पर रीफ़्रेश करें।';

  @override
  String get actionRetry => 'पुनः प्रयास करें';

  @override
  String get actionRefresh => 'रीफ़्रेश करें';

  @override
  String get overviewGreeting => 'फील्ड ड्यूटी के लिए तैयार';

  @override
  String get overviewTodayTasks => 'आज के कार्य';

  @override
  String get overviewUrgentWork => 'तत्काल / P1';

  @override
  String get overviewOverdueTasks => 'अतिदेय';

  @override
  String get overviewPendingSync => 'सिंक लंबित';

  @override
  String get overviewAssignedAction => 'आवंटित';

  @override
  String get overviewInProgress => 'प्रगति पर';

  @override
  String get overviewBlockedAlert => 'अवरुद्ध';

  @override
  String get overviewUrgentDispatchTitle => 'अति आवश्यक डिस्पैच कतार';

  @override
  String get overviewUrgentEmptyTitle =>
      'सब सामान्य — कोई अति आवश्यक रुकावट नहीं';

  @override
  String get overviewUrgentEmptySubtitle =>
      'सभी आवंटित कार्य वर्तमान में परिचालन समय सीमा के भीतर हैं।';

  @override
  String get overviewQuickActionsTitle => 'त्वरित शॉर्टकट और नेविगेशन';

  @override
  String get overviewActionViewTasks => 'कार्य इनबॉक्स खोलें';

  @override
  String get overviewActionOpenMap => 'मानचित्र पर मार्ग देखें';

  @override
  String get overviewClaimPoolTag => 'टीम पूल कार्य';

  @override
  String get overviewClaimAction => 'कार्य का दावा करें';

  @override
  String get overviewAcceptAction => 'कार्य स्वीकार करें';

  @override
  String get overviewViewDetail => 'विवरण देखें';

  @override
  String get overviewControlRoomTitle => 'नगर निगम कंट्रोल रूम: 112';

  @override
  String get overviewControlRoomSubtitle =>
      'फ़ील्ड खतरों और मशीनरी खराबी के लिए टोल-फ्री आपातकालीन डिस्पैच लाइन।';

  @override
  String get overviewNoticesTitle => 'संचालन सूचनाएँ';

  @override
  String get overviewNoticesEmpty =>
      'आपके वार्ड या टीम के लिए कोई सक्रिय सूचना नहीं है।';

  @override
  String get tasksSubtitle =>
      'आवंटित, स्वीकृत, प्रगति पर, अवरुद्ध और समीक्षा हेतु लंबित कार्य';

  @override
  String get tasksFilterAll => 'सभी कार्य';

  @override
  String get tasksFilterIndividual => 'व्यक्तिगत';

  @override
  String get tasksFilterTeamPool => 'टीम पूल';

  @override
  String get tasksEmptyTitle => 'आपकी कतार में कोई सक्रिय कार्य नहीं है';

  @override
  String get tasksEmptySubtitle =>
      'सत्यापन के बाद आपको या आपकी टीम को सौंपे गए कार्य यहाँ दिखाई देंगे।';

  @override
  String get tasksSearchPlaceholder =>
      'शीर्षक, लैंडमार्क या केस आईडी से खोजें...';

  @override
  String get tasksFilterSheetTitle => 'कार्य फ़िल्टर करें';

  @override
  String get tasksFilterPriorityLabel => 'प्राथमिकता स्तर';

  @override
  String get tasksFilterWardLabel => 'वार्ड / सेवा क्षेत्र';

  @override
  String get tasksFilterOverdueOnly => 'केवल समय सीमा समाप्त दिखाएं';

  @override
  String get tasksFilterReset => 'फ़िल्टर रीसेट करें';

  @override
  String get tasksFilterApply => 'फ़िल्टर लागू करें';

  @override
  String get tasksTabAll => 'सभी';

  @override
  String get tasksTabAssigned => 'सौंपा गया';

  @override
  String get tasksTabAccepted => 'स्वीकृत';

  @override
  String get tasksTabInProgress => 'प्रगति पर';

  @override
  String get tasksTabBlocked => 'अवरुद्ध';

  @override
  String get tasksTabReview => 'समीक्षा';

  @override
  String get tasksActionStartWork => 'कार्य शुरू करें';

  @override
  String get tasksActionContinueWork => 'कार्य जारी रखें';

  @override
  String get tasksActionAccept => 'स्वीकार करें';

  @override
  String get tasksActionDecline => 'अस्वीकार करें';

  @override
  String get tasksActionDismiss => 'खारिज करें';

  @override
  String get tasksActionClaim => 'दावा करें';

  @override
  String get tasksDeclineDialogTitle => 'कार्य आवंटन अस्वीकार करें';

  @override
  String get tasksDeclineDialogDesc =>
      'अस्वीकार करने पर यह कार्य आदेश नगर निगम डिस्पैच को पुनः आवंटन हेतु लौटा दिया जाएगा। कृपया कारण चुनें:';

  @override
  String get tasksDeclineReasonOutOfArea => 'आवंटित वार्ड/क्षेत्र से बाहर';

  @override
  String get tasksDeclineReasonSkillMismatch => 'विशेष उपकरण/कौशल की आवश्यकता';

  @override
  String get tasksDeclineReasonWorkload => 'सक्रिय कार्यों का भारी कार्यभार';

  @override
  String get tasksDeclineReasonEquipment => 'उपकरण/सामग्री अनुपलब्ध';

  @override
  String get tasksDeclineReasonSafety => 'साइट पर सक्रिय सुरक्षा खतरा';

  @override
  String get tasksDeclineReasonOther => 'अन्य परिचालन कारण';

  @override
  String get tasksDeclineNotePlaceholder => 'अतिरिक्त विवरण (वैकल्पिक)...';

  @override
  String get tasksDeclineConfirm => 'अस्वीकृति की पुष्टि करें';

  @override
  String get tasksCancel => 'रद्द करें';

  @override
  String get tasksClaimSuccess =>
      'कार्य सफलतापूर्वक आपकी कतार में जोड़ दिया गया';

  @override
  String get tasksAcceptSuccess => 'कार्य स्वीकृत और फ़ील्ड कार्य हेतु तैयार';

  @override
  String get tasksDeclineSuccess =>
      'कार्य अस्वीकार कर डिस्पैच को लौटा दिया गया';

  @override
  String get tasksDismissSuccess => 'पूल कार्य आपकी फ़ीड से हटा दिया गया';

  @override
  String get tasksSlaOverdue => 'समय सीमा समाप्त';

  @override
  String get tasksNoMatchingTitle => 'कोई मेल खाता कार्य नहीं मिला';

  @override
  String get tasksNoMatchingSubtitle =>
      'अपने खोज शब्दों या सक्रिय फ़िल्टर को बदलने का प्रयास करें।';

  @override
  String get taskDetailTitle => 'कार्य विवरण';

  @override
  String get taskDetailNotFound => 'कार्य नहीं मिला';

  @override
  String get taskDetailNotFoundSubtitle =>
      'अनुरोधित नगरपालिका कार्य नहीं मिला या पुनः सौंपा गया हो सकता है।';

  @override
  String get taskDetailBackToList => 'कार्यों पर वापस';

  @override
  String get taskDetailLocationSection => 'स्थान एवं निर्देशांक';

  @override
  String get taskDetailOpenMaps => 'मानचित्र पर रूट देखें';

  @override
  String get taskDetailInstructionsSection => 'कार्य आदेश निर्देश';

  @override
  String get taskDetailSafetySection => 'सुरक्षा सावधानियां';

  @override
  String get taskDetailEvidenceSection => 'आवश्यक साक्ष्य';

  @override
  String get taskDetailTimelineSection => 'समयरेखा एवं आवंटन';

  @override
  String get taskDetailAssignedBy => 'द्वारा सौंपा गया';

  @override
  String get taskDetailAssignedAt => 'सौंपने की तिथि';

  @override
  String get taskDetailDueAt => 'समाधान समय सीमा';

  @override
  String get taskDetailUpdatedAt => 'अंतिम अद्यतन';

  @override
  String get taskDetailSourceCivicFlow => 'सिविकफ्लो शिकायत';

  @override
  String get taskDetailSourceStandalone => 'नगरपालिका कार्य आदेश';

  @override
  String get taskDetailWard => 'वार्ड';

  @override
  String get taskDetailCoordinates => 'निर्देशांक';

  @override
  String get taskDetailActionReady => 'कार्य स्वीकृत • फ़ील्ड कार्य हेतु तैयार';

  @override
  String get taskDetailActionInProgress =>
      'कार्य प्रगति पर • फ़ील्ड कार्य सक्रिय';

  @override
  String get taskDetailActionBlocked => 'कार्य अवरुद्ध • परिचालन विलंब दर्ज';

  @override
  String get taskDetailActionReview =>
      'कार्य जमा किया गया • सुपरवाइज़र समीक्षा की प्रतीक्षा';

  @override
  String get mapSubtitle =>
      'आवंटित कार्य स्थान, स्वीकृत सेवा क्षेत्र और ऑफ़लाइन दिशा-निर्देश';

  @override
  String get mapServiceAreaLabel => 'स्वीकृत सेवा क्षेत्र';

  @override
  String get mapOfflineFallbackTitle => 'ऑफ़लाइन नेविगेशन सहायता';

  @override
  String get mapOfflineFallbackDesc =>
      'इन-ऐप मानचित्र, बाहरी दिशा लिंक और ऑफ़लाइन पता विवरण यहाँ लोड होंगे।';

  @override
  String get notificationsSubtitle =>
      'नए कार्य आवंटन, समय-सीमा अनुस्मारक और सुपरवाइज़र प्रतिक्रिया';

  @override
  String get notificationsEmptyTitle => 'सभी सूचनाएँ पढ़ ली गईं';

  @override
  String get notificationsEmptySubtitle =>
      'आपके पास कोई अपठित कार्य सूचना या सुपरवाइज़र संदेश नहीं है।';

  @override
  String get historySubtitle =>
      'पूर्ण, वापस किए गए, पुनः आवंटित और रद्द किए गए कार्य';

  @override
  String get historyEmptyTitle => 'अभी कोई कार्य इतिहास नहीं है';

  @override
  String get historyEmptySubtitle =>
      'पहला कार्य पूर्ण करने के बाद पिछले परिणाम और सुपरवाइज़र प्रतिक्रिया यहाँ दिखाई देंगे।';

  @override
  String get profileDepartmentLabel => 'विभाग और टीम';

  @override
  String get profileDepartmentPending => 'OTP लॉगिन के बाद आवंटित (फ़ेज़ 2)';

  @override
  String get profileSupervisorLabel => 'सुपरवाइज़र और सहायता';

  @override
  String get profileSupervisorPending => 'नगरपालिका द्वारा निर्धारित';

  @override
  String get profileSafetyTitle => 'फील्ड सुरक्षा और आपातकाल';

  @override
  String get profileSafetyDesc =>
      'असुरक्षित क्षेत्रों में न जाएँ और निर्धारित कार्य-क्षेत्र से बाहर कार्य न करें। आपातकालीन नंबर ऑफ़लाइन भी उपलब्ध हैं।';

  @override
  String get profileEmergencyHelpline => 'आपातकालीन सहायता: 112';

  @override
  String get profileVersionLabel => 'Evora-Workers v1.0.0 • फ़ेज़ 2 उत्पादन';

  @override
  String get authLoginTitle => 'नगर निगम फ़ील्ड कार्यकर्ता साइन इन';

  @override
  String get authLoginSubtitle =>
      'सुरक्षित लॉगिन ओटीपी प्राप्त करने के लिए अपना पंजीकृत मोबाइल नंबर दर्ज करें।';

  @override
  String get authPhoneLabel => 'मोबाइल नंबर';

  @override
  String get authPhoneHint => '98765 43210';

  @override
  String get authGetOtp => 'सत्यापन ओटीपी प्राप्त करें';

  @override
  String get authSendingOtp => 'एसएमएस ओटीपी भेजा जा रहा है...';

  @override
  String get authTestChip => 'त्वरित परीक्षण कार्यकर्ता (9999999999)';

  @override
  String get authRestrictedNotice =>
      'केवल अधिकृत नगर निगम कर्मचारी • स्व-पंजीकरण अक्षम है।';

  @override
  String get authVerifyTitle => 'एकमुश्त पासवर्ड सत्यापित करें';

  @override
  String authVerifySubtitle(String phone) {
    return '$phone पर भेजा गया 6-अंकीय कोड दर्ज करें';
  }

  @override
  String get authEditPhone => 'फ़ोन नंबर बदलें';

  @override
  String get authVerifyButton => 'सत्यापित करें और साइन इन करें';

  @override
  String get authVerifying => 'पहचान सत्यापित की जा रही है...';

  @override
  String authResendIn(int seconds) {
    return '${seconds}s में पुनः भेजें';
  }

  @override
  String get authResendButton => 'ओटीपी कोड पुनः भेजें';

  @override
  String get authTestModeBanner =>
      'परीक्षण मोड: सत्यापन कोड 123456 का उपयोग करें';

  @override
  String get authUnregisteredTitle => 'पहुंच प्रतिबंधित: पंजीकृत नहीं है';

  @override
  String authUnregisteredMessage(String phone) {
    return 'मोबाइल नंबर $phone नगर निगम फ़ील्ड रिकॉर्ड में सूचीबद्ध नहीं है। अपना खाता सक्रिय करने के लिए अपने सुपरवाइज़र से संपर्क करें।';
  }

  @override
  String get authCallSupervisor => 'नगर निगम हेल्पलाइन पर कॉल करें';

  @override
  String get authBackToLogin => 'साइन इन पर वापस जाएँ';

  @override
  String get authSignOut => 'साइन आउट';

  @override
  String get authSignOutConfirmTitle => 'साइन आउट की पुष्टि करें';

  @override
  String get authSignOutConfirmMessage =>
      'क्या आप वाकई साइन आउट करना चाहते हैं? इस डिवाइस पर आपका सत्र समाप्त हो जाएगा।';

  @override
  String get authCancel => 'रद्द करें';
}
