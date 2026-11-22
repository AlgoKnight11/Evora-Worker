// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Evora-Workers';

  @override
  String get appSubtitle => 'Field Operations Portal';

  @override
  String get brandTagline => 'Greener Choices. Healthier Cities.';

  @override
  String get splashBadge => 'MUNICIPAL FIELD OPERATIONS';

  @override
  String get splashMission =>
      'Civic Resolution • Rapid Response • Sustainable Cities';

  @override
  String get splashInitializing => 'Connecting to Municipal Dispatch...';

  @override
  String get languageSelectTitle => 'Choose Your Language';

  @override
  String get languageSelectSubtitle =>
      'Select your preferred language for Evora-Workers. You can change this anytime in Profile & Help.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageEnglishSub => 'Continue in English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageHindiSub => 'हिन्दी में जारी रखें';

  @override
  String get languageContinue => 'Continue';

  @override
  String get languageSettingsTitle => 'App Language';

  @override
  String get languageSettingsSubtitle => 'Switch between English and Hindi';

  @override
  String languageChangedNotice(String language) {
    return 'Language switched to $language';
  }

  @override
  String get navOverview => 'Overview';

  @override
  String get navOverviewFull => 'My Overview';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navTasksFull => 'My Tasks';

  @override
  String get navMap => 'Map';

  @override
  String get navMapFull => 'Task Map';

  @override
  String get navNotifications => 'Alerts';

  @override
  String get navNotificationsFull => 'Notifications';

  @override
  String get navHistory => 'History';

  @override
  String get navHistoryFull => 'Task History';

  @override
  String get navProfile => 'Profile';

  @override
  String get navProfileFull => 'Profile & Help';

  @override
  String get syncOnline => 'Online';

  @override
  String get syncOffline => 'Offline';

  @override
  String get syncSyncing => 'Syncing...';

  @override
  String syncPendingCount(int count) {
    return '$count pending';
  }

  @override
  String syncLastUpdated(String time) {
    return 'Last synced $time';
  }

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusBlocked => 'Blocked';

  @override
  String get statusSubmittedForReview => 'Pending Review';

  @override
  String get statusReturned => 'Returned';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusReassigned => 'Reassigned';

  @override
  String get priorityP1 => 'P1 Critical';

  @override
  String get priorityP2 => 'P2 High';

  @override
  String get priorityP3 => 'P3 Normal';

  @override
  String get priorityP4 => 'P4 Low';

  @override
  String get stateLoadingTitle => 'Loading data...';

  @override
  String get stateLoadingSubtitle =>
      'Fetching your latest municipal task updates.';

  @override
  String get stateEmptyTitle => 'Nothing here yet';

  @override
  String get stateEmptySubtitle =>
      'Assigned items will appear here once dispatched.';

  @override
  String get stateErrorTitle => 'Something went wrong';

  @override
  String get stateErrorSubtitle =>
      'Unable to load records right now. Please try again.';

  @override
  String get stateOfflineTitle => 'Working offline';

  @override
  String get stateOfflineSubtitle =>
      'Showing authorized cached data. Actions will sync automatically once reconnected.';

  @override
  String get statePermissionDeniedTitle => 'Access restricted';

  @override
  String get statePermissionDeniedSubtitle =>
      'You do not have permission to view this scope. Contact your supervisor.';

  @override
  String get stateStaleDataTitle => 'Cached snapshot';

  @override
  String get stateStaleDataSubtitle =>
      'Data may be outdated. Pull to refresh when online.';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get overviewGreeting => 'Ready for field duty';

  @override
  String get overviewTodayTasks => 'Today\'s Tasks';

  @override
  String get overviewUrgentWork => 'Urgent / P1';

  @override
  String get overviewOverdueTasks => 'Overdue';

  @override
  String get overviewPendingSync => 'Pending Sync';

  @override
  String get overviewAssignedAction => 'Assigned';

  @override
  String get overviewInProgress => 'In Progress';

  @override
  String get overviewBlockedAlert => 'Blocked';

  @override
  String get overviewUrgentDispatchTitle => 'Urgent Dispatch Queue';

  @override
  String get overviewUrgentEmptyTitle => 'All Clear — No Urgent Bottlenecks';

  @override
  String get overviewUrgentEmptySubtitle =>
      'All assigned field work is currently within operational SLA limits.';

  @override
  String get overviewQuickActionsTitle => 'Field Shortcuts & Navigation';

  @override
  String get overviewActionViewTasks => 'Open Tasks Inbox';

  @override
  String get overviewActionOpenMap => 'View Work Route on Map';

  @override
  String get overviewClaimPoolTag => 'Team Pool Task';

  @override
  String get overviewClaimAction => 'Claim Task';

  @override
  String get overviewAcceptAction => 'Accept Task';

  @override
  String get overviewViewDetail => 'View Details';

  @override
  String get overviewControlRoomTitle => 'Municipal Control Room: 112';

  @override
  String get overviewControlRoomSubtitle =>
      'Toll-free emergency dispatch line for field hazards and equipment failure.';

  @override
  String get overviewNoticesTitle => 'Operational Notices';

  @override
  String get overviewNoticesEmpty =>
      'No active operational notices for your ward or team.';

  @override
  String get tasksSubtitle =>
      'Assigned, accepted, in-progress, blocked, and pending-review work';

  @override
  String get tasksFilterAll => 'All Work';

  @override
  String get tasksFilterIndividual => 'Individual';

  @override
  String get tasksFilterTeamPool => 'Team Pool';

  @override
  String get tasksEmptyTitle => 'No active tasks in your queue';

  @override
  String get tasksEmptySubtitle =>
      'Tasks assigned to you or your crew pool will appear here once authenticated.';

  @override
  String get tasksSearchPlaceholder =>
      'Search by title, landmark, or case ID...';

  @override
  String get tasksFilterSheetTitle => 'Filter Tasks';

  @override
  String get tasksFilterPriorityLabel => 'Priority Level';

  @override
  String get tasksFilterWardLabel => 'Ward / Service Area';

  @override
  String get tasksFilterOverdueOnly => 'Show Overdue Only';

  @override
  String get tasksFilterReset => 'Reset Filters';

  @override
  String get tasksFilterApply => 'Apply Filters';

  @override
  String get tasksTabAll => 'All';

  @override
  String get tasksTabAssigned => 'Assigned';

  @override
  String get tasksTabAccepted => 'Accepted';

  @override
  String get tasksTabInProgress => 'In Progress';

  @override
  String get tasksTabBlocked => 'Blocked';

  @override
  String get tasksTabReview => 'Review';

  @override
  String get tasksActionStartWork => 'Start Work';

  @override
  String get tasksActionContinueWork => 'Continue Work';

  @override
  String get tasksActionAccept => 'Accept';

  @override
  String get tasksActionDecline => 'Decline';

  @override
  String get tasksActionDismiss => 'Dismiss';

  @override
  String get tasksActionClaim => 'Claim Task';

  @override
  String get tasksDeclineDialogTitle => 'Decline Assignment';

  @override
  String get tasksDeclineDialogDesc =>
      'Declining returns this work order to municipal dispatch for immediate reallocation. Please select a reason:';

  @override
  String get tasksDeclineReasonOutOfArea => 'Out of assigned ward/area';

  @override
  String get tasksDeclineReasonSkillMismatch =>
      'Requires specialized equipment/skill';

  @override
  String get tasksDeclineReasonWorkload => 'Heavy active task workload';

  @override
  String get tasksDeclineReasonEquipment => 'Equipment/materials unavailable';

  @override
  String get tasksDeclineReasonSafety => 'Active safety hazard at site';

  @override
  String get tasksDeclineReasonOther => 'Other operational reason';

  @override
  String get tasksDeclineNotePlaceholder => 'Additional notes (optional)...';

  @override
  String get tasksDeclineConfirm => 'Confirm Decline';

  @override
  String get tasksCancel => 'Cancel';

  @override
  String get tasksClaimSuccess => 'Task successfully claimed into your queue';

  @override
  String get tasksAcceptSuccess =>
      'Task accepted and ready for field execution';

  @override
  String get tasksDeclineSuccess => 'Task declined and returned to dispatch';

  @override
  String get tasksDismissSuccess => 'Pool task dismissed from your feed';

  @override
  String get tasksSlaOverdue => 'SLA Breached';

  @override
  String get tasksNoMatchingTitle => 'No matching tasks found';

  @override
  String get tasksNoMatchingSubtitle =>
      'Try adjusting your search query or clearing active filters.';

  @override
  String get taskDetailTitle => 'Task Details';

  @override
  String get taskDetailNotFound => 'Task Not Found';

  @override
  String get taskDetailNotFoundSubtitle =>
      'The requested municipal task could not be located or may have been reassigned.';

  @override
  String get taskDetailBackToList => 'Back to Tasks';

  @override
  String get taskDetailLocationSection => 'Location & Coordinates';

  @override
  String get taskDetailOpenMaps => 'Show Route on Maps';

  @override
  String get taskDetailInstructionsSection => 'Work Order Instructions';

  @override
  String get taskDetailSafetySection => 'Safety Precautions';

  @override
  String get taskDetailEvidenceSection => 'Required Completion Evidence';

  @override
  String get taskDetailTimelineSection => 'Timeline & Custody';

  @override
  String get taskDetailAssignedBy => 'Assigned By';

  @override
  String get taskDetailAssignedAt => 'Assigned At';

  @override
  String get taskDetailDueAt => 'Resolution Deadline';

  @override
  String get taskDetailUpdatedAt => 'Last Updated';

  @override
  String get taskDetailSourceCivicFlow => 'CivicFlow Grievance';

  @override
  String get taskDetailSourceStandalone => 'Municipal Work Order';

  @override
  String get taskDetailWard => 'Ward';

  @override
  String get taskDetailCoordinates => 'Coordinates';

  @override
  String get taskDetailActionReady => 'Task Accepted • Ready for Field Work';

  @override
  String get taskDetailActionInProgress =>
      'Task In Progress • Field Execution Active';

  @override
  String get taskDetailActionBlocked =>
      'Task Blocked • Operational Delay Logged';

  @override
  String get taskDetailActionReview =>
      'Task Submitted • Awaiting Supervisor Review';

  @override
  String get taskDetailActionStart => 'Start Field Work';

  @override
  String get taskDetailActionPause => 'Pause Work';

  @override
  String get taskDetailActionResume => 'Resume Work';

  @override
  String get taskDetailActionPauseDialogTitle => 'Pause Field Work';

  @override
  String get taskDetailActionPauseDialogMessage =>
      'Select a reason for temporarily holding work:';

  @override
  String get taskDetailPauseReasonMeal => 'Meal or Rest Break';

  @override
  String get taskDetailPauseReasonShift => 'Shift Handover / Crew Change';

  @override
  String get taskDetailPauseReasonWeather => 'Adverse Weather Hold';

  @override
  String get taskDetailPauseReasonMaterial => 'Awaiting Materials or Tools';

  @override
  String get taskDetailPauseReasonOther => 'Other Operational Reason';

  @override
  String get taskDetailStartedSuccess => 'Work started on task.';

  @override
  String get taskDetailPausedSuccess => 'Field work paused.';

  @override
  String get taskDetailResumedSuccess => 'Field work resumed.';

  @override
  String get taskDetailPausedNotice => 'Task Work Paused';

  @override
  String get taskDetailActionReportBlocker => 'Report Blocker';

  @override
  String get taskDetailActionUnblock => 'Unblock & Resume Work';

  @override
  String get taskDetailBlockDialogTitle => 'Report Operational Blocker';

  @override
  String get taskDetailBlockDialogDesc =>
      'Reporting a blocker pauses the task, notifies municipal dispatch, and updates the citizen tracking status to Delayed with your explanation.';

  @override
  String get taskDetailBlockReasonAccess =>
      'Access Restricted (Locked gate, road barricaded)';

  @override
  String get taskDetailBlockReasonWeather =>
      'Adverse Weather (Heavy rain, snow, landslide)';

  @override
  String get taskDetailBlockReasonEquipment =>
      'Equipment Failure (Machinery breakdown, no power)';

  @override
  String get taskDetailBlockReasonMaterial =>
      'Material Unavailable (Awaiting parts or supplies)';

  @override
  String get taskDetailBlockReasonAuthority =>
      'Awaiting Authority Clearance (NOC / Police)';

  @override
  String get taskDetailBlockReasonSafety => 'Unsafe Site / Structural Hazard';

  @override
  String get taskDetailBlockReasonOther => 'Other Operational Delay';

  @override
  String get taskDetailBlockNoteLabel =>
      'Detailed Explanation (Required for Other)';

  @override
  String get taskDetailBlockNoteHint =>
      'Describe what is preventing work at the site...';

  @override
  String get taskDetailBlockConfirm => 'Confirm Blocker';

  @override
  String get taskDetailBlockSuccess =>
      'Task marked as blocked. Dispatch and citizens notified.';

  @override
  String get taskDetailUnblockSuccess =>
      'Blocker cleared. Task resumed to in-progress.';

  @override
  String get taskDetailBlockedNotice => 'Task Blocked';

  @override
  String get taskDetailBlockedNoticeSub =>
      'Civic grievance delayed on citizen portal';

  @override
  String get taskDetailSafetyCriticalAlert =>
      'Safety Hazard: If there is immediate danger to life or property, call 112 or file an emergency Safety Alert.';

  @override
  String get taskDetailActionRequestHelp => 'Request Help';

  @override
  String get taskDetailActionCallSupervisor => 'Call Supervisor';

  @override
  String get taskDetailActionCancelHelp => 'Cancel Request';

  @override
  String get taskDetailHelpDialogTitle => 'Request Supervisor Help';

  @override
  String get taskDetailHelpDialogDesc =>
      'Flag this task for supervisor advisory callback or equipment assistance without holding field work.';

  @override
  String get taskDetailHelpTypeCallback =>
      'Supervisor Callback / Phone Guidance';

  @override
  String get taskDetailHelpTypeEquipment =>
      'Heavy Machinery / Equipment Assistance';

  @override
  String get taskDetailHelpTypeManpower =>
      'Additional Crew / Manpower Reinforcement';

  @override
  String get taskDetailHelpTypeMaterial =>
      'Materials / Parts / Safety Gear Replacements';

  @override
  String get taskDetailHelpTypeOther => 'Other Municipal Guidance';

  @override
  String get taskDetailHelpNoteLabel =>
      'Specific Details or Equipment Needed (Optional)';

  @override
  String get taskDetailHelpNoteHint =>
      'e.g., Requesting backhoe loader or replacement gloves...';

  @override
  String get taskDetailHelpSubmit => 'Send Help Request';

  @override
  String get taskDetailHelpSuccess =>
      'Supervisor help requested. Work remains active.';

  @override
  String get taskDetailHelpCancelSuccess =>
      'Supervisor help request cancelled.';

  @override
  String get taskDetailHelpBannerTitle => 'Supervisor Help Requested';

  @override
  String get taskDetailHelpBannerSub =>
      'Supervisor notified • Work continues actively';

  @override
  String get safetyDialogTitle => 'Report Safety Hazard';

  @override
  String get safetyDialogDesc =>
      'High-priority life safety escalation. Out-of-band alert directly notifies emergency dispatch and supervisors.';

  @override
  String get safetyEmergencySpeedDial => 'Instant Emergency Speed Dial';

  @override
  String get safetyEmergencyCallPolice => 'Police / Emergency (112)';

  @override
  String get safetyEmergencyCallAmbulance => 'Ambulance (108)';

  @override
  String get safetyEmergencyCallFire => 'Fire Dispatch (101)';

  @override
  String get safetyEmergencyCallMunicipal => 'Control Room (1916)';

  @override
  String get safetyHazardTypeTitle => 'Hazard Classification';

  @override
  String get safetyHazardElectrical => 'Live Electrical Wire / High Voltage';

  @override
  String get safetyHazardStructural => 'Structural Collapse / Landslide';

  @override
  String get safetyHazardGasChemical => 'Toxic Gas Leak / Hazardous Chemical';

  @override
  String get safetyHazardViolence => 'Threat of Violence / Aggressive Crowd';

  @override
  String get safetyHazardTraffic => 'Traffic Collision / Highway Hazard';

  @override
  String get safetyHazardOther => 'Other Critical Life-Safety Risk';

  @override
  String get safetyRiskLevelTitle => 'Risk Level';

  @override
  String get safetyRiskCritical => 'Critical (Immediate Danger)';

  @override
  String get safetyRiskHigh => 'High (Severe Threat)';

  @override
  String get safetyNotesLabel => 'Incident Description & Immediate Threats';

  @override
  String get safetyNotesHint =>
      'Describe live danger, exact location details, or trapped personnel...';

  @override
  String get safetySubmitButton => 'Transmit Safety Alert';

  @override
  String safetySubmitSuccess(Object id) {
    return 'Safety alert #$id transmitted to emergency dispatch.';
  }

  @override
  String get safetyActionReport => 'Report Hazard';

  @override
  String get safetyBannerTitle => 'Safety Hazard Escalated';

  @override
  String get safetyBannerSubtitle =>
      'Emergency dispatch & supervisor alerted out-of-band';

  @override
  String get mapSubtitle =>
      'Assigned task pins, approved service area, and offline navigation fallback';

  @override
  String get mapServiceAreaLabel => 'Approved Service Area';

  @override
  String get mapOfflineFallbackTitle => 'Offline Navigation Support';

  @override
  String get mapOfflineFallbackDesc =>
      'In-app map, external directions link, and textual landmark directions will load here.';

  @override
  String get mapTotalTasks => 'Active Pins';

  @override
  String get mapCriticalTasks => 'Critical';

  @override
  String get mapOverdueTasks => 'Overdue';

  @override
  String get mapFilterAll => 'All Work';

  @override
  String get mapFilterAssigned => 'My Route';

  @override
  String get mapFilterUrgent => 'Urgent Only';

  @override
  String get mapTabVisual => 'Interactive Map';

  @override
  String get mapTabDirections => 'Turn-by-Turn Route';

  @override
  String get mapSelectPinPrompt =>
      'Tap any task pin to preview route and instructions';

  @override
  String get mapLaunchExternalNavigation => 'Start Navigation in Google Maps';

  @override
  String get mapNoAssignedTasks =>
      'No active tasks located in your service area.';

  @override
  String get mapWardsHeader => 'Assigned Service Wards';

  @override
  String mapStepTitle(int stop, String title) {
    return 'Stop $stop: $title';
  }

  @override
  String mapStepLandmark(String landmark) {
    return 'Near: $landmark';
  }

  @override
  String get notificationsSubtitle =>
      'New assignments, SLA reminders, supervisor feedback, and schedule changes';

  @override
  String get notificationsEmptyTitle => 'All caught up';

  @override
  String get notificationsEmptySubtitle =>
      'You have no unread dispatch alerts or supervisor review messages.';

  @override
  String get historySubtitle =>
      'Completed, returned, reassigned, and cancelled tasks';

  @override
  String get historyEmptyTitle => 'No task history yet';

  @override
  String get historyEmptySubtitle =>
      'Past outcomes and supervisor feedback will appear here after your first completion.';

  @override
  String get profileDepartmentLabel => 'Department & Team';

  @override
  String get profileDepartmentPending => 'Assigned after OTP login (Phase 2)';

  @override
  String get profileSupervisorLabel => 'Supervisor & Support';

  @override
  String get profileSupervisorPending => 'Configured per municipal tenant';

  @override
  String get profileSafetyTitle => 'Field Safety & Emergency';

  @override
  String get profileSafetyDesc =>
      'Never enter unsafe areas or work beyond assigned scope. Emergency numbers remain accessible offline.';

  @override
  String get profileEmergencyHelpline => 'Emergency Dispatch: 112';

  @override
  String get profileVersionLabel => 'Evora-Workers v1.0.0 • Phase 2 Production';

  @override
  String get authLoginTitle => 'Municipal Field Worker Sign In';

  @override
  String get authLoginSubtitle =>
      'Enter your registered mobile number to receive a secure login OTP.';

  @override
  String get authPhoneLabel => 'Mobile Number';

  @override
  String get authPhoneHint => '98765 43210';

  @override
  String get authGetOtp => 'Get Verification OTP';

  @override
  String get authSendingOtp => 'Sending SMS OTP...';

  @override
  String get authTestChip => 'Quick Test Worker (9999999999)';

  @override
  String get authRestrictedNotice =>
      'Authorized Municipal Staff Only • Self-registration is disabled.';

  @override
  String get authVerifyTitle => 'Verify One-Time Password';

  @override
  String authVerifySubtitle(String phone) {
    return 'Enter the 6-digit code sent to $phone';
  }

  @override
  String get authEditPhone => 'Change Phone Number';

  @override
  String get authVerifyButton => 'Verify & Sign In';

  @override
  String get authVerifying => 'Verifying Identity...';

  @override
  String authResendIn(int seconds) {
    return 'Resend OTP in ${seconds}s';
  }

  @override
  String get authResendButton => 'Resend OTP Code';

  @override
  String get authTestModeBanner => 'Test Mode: Use verification code 123456';

  @override
  String get authUnregisteredTitle => 'Access Restricted: Not Provisioned';

  @override
  String authUnregisteredMessage(String phone) {
    return 'The mobile number $phone is not listed in municipal field records. Contact your supervisor to activate your account.';
  }

  @override
  String get authCallSupervisor => 'Call Municipal Helpline';

  @override
  String get authBackToLogin => 'Back to Sign In';

  @override
  String get authSignOut => 'Sign Out';

  @override
  String get authSignOutConfirmTitle => 'Confirm Sign Out';

  @override
  String get authSignOutConfirmMessage =>
      'Are you sure you want to sign out? Your session on this device will end.';

  @override
  String get authCancel => 'Cancel';
}
