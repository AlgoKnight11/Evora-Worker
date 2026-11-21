import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('en'),
    Locale('hi'),
  ];

  /// Display name of the EVORA Field Worker Portal
  ///
  /// In en, this message translates to:
  /// **'Evora-Workers'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Field Operations Portal'**
  String get appSubtitle;

  /// No description provided for @brandTagline.
  ///
  /// In en, this message translates to:
  /// **'Greener Choices. Healthier Cities.'**
  String get brandTagline;

  /// No description provided for @splashBadge.
  ///
  /// In en, this message translates to:
  /// **'MUNICIPAL FIELD OPERATIONS'**
  String get splashBadge;

  /// No description provided for @splashMission.
  ///
  /// In en, this message translates to:
  /// **'Civic Resolution • Rapid Response • Sustainable Cities'**
  String get splashMission;

  /// No description provided for @splashInitializing.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Municipal Dispatch...'**
  String get splashInitializing;

  /// No description provided for @languageSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get languageSelectTitle;

  /// No description provided for @languageSelectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language for Evora-Workers. You can change this anytime in Profile & Help.'**
  String get languageSelectSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageEnglishSub.
  ///
  /// In en, this message translates to:
  /// **'Continue in English'**
  String get languageEnglishSub;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @languageHindiSub.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी में जारी रखें'**
  String get languageHindiSub;

  /// No description provided for @languageContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get languageContinue;

  /// No description provided for @languageSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get languageSettingsTitle;

  /// No description provided for @languageSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch between English and Hindi'**
  String get languageSettingsSubtitle;

  /// No description provided for @languageChangedNotice.
  ///
  /// In en, this message translates to:
  /// **'Language switched to {language}'**
  String languageChangedNotice(String language);

  /// No description provided for @navOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// No description provided for @navOverviewFull.
  ///
  /// In en, this message translates to:
  /// **'My Overview'**
  String get navOverviewFull;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navTasksFull.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get navTasksFull;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navMapFull.
  ///
  /// In en, this message translates to:
  /// **'Task Map'**
  String get navMapFull;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navNotifications;

  /// No description provided for @navNotificationsFull.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotificationsFull;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navHistoryFull.
  ///
  /// In en, this message translates to:
  /// **'Task History'**
  String get navHistoryFull;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navProfileFull.
  ///
  /// In en, this message translates to:
  /// **'Profile & Help'**
  String get navProfileFull;

  /// No description provided for @syncOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get syncOnline;

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncOffline;

  /// No description provided for @syncSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncSyncing;

  /// No description provided for @syncPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String syncPendingCount(int count);

  /// No description provided for @syncLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String syncLastUpdated(String time);

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get statusBlocked;

  /// No description provided for @statusSubmittedForReview.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get statusSubmittedForReview;

  /// No description provided for @statusReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get statusReturned;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusReassigned.
  ///
  /// In en, this message translates to:
  /// **'Reassigned'**
  String get statusReassigned;

  /// No description provided for @priorityP1.
  ///
  /// In en, this message translates to:
  /// **'P1 Critical'**
  String get priorityP1;

  /// No description provided for @priorityP2.
  ///
  /// In en, this message translates to:
  /// **'P2 High'**
  String get priorityP2;

  /// No description provided for @priorityP3.
  ///
  /// In en, this message translates to:
  /// **'P3 Normal'**
  String get priorityP3;

  /// No description provided for @priorityP4.
  ///
  /// In en, this message translates to:
  /// **'P4 Low'**
  String get priorityP4;

  /// No description provided for @stateLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get stateLoadingTitle;

  /// No description provided for @stateLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fetching your latest municipal task updates.'**
  String get stateLoadingSubtitle;

  /// No description provided for @stateEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get stateEmptyTitle;

  /// No description provided for @stateEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assigned items will appear here once dispatched.'**
  String get stateEmptySubtitle;

  /// No description provided for @stateErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get stateErrorTitle;

  /// No description provided for @stateErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load records right now. Please try again.'**
  String get stateErrorSubtitle;

  /// No description provided for @stateOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Working offline'**
  String get stateOfflineTitle;

  /// No description provided for @stateOfflineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Showing authorized cached data. Actions will sync automatically once reconnected.'**
  String get stateOfflineSubtitle;

  /// No description provided for @statePermissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access restricted'**
  String get statePermissionDeniedTitle;

  /// No description provided for @statePermissionDeniedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view this scope. Contact your supervisor.'**
  String get statePermissionDeniedSubtitle;

  /// No description provided for @stateStaleDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Cached snapshot'**
  String get stateStaleDataTitle;

  /// No description provided for @stateStaleDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Data may be outdated. Pull to refresh when online.'**
  String get stateStaleDataSubtitle;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @overviewGreeting.
  ///
  /// In en, this message translates to:
  /// **'Ready for field duty'**
  String get overviewGreeting;

  /// No description provided for @overviewTodayTasks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tasks'**
  String get overviewTodayTasks;

  /// No description provided for @overviewUrgentWork.
  ///
  /// In en, this message translates to:
  /// **'Urgent / P1'**
  String get overviewUrgentWork;

  /// No description provided for @overviewOverdueTasks.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overviewOverdueTasks;

  /// No description provided for @overviewPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending Sync'**
  String get overviewPendingSync;

  /// No description provided for @overviewAssignedAction.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get overviewAssignedAction;

  /// No description provided for @overviewInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get overviewInProgress;

  /// No description provided for @overviewBlockedAlert.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get overviewBlockedAlert;

  /// No description provided for @overviewUrgentDispatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Urgent Dispatch Queue'**
  String get overviewUrgentDispatchTitle;

  /// No description provided for @overviewUrgentEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'All Clear — No Urgent Bottlenecks'**
  String get overviewUrgentEmptyTitle;

  /// No description provided for @overviewUrgentEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'All assigned field work is currently within operational SLA limits.'**
  String get overviewUrgentEmptySubtitle;

  /// No description provided for @overviewQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Field Shortcuts & Navigation'**
  String get overviewQuickActionsTitle;

  /// No description provided for @overviewActionViewTasks.
  ///
  /// In en, this message translates to:
  /// **'Open Tasks Inbox'**
  String get overviewActionViewTasks;

  /// No description provided for @overviewActionOpenMap.
  ///
  /// In en, this message translates to:
  /// **'View Work Route on Map'**
  String get overviewActionOpenMap;

  /// No description provided for @overviewClaimPoolTag.
  ///
  /// In en, this message translates to:
  /// **'Team Pool Task'**
  String get overviewClaimPoolTag;

  /// No description provided for @overviewClaimAction.
  ///
  /// In en, this message translates to:
  /// **'Claim Task'**
  String get overviewClaimAction;

  /// No description provided for @overviewAcceptAction.
  ///
  /// In en, this message translates to:
  /// **'Accept Task'**
  String get overviewAcceptAction;

  /// No description provided for @overviewViewDetail.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get overviewViewDetail;

  /// No description provided for @overviewControlRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Municipal Control Room: 112'**
  String get overviewControlRoomTitle;

  /// No description provided for @overviewControlRoomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Toll-free emergency dispatch line for field hazards and equipment failure.'**
  String get overviewControlRoomSubtitle;

  /// No description provided for @overviewNoticesTitle.
  ///
  /// In en, this message translates to:
  /// **'Operational Notices'**
  String get overviewNoticesTitle;

  /// No description provided for @overviewNoticesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active operational notices for your ward or team.'**
  String get overviewNoticesEmpty;

  /// No description provided for @tasksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assigned, accepted, in-progress, blocked, and pending-review work'**
  String get tasksSubtitle;

  /// No description provided for @tasksFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All Work'**
  String get tasksFilterAll;

  /// No description provided for @tasksFilterIndividual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get tasksFilterIndividual;

  /// No description provided for @tasksFilterTeamPool.
  ///
  /// In en, this message translates to:
  /// **'Team Pool'**
  String get tasksFilterTeamPool;

  /// No description provided for @tasksEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No active tasks in your queue'**
  String get tasksEmptyTitle;

  /// No description provided for @tasksEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks assigned to you or your crew pool will appear here once authenticated.'**
  String get tasksEmptySubtitle;

  /// No description provided for @tasksSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search by title, landmark, or case ID...'**
  String get tasksSearchPlaceholder;

  /// No description provided for @tasksFilterSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Tasks'**
  String get tasksFilterSheetTitle;

  /// No description provided for @tasksFilterPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority Level'**
  String get tasksFilterPriorityLabel;

  /// No description provided for @tasksFilterWardLabel.
  ///
  /// In en, this message translates to:
  /// **'Ward / Service Area'**
  String get tasksFilterWardLabel;

  /// No description provided for @tasksFilterOverdueOnly.
  ///
  /// In en, this message translates to:
  /// **'Show Overdue Only'**
  String get tasksFilterOverdueOnly;

  /// No description provided for @tasksFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get tasksFilterReset;

  /// No description provided for @tasksFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get tasksFilterApply;

  /// No description provided for @tasksTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tasksTabAll;

  /// No description provided for @tasksTabAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get tasksTabAssigned;

  /// No description provided for @tasksTabAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get tasksTabAccepted;

  /// No description provided for @tasksTabInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get tasksTabInProgress;

  /// No description provided for @tasksTabBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get tasksTabBlocked;

  /// No description provided for @tasksTabReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get tasksTabReview;

  /// No description provided for @tasksActionStartWork.
  ///
  /// In en, this message translates to:
  /// **'Start Work'**
  String get tasksActionStartWork;

  /// No description provided for @tasksActionContinueWork.
  ///
  /// In en, this message translates to:
  /// **'Continue Work'**
  String get tasksActionContinueWork;

  /// No description provided for @tasksActionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get tasksActionAccept;

  /// No description provided for @tasksActionDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get tasksActionDecline;

  /// No description provided for @tasksActionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get tasksActionDismiss;

  /// No description provided for @tasksActionClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim Task'**
  String get tasksActionClaim;

  /// No description provided for @tasksDeclineDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline Assignment'**
  String get tasksDeclineDialogTitle;

  /// No description provided for @tasksDeclineDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Declining returns this work order to municipal dispatch for immediate reallocation. Please select a reason:'**
  String get tasksDeclineDialogDesc;

  /// No description provided for @tasksDeclineReasonOutOfArea.
  ///
  /// In en, this message translates to:
  /// **'Out of assigned ward/area'**
  String get tasksDeclineReasonOutOfArea;

  /// No description provided for @tasksDeclineReasonSkillMismatch.
  ///
  /// In en, this message translates to:
  /// **'Requires specialized equipment/skill'**
  String get tasksDeclineReasonSkillMismatch;

  /// No description provided for @tasksDeclineReasonWorkload.
  ///
  /// In en, this message translates to:
  /// **'Heavy active task workload'**
  String get tasksDeclineReasonWorkload;

  /// No description provided for @tasksDeclineReasonEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment/materials unavailable'**
  String get tasksDeclineReasonEquipment;

  /// No description provided for @tasksDeclineReasonSafety.
  ///
  /// In en, this message translates to:
  /// **'Active safety hazard at site'**
  String get tasksDeclineReasonSafety;

  /// No description provided for @tasksDeclineReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other operational reason'**
  String get tasksDeclineReasonOther;

  /// No description provided for @tasksDeclineNotePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Additional notes (optional)...'**
  String get tasksDeclineNotePlaceholder;

  /// No description provided for @tasksDeclineConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Decline'**
  String get tasksDeclineConfirm;

  /// No description provided for @tasksCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tasksCancel;

  /// No description provided for @tasksClaimSuccess.
  ///
  /// In en, this message translates to:
  /// **'Task successfully claimed into your queue'**
  String get tasksClaimSuccess;

  /// No description provided for @tasksAcceptSuccess.
  ///
  /// In en, this message translates to:
  /// **'Task accepted and ready for field execution'**
  String get tasksAcceptSuccess;

  /// No description provided for @tasksDeclineSuccess.
  ///
  /// In en, this message translates to:
  /// **'Task declined and returned to dispatch'**
  String get tasksDeclineSuccess;

  /// No description provided for @tasksDismissSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pool task dismissed from your feed'**
  String get tasksDismissSuccess;

  /// No description provided for @tasksSlaOverdue.
  ///
  /// In en, this message translates to:
  /// **'SLA Breached'**
  String get tasksSlaOverdue;

  /// No description provided for @tasksNoMatchingTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching tasks found'**
  String get tasksNoMatchingTitle;

  /// No description provided for @tasksNoMatchingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search query or clearing active filters.'**
  String get tasksNoMatchingSubtitle;

  /// No description provided for @taskDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Details'**
  String get taskDetailTitle;

  /// No description provided for @taskDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Task Not Found'**
  String get taskDetailNotFound;

  /// No description provided for @taskDetailNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The requested municipal task could not be located or may have been reassigned.'**
  String get taskDetailNotFoundSubtitle;

  /// No description provided for @taskDetailBackToList.
  ///
  /// In en, this message translates to:
  /// **'Back to Tasks'**
  String get taskDetailBackToList;

  /// No description provided for @taskDetailLocationSection.
  ///
  /// In en, this message translates to:
  /// **'Location & Coordinates'**
  String get taskDetailLocationSection;

  /// No description provided for @taskDetailOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Show Route on Maps'**
  String get taskDetailOpenMaps;

  /// No description provided for @taskDetailInstructionsSection.
  ///
  /// In en, this message translates to:
  /// **'Work Order Instructions'**
  String get taskDetailInstructionsSection;

  /// No description provided for @taskDetailSafetySection.
  ///
  /// In en, this message translates to:
  /// **'Safety Precautions'**
  String get taskDetailSafetySection;

  /// No description provided for @taskDetailEvidenceSection.
  ///
  /// In en, this message translates to:
  /// **'Required Completion Evidence'**
  String get taskDetailEvidenceSection;

  /// No description provided for @taskDetailTimelineSection.
  ///
  /// In en, this message translates to:
  /// **'Timeline & Custody'**
  String get taskDetailTimelineSection;

  /// No description provided for @taskDetailAssignedBy.
  ///
  /// In en, this message translates to:
  /// **'Assigned By'**
  String get taskDetailAssignedBy;

  /// No description provided for @taskDetailAssignedAt.
  ///
  /// In en, this message translates to:
  /// **'Assigned At'**
  String get taskDetailAssignedAt;

  /// No description provided for @taskDetailDueAt.
  ///
  /// In en, this message translates to:
  /// **'Resolution Deadline'**
  String get taskDetailDueAt;

  /// No description provided for @taskDetailUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get taskDetailUpdatedAt;

  /// No description provided for @taskDetailSourceCivicFlow.
  ///
  /// In en, this message translates to:
  /// **'CivicFlow Grievance'**
  String get taskDetailSourceCivicFlow;

  /// No description provided for @taskDetailSourceStandalone.
  ///
  /// In en, this message translates to:
  /// **'Municipal Work Order'**
  String get taskDetailSourceStandalone;

  /// No description provided for @taskDetailWard.
  ///
  /// In en, this message translates to:
  /// **'Ward'**
  String get taskDetailWard;

  /// No description provided for @taskDetailCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get taskDetailCoordinates;

  /// No description provided for @taskDetailActionReady.
  ///
  /// In en, this message translates to:
  /// **'Task Accepted • Ready for Field Work'**
  String get taskDetailActionReady;

  /// No description provided for @taskDetailActionInProgress.
  ///
  /// In en, this message translates to:
  /// **'Task In Progress • Field Execution Active'**
  String get taskDetailActionInProgress;

  /// No description provided for @taskDetailActionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Task Blocked • Operational Delay Logged'**
  String get taskDetailActionBlocked;

  /// No description provided for @taskDetailActionReview.
  ///
  /// In en, this message translates to:
  /// **'Task Submitted • Awaiting Supervisor Review'**
  String get taskDetailActionReview;

  /// No description provided for @mapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assigned task pins, approved service area, and offline navigation fallback'**
  String get mapSubtitle;

  /// No description provided for @mapServiceAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Approved Service Area'**
  String get mapServiceAreaLabel;

  /// No description provided for @mapOfflineFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Navigation Support'**
  String get mapOfflineFallbackTitle;

  /// No description provided for @mapOfflineFallbackDesc.
  ///
  /// In en, this message translates to:
  /// **'In-app map, external directions link, and textual landmark directions will load here.'**
  String get mapOfflineFallbackDesc;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New assignments, SLA reminders, supervisor feedback, and schedule changes'**
  String get notificationsSubtitle;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have no unread dispatch alerts or supervisor review messages.'**
  String get notificationsEmptySubtitle;

  /// No description provided for @historySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Completed, returned, reassigned, and cancelled tasks'**
  String get historySubtitle;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No task history yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Past outcomes and supervisor feedback will appear here after your first completion.'**
  String get historyEmptySubtitle;

  /// No description provided for @profileDepartmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Department & Team'**
  String get profileDepartmentLabel;

  /// No description provided for @profileDepartmentPending.
  ///
  /// In en, this message translates to:
  /// **'Assigned after OTP login (Phase 2)'**
  String get profileDepartmentPending;

  /// No description provided for @profileSupervisorLabel.
  ///
  /// In en, this message translates to:
  /// **'Supervisor & Support'**
  String get profileSupervisorLabel;

  /// No description provided for @profileSupervisorPending.
  ///
  /// In en, this message translates to:
  /// **'Configured per municipal tenant'**
  String get profileSupervisorPending;

  /// No description provided for @profileSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Field Safety & Emergency'**
  String get profileSafetyTitle;

  /// No description provided for @profileSafetyDesc.
  ///
  /// In en, this message translates to:
  /// **'Never enter unsafe areas or work beyond assigned scope. Emergency numbers remain accessible offline.'**
  String get profileSafetyDesc;

  /// No description provided for @profileEmergencyHelpline.
  ///
  /// In en, this message translates to:
  /// **'Emergency Dispatch: 112'**
  String get profileEmergencyHelpline;

  /// No description provided for @profileVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Evora-Workers v1.0.0 • Phase 2 Production'**
  String get profileVersionLabel;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Municipal Field Worker Sign In'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered mobile number to receive a secure login OTP.'**
  String get authLoginSubtitle;

  /// No description provided for @authPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'98765 43210'**
  String get authPhoneHint;

  /// No description provided for @authGetOtp.
  ///
  /// In en, this message translates to:
  /// **'Get Verification OTP'**
  String get authGetOtp;

  /// No description provided for @authSendingOtp.
  ///
  /// In en, this message translates to:
  /// **'Sending SMS OTP...'**
  String get authSendingOtp;

  /// No description provided for @authTestChip.
  ///
  /// In en, this message translates to:
  /// **'Quick Test Worker (9999999999)'**
  String get authTestChip;

  /// No description provided for @authRestrictedNotice.
  ///
  /// In en, this message translates to:
  /// **'Authorized Municipal Staff Only • Self-registration is disabled.'**
  String get authRestrictedNotice;

  /// No description provided for @authVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify One-Time Password'**
  String get authVerifyTitle;

  /// No description provided for @authVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}'**
  String authVerifySubtitle(String phone);

  /// No description provided for @authEditPhone.
  ///
  /// In en, this message translates to:
  /// **'Change Phone Number'**
  String get authEditPhone;

  /// No description provided for @authVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify & Sign In'**
  String get authVerifyButton;

  /// No description provided for @authVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying Identity...'**
  String get authVerifying;

  /// No description provided for @authResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in {seconds}s'**
  String authResendIn(int seconds);

  /// No description provided for @authResendButton.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP Code'**
  String get authResendButton;

  /// No description provided for @authTestModeBanner.
  ///
  /// In en, this message translates to:
  /// **'Test Mode: Use verification code 123456'**
  String get authTestModeBanner;

  /// No description provided for @authUnregisteredTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Restricted: Not Provisioned'**
  String get authUnregisteredTitle;

  /// No description provided for @authUnregisteredMessage.
  ///
  /// In en, this message translates to:
  /// **'The mobile number {phone} is not listed in municipal field records. Contact your supervisor to activate your account.'**
  String authUnregisteredMessage(String phone);

  /// No description provided for @authCallSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Call Municipal Helpline'**
  String get authCallSupervisor;

  /// No description provided for @authBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get authBackToLogin;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get authSignOut;

  /// No description provided for @authSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Sign Out'**
  String get authSignOutConfirmTitle;

  /// No description provided for @authSignOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out? Your session on this device will end.'**
  String get authSignOutConfirmMessage;

  /// No description provided for @authCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get authCancel;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
