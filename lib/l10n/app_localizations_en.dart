// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get menuHome => 'Home';

  @override
  String get menuRegistration => 'New believers registration';

  @override
  String get menuCellGroup => 'Cell group';

  @override
  String get menuLeaderGroup => 'Leader registration';

  @override
  String get menuNewCell => 'Create cell group';

  @override
  String get menuCellDashboard => 'Cell statistics';

  @override
  String get menuBaptismGroup => 'Baptism';

  @override
  String get menuBaptismCalendar => 'Baptism calendar';

  @override
  String get menuBaptismDashboard => 'Baptism statistics';

  @override
  String get menuNewMember => 'New member';

  @override
  String get menuMembers => 'View new believers';

  @override
  String get menuChurchMembers => 'View members';

  @override
  String get menuByLeader => 'View new believers by leader';

  @override
  String get menuMyMembers => 'My new believers';

  @override
  String get menuMyAssignedCell => 'My cell';

  @override
  String get menuNewLeader => 'Create leader';

  @override
  String get menuLeaders => 'View leaders';

  @override
  String get menuMySupervisedLeaders => 'My assigned leaders';

  @override
  String get menuVisitsDashboard => 'Visits dashboard';

  @override
  String get menuPastoralDashboard => 'Pastoral dashboard';

  @override
  String get menuSupervisorLeaders => 'Leaders by supervisor';

  @override
  String get menuLeaderDashboard => 'Leader statistics';

  @override
  String get menuChurches => 'Churches';

  @override
  String get menuAdmins => 'Administrators';

  @override
  String get menuNewAdmin => 'New administrator';

  @override
  String get menuNotifications => 'Notifications';

  @override
  String get menuMyAccount => 'My account';

  @override
  String get menuRegisterNewMember => 'New member registration';

  @override
  String get quickNewMemberTitle => 'New member registration';

  @override
  String get quickNewMemberSubtitle => 'New member form';

  @override
  String get quickViewMembersTitle => 'View new believers';

  @override
  String get quickViewMembersSubtitle => 'List of registered new believers';

  @override
  String get quickMembersByLeaderTitle => 'View new believers by leader';

  @override
  String get quickMembersByLeaderSubtitle =>
      'New believers assigned to each leader';

  @override
  String get quickMyMembersTitle => 'My new believers';

  @override
  String get quickMyMembersSubtitle => 'Believers assigned to your visits';

  @override
  String get quickMyAssignedCellTitle => 'My assigned cell';

  @override
  String get quickMyAssignedCellSubtitle => 'Cell details and disciples';

  @override
  String get quickRegisterLeaderTitle => 'Leader registration';

  @override
  String get quickRegisterLeaderSubtitle => 'Leadership details';

  @override
  String get quickNewCellTitle => 'Create cell group';

  @override
  String get quickNewCellSubtitle => 'Register a new cell group';

  @override
  String get quickViewCellsTitle => 'View cell groups';

  @override
  String get quickViewCellsSubtitle => 'List of registered cell groups';

  @override
  String get quickBaptismCalendarTitle => 'Baptism calendar';

  @override
  String get quickBaptismCalendarSubtitle => 'View scheduled baptism dates';

  @override
  String get quickBaptismDashboardTitle => 'Baptism statistics';

  @override
  String get quickBaptismDashboardSubtitle =>
      'Baptized from believer registration';

  @override
  String get baptismDashboardTitle => 'Baptism statistics';

  @override
  String get baptismDashboardDenied =>
      'You do not have permission to view baptism statistics.';

  @override
  String get baptismDashboardLoadError => 'Could not load baptism statistics.';

  @override
  String get baptismDashboardBaptizedInPeriod => 'Baptized in period';

  @override
  String get baptismDashboardBaptizedInYear => 'Baptized in year';

  @override
  String get baptismDashboardBaptizedInMonth => 'Baptized in month';

  @override
  String get baptismDashboardNewBelieversAmongBaptized =>
      'New believers among baptized (believer registration)';

  @override
  String get baptismDashboardSelectYear => 'Year';

  @override
  String get baptismDashboardSelectMonth => 'Month';

  @override
  String get baptismDashboardAllMonths => 'Full year';

  @override
  String baptismDashboardChartTitleYear(int year) {
    return 'Baptisms per month in $year';
  }

  @override
  String get baptismDashboardChartTitle => 'Baptisms per period';

  @override
  String get baptismDashboardListTitleYear => 'Baptized in year';

  @override
  String baptismDashboardListTitleMonth(String month) {
    return 'Baptized in $month';
  }

  @override
  String get baptismDashboardListTitle => 'Baptized in period';

  @override
  String get baptismDashboardListSelectMonth =>
      'Select a month to see baptized believers.';

  @override
  String baptismDashboardListCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count baptized',
      one: '1 baptized',
    );
    return '$_temp0';
  }

  @override
  String get baptismDashboardListEmpty =>
      'No baptized believers in this period.';

  @override
  String baptismDashboardPeriodLastMonths(int count) {
    return 'Last $count months';
  }

  @override
  String baptismDashboardPeriodLastYears(int count) {
    return 'Last $count years';
  }

  @override
  String get baptismDashboardConversionHint =>
      'The baptism rate only includes believers registered from «Believer registration» (not cell or direct baptism registration). The chart uses the confirmed baptism date.';

  @override
  String get cellDashboardTitle => 'Cell statistics';

  @override
  String get cellDashboardDenied =>
      'You do not have permission to view cell statistics.';

  @override
  String get cellDashboardLoadError => 'Could not load cell statistics.';

  @override
  String get cellDashboardCreatedInYear => 'Cells created in year';

  @override
  String get cellDashboardCreatedInMonth => 'Cells created in month';

  @override
  String cellDashboardChartTitleYear(int year) {
    return 'Cells created per month in $year';
  }

  @override
  String cellDashboardListTitleMonth(String month) {
    return 'Cells created in $month';
  }

  @override
  String get cellDashboardListSelectMonth =>
      'Select a month to see cells created.';

  @override
  String cellDashboardListCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cells',
      one: '1 cell',
    );
    return '$_temp0';
  }

  @override
  String get cellDashboardListEmpty => 'No cells created in this period.';

  @override
  String get leaderDashboardTitle => 'Leader statistics';

  @override
  String get leaderDashboardDenied =>
      'You do not have permission to view leader statistics.';

  @override
  String get leaderDashboardLoadError => 'Could not load leader statistics.';

  @override
  String get leaderDashboardCreatedInYear => 'Leaders created in the year';

  @override
  String get leaderDashboardCreatedInMonth => 'Leaders created in the month';

  @override
  String get leaderDashboardFromRegisterLeader => 'From leader registration';

  @override
  String get leaderDashboardFromCell => 'From cell group';

  @override
  String leaderDashboardChartTitleYear(int year) {
    return 'Leaders created per month in $year';
  }

  @override
  String leaderDashboardListTitleMonth(String month) {
    return 'Leaders created in $month';
  }

  @override
  String get leaderDashboardListSelectMonth =>
      'Select a month to view created leaders.';

  @override
  String leaderDashboardListCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leaders',
      one: '1 leader',
    );
    return '$_temp0';
  }

  @override
  String get leaderDashboardListEmpty => 'No leaders created in this period.';

  @override
  String get leaderRegistrationSourceRegisterLeader => 'Leader registration';

  @override
  String get leaderRegistrationSourceRegisterCell => 'Cell group';

  @override
  String get quickViewLeadersTitle => 'View leaders';

  @override
  String get quickViewLeadersSubtitle => 'List of registered leaders';

  @override
  String get quickMySupervisedLeadersTitle => 'My assigned leaders';

  @override
  String get quickMySupervisedLeadersSubtitle =>
      'Leaders under your supervision';

  @override
  String get quickVisitsDashboardTitle => 'Visits dashboard';

  @override
  String get quickVisitsDashboardSubtitle =>
      'Visit charts by day, month and year';

  @override
  String get quickPastoralDashboardTitle => 'Pastoral dashboard';

  @override
  String get quickPastoralDashboardSubtitle =>
      'Follow-up, new members and prayer';

  @override
  String get quickSupervisorLeadersTitle => 'Leaders by supervisor';

  @override
  String get quickSupervisorLeadersSubtitle =>
      'Assign leader portfolios to each supervisor';

  @override
  String get quickChurchesTitle => 'Churches';

  @override
  String get quickChurchesSubtitle => 'View, edit and register locations';

  @override
  String get quickAdminsTitle => 'Administrators';

  @override
  String get quickAdminsSubtitle => 'View, edit and block accounts';

  @override
  String get quickNewAdminTitle => 'New administrator';

  @override
  String get quickNewAdminSubtitle => 'Assign a church to the administrator';

  @override
  String get signOut => 'Sign out';

  @override
  String get menuTooltip => 'Menu';

  @override
  String get welcome => 'Welcome';

  @override
  String homeWelcomeName(String name) {
    return '👋 Welcome, $name';
  }

  @override
  String get homeSummaryTitle => 'Summary';

  @override
  String homeMembersCount(int count) {
    return '👥 Assigned members: $count';
  }

  @override
  String homeLeadersCount(int count) {
    return '👥 Assigned leaders: $count';
  }

  @override
  String homeSummaryMembersCount(int count) {
    return '👥 Members: $count';
  }

  @override
  String homeSummaryNewBelieversCount(int count) {
    return '👥 New believers: $count';
  }

  @override
  String homeSummaryLeadersCount(int count) {
    return '👥 Leaders and supervisors: $count';
  }

  @override
  String homeSummaryDisciplesCount(int count) {
    return '👥 Assigned disciples: $count';
  }

  @override
  String homeSummaryAssignedNewBelieversCount(int count) {
    return '👥 Assigned new believers: $count';
  }

  @override
  String homeChurchMembersCount(String churchName, int count) {
    return '👥 Church members $churchName: $count';
  }

  @override
  String homeChurchLeadersCount(String churchName, int count) {
    return '👥 Church leaders $churchName: $count';
  }

  @override
  String get homeTodayTitle => 'Today';

  @override
  String get homeCellBirthdaysTitle => 'Today\'s birthdays in my cell';

  @override
  String get homeBirthdaysEmpty => 'No birthdays today in your cell.';

  @override
  String get homeQuickActionsTitle => 'Quick actions';

  @override
  String get homeWelcomeSubtitle => 'Thank you for leading with purpose.';

  @override
  String get homeSummarySeeDetail => 'See details';

  @override
  String get homeStatMembersTitle => 'Members';

  @override
  String get homeStatMembersSubtitle => 'Total active members';

  @override
  String get homeStatNewBelieversTitle => 'New believers';

  @override
  String get homeStatNewBelieversSubtitle => 'Registered new believers';

  @override
  String get homeStatLeadersTitle => 'Leaders';

  @override
  String get homeStatLeadersSubtitle => 'Registered active leaders';

  @override
  String get homeStatCellsTitle => 'Cells';

  @override
  String get homeStatCellsSubtitle => 'Active cells';

  @override
  String get homeStatBaptismsTitle => 'Baptisms';

  @override
  String get homeStatBaptismsSubtitle => 'Scheduled baptisms';

  @override
  String get homeStatDisciplesTitle => 'Disciples';

  @override
  String get homeStatDisciplesSubtitle => 'Assigned disciples';

  @override
  String get homeStatMyDisciplesTitle => 'My disciples';

  @override
  String get homeStatMyDisciplesSubtitle => 'In your assigned cell';

  @override
  String get homeStatMyNewBelieversTitle => 'My new believers';

  @override
  String get homeStatMyNewBelieversSubtitle => 'Assigned to your leadership';

  @override
  String get homeStatMyAssignedLeadersTitle => 'My assigned leaders';

  @override
  String get homeStatMyAssignedLeadersSubtitle =>
      'Leaders under your supervision';

  @override
  String get homeNavBelievers => 'Believers';

  @override
  String get homeNavLeaders => 'Leaders';

  @override
  String get homeNavCells => 'Cells';

  @override
  String get homeNavMore => 'More';

  @override
  String get homeRegisterAttendanceTitle => 'Register attendance';

  @override
  String get homeRegisterAttendanceSubtitle =>
      'Select your cell to register attendance';

  @override
  String get homeDashboardLoadError => 'Could not load the home summary.';

  @override
  String get user => 'User';

  @override
  String get noAccessForRole =>
      'No shortcuts available for your role. Contact the administrator.';

  @override
  String get leaderAccountNotLinked =>
      'Your leader account is not linked to a record.';

  @override
  String get leaderRecordNotFound => 'Your leader record was not found.';

  @override
  String get retry => 'Retry';

  @override
  String get profileLoadError => 'Could not load your user profile.';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get emailRequired => 'Enter your email';

  @override
  String get emailInvalid => 'Invalid email';

  @override
  String get passwordRequired => 'Enter your password';

  @override
  String get passwordMinLength => 'At least 6 characters';

  @override
  String get passwordRegistrationMinLength => 'At least 8 characters';

  @override
  String get passwordRegistrationNeedsLetter =>
      'Must include at least one letter';

  @override
  String get passwordRegistrationNeedsNumber =>
      'Must include at least one number';

  @override
  String get passwordRegistrationNeedsSpecial =>
      'Must include at least one special character';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get signIn => 'Sign in';

  @override
  String get loginUnexpectedError => 'Unexpected error while signing in.';

  @override
  String get forgotPasswordEnterEmail =>
      'Enter your email to reset your password';

  @override
  String get forgotPasswordEmailSent =>
      'Check your email to reset your password';

  @override
  String get forgotPasswordSendFailed => 'Could not send the recovery email.';

  @override
  String get myAccount => 'My account';

  @override
  String get systemRoles => 'System roles';

  @override
  String get personalData => 'Personal data';

  @override
  String get personalDataSubtitleFull => 'Name, address, document and phone';

  @override
  String get personalDataSubtitleName => 'Your profile name';

  @override
  String get churchData => 'Church data';

  @override
  String get churchDataSubtitle => 'View your church location details';

  @override
  String get changePassword => 'Change password';

  @override
  String get changePasswordSubtitle => 'Update your access password';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Spanish, English or system language';

  @override
  String get languageSettingsTitle => 'Language';

  @override
  String get languageSystem => 'System language';

  @override
  String get languageSystemSubtitle => 'Uses your device settings';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get theme => 'Theme';

  @override
  String get themeSubtitle => 'Light, dark or follow system';

  @override
  String get themeSettingsTitle => 'App theme';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeSystemSubtitle => 'Uses your device settings';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeColorSection => 'Color palette';

  @override
  String get themeModeSection => 'Display mode';

  @override
  String get templateManantial => 'Manantial';

  @override
  String get templateManantialSubtitle => 'Deep blue and gold — recommended';

  @override
  String get templateWhatsapp => 'Messaging green';

  @override
  String get templateWhatsappSubtitle =>
      'WhatsApp style, the previous app look';

  @override
  String get templatePeace => 'Peace';

  @override
  String get templatePeaceSubtitle => 'Soft indigo and calm tones';

  @override
  String get templateTraditional => 'Traditional';

  @override
  String get templateTraditionalSubtitle => 'Wine and cream, elegant';

  @override
  String get roleSuperAdmin => 'Super administrator';

  @override
  String get roleAdmin => 'Church administrator';

  @override
  String get roleRegistrar => 'Registrar';

  @override
  String get roleSupervisor => 'Supervisor';

  @override
  String get roleLeader => 'Leader';

  @override
  String get authInvalidEmail => 'The email address is not valid.';

  @override
  String get authUserDisabled => 'This account has been disabled.';

  @override
  String get authUserNotFound => 'No account exists with this email.';

  @override
  String get authWrongPassword => 'Incorrect email or password.';

  @override
  String get authEmailInUse => 'An account already exists with this email.';

  @override
  String get authWeakPassword => 'Password must be at least 6 characters.';

  @override
  String get authRequiresRecentLogin =>
      'For security, sign in again and try once more.';

  @override
  String get authTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get authNetworkError => 'No connection. Check your internet.';

  @override
  String get authOperationNotAllowed =>
      'Email registration is not enabled in Firebase.';

  @override
  String get authGenericError => 'Authentication error. Please try again.';

  @override
  String get memberRegisterTitle => 'New member registration';

  @override
  String get memberEditTitle => 'Edit member';

  @override
  String get memberNoPermissionRegister =>
      'You do not have permission to register members.';

  @override
  String get memberNoPermissionEdit =>
      'You do not have permission to edit members.';

  @override
  String get memberFormDate => 'Date';

  @override
  String get memberEntrySource => 'Where did the believer join? *';

  @override
  String get memberEntrySourceRequired => 'Select where the believer joined';

  @override
  String get memberDetailEntrySource => 'Where they joined';

  @override
  String get memberDetailLeadershipStatus => 'Pastoral status';

  @override
  String get memberDetailAssignmentKind => 'Assignment type';

  @override
  String get memberAssignmentPastoral => 'New believer';

  @override
  String get memberAssignmentCell => 'Cell group disciple';

  @override
  String get memberDetailSectionJourney => 'Journey';

  @override
  String get memberDetailRegistrationSource => 'Registered from';

  @override
  String get memberDetailPastoralAssignedAt => 'Assigned to leader';

  @override
  String get memberDetailNewBelieverAt => 'Registered as new believer';

  @override
  String get memberDetailCellAssignedAt => 'Assigned to cell group';

  @override
  String get memberDetailBaptizedAt => 'Baptism date';

  @override
  String get memberDetailJourneyComplete =>
      'Believer registration → cell → baptism';

  @override
  String get memberDetailHistoryTitle => 'Change history';

  @override
  String get memberRegistrationSourceRegisterMember => 'Believer registration';

  @override
  String get memberRegistrationSourceRegisterMemberCell =>
      'Believer registration in cell';

  @override
  String get memberRegistrationSourceRegisterCellMember =>
      'Cell group registration';

  @override
  String get memberRegistrationSourceRegisterBaptismBeliever =>
      'Baptism registration';

  @override
  String get memberHistoryEventRegistered => 'Record created';

  @override
  String get memberHistoryEventPastoralAssigned => 'Assigned to leader';

  @override
  String get memberHistoryEventCellAssigned => 'Assigned to cell group';

  @override
  String get memberHistoryEventCellUnassigned => 'Removed from cell group';

  @override
  String get memberHistoryEventBaptizedConfirmed => 'Baptism confirmed';

  @override
  String get memberDetailAssignedCell => 'Assigned cell group';

  @override
  String get entrySourceCampaignOutside => 'Outreach campaign';

  @override
  String get entrySourceCell => 'Cell group';

  @override
  String get entrySourceHospital => 'Hospital';

  @override
  String get entrySourceEvangelism => 'Evangelism';

  @override
  String get entrySourceMotherChurch => 'Mother church';

  @override
  String get entrySourceDaughterChurch => 'Daughter church';

  @override
  String get memberSectionPersonalData => 'PERSONAL DATA';

  @override
  String get memberFirstName => 'First name *';

  @override
  String get memberFirstNameRequired => 'Enter the first name';

  @override
  String get memberLastName => 'Last name *';

  @override
  String get memberLastNameRequired => 'Enter the last name';

  @override
  String get memberIdDocumentType => 'ID document';

  @override
  String get memberIdDocumentNumber => 'Document number';

  @override
  String get idDocumentDni => 'National ID (DNI)';

  @override
  String get idDocumentPassport => 'Passport';

  @override
  String get idDocumentOther => 'Other';

  @override
  String get memberGenderRequired => 'Gender *';

  @override
  String get memberGender => 'Gender';

  @override
  String get memberIncludeAddress => 'Include address';

  @override
  String get memberAddressRequiredForLeader =>
      'Required to assign a leader automatically';

  @override
  String get memberAddressOptional => 'Optional: member home address';

  @override
  String get memberPhone => 'Phone *';

  @override
  String get memberPhoneRequired => 'Enter the phone number';

  @override
  String get memberBirthDate => 'Date of birth *';

  @override
  String get memberBirthDateRequired => 'Select the date of birth';

  @override
  String get memberSelectDate => 'Select date';

  @override
  String get memberClearDate => 'Clear date';

  @override
  String get memberAge => 'Age *';

  @override
  String memberAgeYears(int age) {
    return '$age years';
  }

  @override
  String get memberOccupation => 'Occupation *';

  @override
  String get memberOccupationRequired => 'Enter the occupation';

  @override
  String get memberMaritalStatus => 'Marital status *';

  @override
  String get memberMaritalStatusRequired => 'Select marital status';

  @override
  String get memberSectionCellSchedule => 'CELL GROUP SCHEDULE';

  @override
  String get memberCellDay => 'Day';

  @override
  String get memberCellTime => 'Time';

  @override
  String get memberSelectTime => 'Select time';

  @override
  String get memberCellZone => 'Zone';

  @override
  String get memberSectionVisit => 'VISIT';

  @override
  String get memberWantsVisit => 'Wants to be visited';

  @override
  String get memberWantsVisitSubtitle =>
      'Indicates whether the person requests a home visit';

  @override
  String get memberSectionObservations => 'NOTES';

  @override
  String get memberObservationsHint => 'Additional notes...';

  @override
  String get memberVolunteer => 'Volunteer';

  @override
  String get memberSaving => 'Saving...';

  @override
  String get memberSaveChanges => 'Save changes';

  @override
  String get memberRegisterButton => 'Register member';

  @override
  String get memberSectionAssignedLeader => 'ASSIGNED LEADER';

  @override
  String get memberManualLeader => 'Choose leader manually';

  @override
  String get memberManualLeaderSubtitle => 'Search and pick a leader by name';

  @override
  String get memberAutoLeaderSubtitle =>
      'The nearest leader of the same gender will be assigned';

  @override
  String get memberNoLeaderSubtitle =>
      'No leader until you enable a visit or choose one';

  @override
  String get memberNoLeadersAvailable =>
      'There are no leaders in the app. Assign the Leader role when registering a leader.';

  @override
  String get memberSelectLeader => 'Select a leader';

  @override
  String get memberSelectLeaderFromList => 'Select a leader from the list';

  @override
  String get memberGenderForAutoLeader =>
      'Select gender to assign a leader automatically';

  @override
  String get memberCompatibleLeadersHint =>
      'Showing leaders compatible with the selected gender.';

  @override
  String get memberNoChurchAssigned =>
      'Your account has no church assigned. Contact the administrator.';

  @override
  String get memberAddressRequiredAutoLeader =>
      'Enable \"Include address\" and select an address from search to assign a leader automatically.';

  @override
  String get memberAddressGeocodeFailed =>
      'Could not locate the address. Select it from autocomplete.';

  @override
  String get memberUpdatedSuccess => 'Member updated successfully';

  @override
  String get memberRegisteredSuccess => 'Member registered successfully';

  @override
  String memberRegisteredWithLeader(
    String leader,
    String cell,
    String distance,
  ) {
    return 'Member registered. Leader: $leader$cell$distance';
  }

  @override
  String get memberRegisteredNoNearbyLeader =>
      'Member registered. No leader of the same gender with a nearby address.';

  @override
  String get memberSaveUnexpectedError => 'Unexpected error while saving.';

  @override
  String memberCellCodeSuffix(String code) {
    return ' (Cell $code)';
  }

  @override
  String memberDistanceKm(String km) {
    return ' · $km km';
  }

  @override
  String get genderMale => 'Male (H)';

  @override
  String get genderFemale => 'Female (M)';

  @override
  String get maritalSingle => 'Single';

  @override
  String get maritalMarried => 'Married';

  @override
  String get maritalConcubino => 'Cohabiting';

  @override
  String get maritalDivorced => 'Divorced';

  @override
  String get maritalWidowed => 'Widowed';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get addressSection => 'ADDRESS';

  @override
  String get addressSearchRequired => 'Search address *';

  @override
  String get addressSearchOptional => 'Search address';

  @override
  String get addressSearchHint => 'Type and pick a suggestion...';

  @override
  String get addressSearchTapToChange => 'Tap here to change the address...';

  @override
  String get addressChangeButton => 'Change address';

  @override
  String get addressSearchAndSelect => 'Search and select an address';

  @override
  String get addressMustPickFromList =>
      'You must pick an address from the list';

  @override
  String get addressAutoFilledHint => 'Filled when you search an address';

  @override
  String get addressStreetRequired => 'Street *';

  @override
  String get addressStreetOptional => 'Street';

  @override
  String get addressNumber => 'Number';

  @override
  String get addressPostalCode => 'Postal code';

  @override
  String get addressNeighborhood => 'Neighborhood';

  @override
  String get addressLocality => 'City / District';

  @override
  String get addressStateProvince => 'State / Province';

  @override
  String get leaderSearchLabel => 'Search leader *';

  @override
  String get leaderSearchHint => 'Type letters from name or cell group...';

  @override
  String get leaderSearchClear => 'Clear leader';

  @override
  String leaderCellLabel(String code) {
    return 'Cell $code';
  }

  @override
  String get firestorePermissionDenied =>
      'You do not have permission for this operation.';

  @override
  String get firestoreUnavailable =>
      'Firestore is unavailable. Check your connection.';

  @override
  String get firestoreNotFound => 'The member no longer exists.';

  @override
  String get firestoreGenericError =>
      'Error processing the request. Please try again.';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get memberDetailSectionPersonal => 'Personal data';

  @override
  String get memberDetailSectionAddress => 'Address';

  @override
  String get memberDetailSectionLeader => 'Assigned leader';

  @override
  String get memberDetailSectionCellSchedule => 'Cell group schedule';

  @override
  String get memberDetailSectionObservations => 'Notes';

  @override
  String get memberDetailSectionRegistration => 'Registration';

  @override
  String get memberDetailFirstName => 'First name';

  @override
  String get memberDetailLastName => 'Last name';

  @override
  String get memberDetailGender => 'Gender';

  @override
  String get memberDetailPhone => 'Phone';

  @override
  String get memberDetailIdDocument => 'Document';

  @override
  String get memberDetailIdDocumentNumber => 'Document number';

  @override
  String get memberDetailBirthDate => 'Date of birth';

  @override
  String get memberDetailAge => 'Age';

  @override
  String get memberDetailOccupation => 'Occupation';

  @override
  String get memberDetailMaritalStatus => 'Marital status';

  @override
  String get memberDetailWantsVisit => 'Wants to be visited';

  @override
  String get memberDetailLeaderName => 'Name';

  @override
  String get memberDetailCell => 'Cell group';

  @override
  String get memberDetailDistance => 'Distance';

  @override
  String memberDetailDistanceKm(String km) {
    return '$km km';
  }

  @override
  String get memberDetailCellDay => 'Day';

  @override
  String get memberDetailCellTime => 'Time';

  @override
  String get memberDetailCellZone => 'Zone';

  @override
  String get memberDetailFormDate => 'Form date';

  @override
  String get memberDetailVolunteer => 'Volunteer';

  @override
  String get memberDetailRegisteredBy => 'Registered by';

  @override
  String get memberDetailDeleteTitle => 'Delete member';

  @override
  String memberDetailDeleteConfirm(String name) {
    return 'Delete $name? This action cannot be undone.';
  }

  @override
  String get memberDetailDeletedSuccess => 'Member deleted';

  @override
  String get memberDetailRegisterVisit => 'Register visit';

  @override
  String get memberDetailEditMember => 'Edit member';

  @override
  String get memberDetailDeleteMember => 'Delete member';

  @override
  String get memberVisitsTitle => 'Registered visits';

  @override
  String get memberVisitsLoadError => 'Could not load visits.';

  @override
  String get memberVisitsEmpty => 'No visits registered yet.';

  @override
  String get memberVisitsNeedsFollowUp => ' · Follow-up required';

  @override
  String visitDuration(String value) {
    return 'Duration: $value';
  }

  @override
  String visitPrayer(String value) {
    return 'Prayer: $value';
  }

  @override
  String visitRequests(String value) {
    return 'Requests: $value';
  }

  @override
  String visitFollowUp(String value) {
    return 'Follow-up: $value';
  }

  @override
  String visitSpiritualState(String value) {
    return 'State: $value';
  }

  @override
  String get visitPlaceHome => 'Home';

  @override
  String get visitPlaceHospital => 'Hospital';

  @override
  String get visitPlaceWork => 'Work';

  @override
  String get visitPlaceChurch => 'Church';

  @override
  String get visitPlaceVideoCall => 'Video call';

  @override
  String get spiritualNewBeliever => 'New believer';

  @override
  String get spiritualInDiscipleship => 'In discipleship';

  @override
  String get spiritualActiveMember => 'Active member';

  @override
  String get spiritualDistant => 'Distant';

  @override
  String get spiritualFrequentVisitor => 'Frequent visitor';

  @override
  String get membersMapNoLocationSnack =>
      'This member has no location on the map';

  @override
  String get membersMapNavigationFailed => 'Could not open navigation';

  @override
  String get membersMapRequestsVisit => 'Requests visit';

  @override
  String membersMapDistanceFromLeader(String km) {
    return '$km km from leader';
  }

  @override
  String get membersMapGetDirections => 'Get directions';

  @override
  String get membersMapViewDetail => 'View details';

  @override
  String get membersMapLeaderLabel => 'Leader';

  @override
  String get membersMapEmptyTitle => 'No locations on the map';

  @override
  String get membersMapEmptySubtitle =>
      'Members need an address with coordinates to appear on the map.';

  @override
  String membersMapMissingLocationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members without map location',
      one: '1 member without map location',
    );
    return '$_temp0';
  }

  @override
  String membersMapLeaderMarker(String name) {
    return 'Purple marker: $name (leader)';
  }

  @override
  String get commonBack => 'Back';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaving => 'Saving...';

  @override
  String get commonNew => 'New';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonUnblock => 'Unblock';

  @override
  String get commonBlock => 'Block';

  @override
  String get commonBlocked => 'Blocked';

  @override
  String get commonBlockedFem => 'Blocked';

  @override
  String get commonUnblocked => 'Unblocked';

  @override
  String get commonUnblockedFem => 'Unblocked';

  @override
  String get commonNoMatches => 'No matches';

  @override
  String get commonNoName => '(No name)';

  @override
  String get commonLoadListError => 'Could not load the list.';

  @override
  String get commonExportError => 'Could not export the list. Try again.';

  @override
  String commonDeleteConfirm(String name) {
    return 'Delete $name? This action cannot be undone.';
  }

  @override
  String get accessDeniedTitle => 'Access restricted';

  @override
  String get accessDeniedDefault =>
      'You do not have permission to view this section.';

  @override
  String get blockedAccountUserTitle => 'Account blocked';

  @override
  String get blockedAccountChurchTitle => 'Church blocked';

  @override
  String get blockedAccountUserMessage =>
      'Your account was suspended. Contact the super administrator to restore access.';

  @override
  String get blockedAccountChurchMessage =>
      'Your assigned church is blocked. You cannot use the system until the super administrator reactivates it.';

  @override
  String get membersListTitle => 'New believers';

  @override
  String get churchMembersListTitle => 'Members';

  @override
  String get churchMembersListEmptyTitle => 'No members registered yet';

  @override
  String get churchMembersListEmptySubtitle =>
      'New believers and those promoted to leadership do not appear here.';

  @override
  String get membersListExportExcel => 'Download Excel';

  @override
  String get membersListDeleteTitle => 'Delete member';

  @override
  String get membersListDeleted => 'Member deleted';

  @override
  String get membersListLoadError =>
      'Could not load the list.\nCheck Firestore in Firebase Console.';

  @override
  String get membersListEmptyTitle => 'No new believers registered yet';

  @override
  String get membersListEmptySubtitle =>
      'Tap \"New\" to register the first one.';

  @override
  String get membersListSearchHint => 'Search by name, phone, leader or city…';

  @override
  String get membersListEndOfList => 'End of list';

  @override
  String membersListLeaderPrefix(String name) {
    return 'Leader: $name';
  }

  @override
  String membersListDatePrefix(String date) {
    return 'Date: $date';
  }

  @override
  String get membersByLeaderTitle => 'View new believers by leader';

  @override
  String get membersByLeaderEmpty => 'No believers registered';

  @override
  String membersByLeaderAssignedCount(int assigned, int total) {
    return '$assigned of $total believers with assigned leader';
  }

  @override
  String membersByLeaderMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count believers',
      one: '1 believer',
    );
    return '$_temp0';
  }

  @override
  String membersByLeaderRegistrationDate(String date) {
    return 'Registered: $date';
  }

  @override
  String get leaderAssignedTitle => 'My new believers';

  @override
  String get leaderAssignedTabList => 'List';

  @override
  String get leaderAssignedTabMap => 'Map';

  @override
  String leaderAssignedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new believers assigned',
      one: '1 new believer assigned',
    );
    return '$_temp0';
  }

  @override
  String leaderAssignedCellSuffix(String code) {
    return '· Cell $code';
  }

  @override
  String get leaderAssignedEmptyTitle => 'No new believers assigned';

  @override
  String get leaderAssignedEmptySubtitle =>
      'New believers assigned to your leadership will appear here.';

  @override
  String get leaderAssignedNoMapLocation => 'No map location';

  @override
  String get leaderAssignedRegisterVisit => 'Register visit';

  @override
  String get leaderAssignedLoadError => 'Could not load members.';

  @override
  String get leadersListTitle => 'Leaders';

  @override
  String get leadersBlockTitle => 'Block leader';

  @override
  String get leadersUnblockTitle => 'Unblock leader';

  @override
  String leadersBlockConfirm(String name) {
    return 'Block \"$name\"? They will not be able to sign in or be assigned to new members until you unblock them.';
  }

  @override
  String leadersUnblockConfirm(String name) {
    return 'Unblock \"$name\" and allow access again?';
  }

  @override
  String get leadersBlocked => 'Leader blocked';

  @override
  String get leadersUnblocked => 'Leader unblocked';

  @override
  String leadersShowBlocked(int count) {
    return 'Show blocked ($count)';
  }

  @override
  String leadersHideBlocked(int count) {
    return 'Hide blocked ($count)';
  }

  @override
  String get leadersAllBlocked => 'All leaders are blocked';

  @override
  String get leadersListLoadError =>
      'Could not load the list. Check Firestore and the \"leaders\" collection rules.';

  @override
  String get leadersListEmpty => 'No leaders registered yet';

  @override
  String get leadersListSearchHint =>
      'Search by name, phone, email or cell group…';

  @override
  String get leadersListEndOfList => 'End of list';

  @override
  String leadersListCellPrefix(String code) {
    return 'Cell $code';
  }

  @override
  String get leadersListViewMembers => 'View members assigned to visit';

  @override
  String get leadersListViewLeader => 'View leader';

  @override
  String get leaderDetailEditLeader => 'Edit leader';

  @override
  String get leaderDetailBlockLeader => 'Block leader';

  @override
  String get leaderDetailUnblockLeader => 'Unblock leader';

  @override
  String get leaderDetailViewMembers => 'View members assigned to visit';

  @override
  String get leaderDetailSectionLeadership => 'Leadership data';

  @override
  String get leaderDetailSectionCellContact => 'Contact';

  @override
  String get leaderDetailSectionRoles => 'App roles';

  @override
  String get leaderDetailLastName => 'Last name';

  @override
  String get leaderDetailFirstNames => 'First names';

  @override
  String get leaderDetailChurchOffice => 'Church office';

  @override
  String get leaderDetailMobile => 'Mobile phone';

  @override
  String get leaderDetailPermissions => 'Permissions';

  @override
  String get leadersMapNoLocationSnack =>
      'This leader has no location on the map';

  @override
  String get leadersMapEmptyTitle => 'No locations on the map';

  @override
  String get leadersMapEmptySubtitle =>
      'Leaders need an address with coordinates to appear on the map.';

  @override
  String leadersMapMissingLocationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leaders without map location',
      one: '1 leader without map location',
    );
    return '$_temp0';
  }

  @override
  String get leadersMapViewLeader => 'View leader';

  @override
  String get supervisorMyLeadersTitle => 'My assigned leaders';

  @override
  String get supervisorMyLeadersDenied =>
      'You do not have permission to view your assigned leaders.';

  @override
  String supervisorMyLeadersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leaders under your supervision',
      one: '1 leader under your supervision',
    );
    return '$_temp0';
  }

  @override
  String get supervisorMyLeadersSearchHint => 'Search leader';

  @override
  String get supervisorMyLeadersEmptyTitle => 'No assigned leaders';

  @override
  String get supervisorMyLeadersEmptySubtitle =>
      'The administrator will assign leaders when appropriate.';

  @override
  String get supervisorMyLeadersNoSearchResults =>
      'No leader matches your search.';

  @override
  String get supervisorMyLeadersViewMembers => 'Members';

  @override
  String get supervisorAssignmentsTitle => 'Leaders by supervisor';

  @override
  String get supervisorAssignmentsDeniedSupervisor =>
      'Supervisors cannot access this screen. Use \"My assigned leaders\" to view your portfolio.';

  @override
  String get supervisorAssignmentsDeniedAdmin =>
      'Only the administrator can assign leaders to supervisors.';

  @override
  String get supervisorAssignmentsNoSupervisors =>
      'There are no supervisors in your church';

  @override
  String get supervisorAssignmentsNoSupervisorsHint =>
      'When registering a leader, assign the Supervisor role in the app.';

  @override
  String get supervisorAssignmentsSelectSupervisor => 'Select supervisor *';

  @override
  String supervisorAssignmentsAssignedLeaders(int count) {
    return 'Assigned leaders ($count)';
  }

  @override
  String get supervisorAssignmentsSearchLeader => 'Search leader';

  @override
  String get supervisorAssignmentsNoLeaders =>
      'There are no leaders registered in your church.';

  @override
  String get supervisorAssignmentsNoLeaderMatches =>
      'No leader matches your search.';

  @override
  String get supervisorAssignmentsNoLeadersAvailable =>
      'No leaders available to assign.';

  @override
  String get supervisorAssignmentsSelectSupervisorError =>
      'Select a supervisor';

  @override
  String supervisorAssignmentsConflict(String name) {
    return 'Cannot save: a leader already belongs to $name';
  }

  @override
  String get supervisorAssignmentsSaved => 'Leaders assigned successfully';

  @override
  String get dashboardVisitsTitle => 'Visits dashboard';

  @override
  String get dashboardPastoralTitle => 'Pastoral dashboard';

  @override
  String get dashboardVisitsDenied =>
      'You do not have permission to view the visits dashboard.';

  @override
  String get dashboardPastoralDenied =>
      'You do not have permission to view the pastoral dashboard.';

  @override
  String get dashboardAdminMissingChurch =>
      'Your administrator account has no church assigned. Contact the super administrator or add \"superadmin\" to roles in Firebase.';

  @override
  String get dashboardScopeAllChurches => 'All churches';

  @override
  String get dashboardScopeYourChurch => 'Your church';

  @override
  String get dashboardScopeYourLeaders => 'Your assigned leaders';

  @override
  String get dashboardChurchLabel => 'Church';

  @override
  String get dashboardNoAssignedLeadersTitle => 'No assigned leaders';

  @override
  String get dashboardNoAssignedLeadersVisits =>
      'When the administrator assigns leaders, you will see their visit statistics here.';

  @override
  String get dashboardNoAssignedLeadersPastoral =>
      'When the administrator assigns leaders, you will see pastoral follow-up here.';

  @override
  String get dashboardTotalPeriod => 'Total in period';

  @override
  String get dashboardLeadersWithVisits => 'Leaders with visits';

  @override
  String dashboardLeadersWithVisitsCount(int count) {
    return '$count leaders with visits';
  }

  @override
  String get dashboardVisitCount => 'Number of visits';

  @override
  String get dashboardTopVisitPlaces => 'Most frequent visit places';

  @override
  String get dashboardByVisitPlace => 'By visit place';

  @override
  String get dashboardTopPrayerRequests => 'Most common prayer requests';

  @override
  String get dashboardPrayerRequestsSubtitle => 'Repeated texts in the period';

  @override
  String get dashboardNoPrayerRequests =>
      'No prayer requests recorded in this period.';

  @override
  String get dashboardVisitsByLeader => 'Visits by leader';

  @override
  String get dashboardPeriodLast14Days => 'Last 14 days';

  @override
  String get dashboardPeriodLast12Months => 'Last 12 months';

  @override
  String get dashboardPeriodLast6Months => 'Last 6 months';

  @override
  String get dashboardPeriodLast5Years => 'Last 5 years';

  @override
  String get dashboardFollowUpTitle => 'People requiring follow-up';

  @override
  String get dashboardFollowUpSubtitle => 'Marked in visits during the period';

  @override
  String dashboardFollowUpCount(int count) {
    return '$count person(s)';
  }

  @override
  String get dashboardFollowUpEmpty =>
      'No people with pending follow-up in this period.';

  @override
  String dashboardVisitOnDate(String date) {
    return 'Visit: $date';
  }

  @override
  String dashboardLeaderPrefix(String name) {
    return 'Leader: $name';
  }

  @override
  String get dashboardMemberNotFound => 'Member not found.';

  @override
  String get dashboardNewMembersTitle => 'New members';

  @override
  String dashboardNewMembersCount(int count) {
    return '$count registered in the period';
  }

  @override
  String get dashboardPrayerVisitsTitle => 'Visits with prayer';

  @override
  String get dashboardPrayerVisitsEmpty => 'No visits in the selected period.';

  @override
  String dashboardPrayerVisitsSummary(int withPrayer, int total) {
    return '$withPrayer of $total visits included prayer.';
  }

  @override
  String get dashboardNoData => 'No data to display';

  @override
  String get chartPeriodDay => 'By day';

  @override
  String get chartPeriodMonth => 'By month';

  @override
  String get chartPeriodYear => 'By year';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsLeaderNotLinked =>
      'Your leader account is not linked. Contact the administrator.';

  @override
  String get notificationsMarkRead => 'Mark as read';

  @override
  String get notificationsDismissAll => 'Dismiss all';

  @override
  String get notificationsDismissAllConfirmTitle => 'Dismiss all alerts?';

  @override
  String get notificationsDismissAllConfirmMessage =>
      'Alerts will be removed from your list. This cannot be undone.';

  @override
  String get notificationsLoadError =>
      'Could not load notifications. Check Firestore rules.';

  @override
  String get notificationsEmptyTitle => 'You have no notifications';

  @override
  String get notificationsEmptySubtitle =>
      'When a new member is assigned to you, it will appear here.';

  @override
  String get notificationsMemberUnavailable =>
      'The member is no longer available.';

  @override
  String notificationsToday(String time) {
    return 'Today $time';
  }

  @override
  String notificationsYesterday(String time) {
    return 'Yesterday $time';
  }

  @override
  String get notificationNewMemberTitle => 'New member assigned';

  @override
  String notificationNewMemberBody(String name) {
    return 'You were assigned $name. Tap to view details.';
  }

  @override
  String get notificationMemberFallback => 'Member';

  @override
  String get notificationCellCapacityTitle =>
      'Cell with more than 12 disciples';

  @override
  String notificationCellCapacityBody(String cell, int count) {
    return 'Cell $cell has $count assigned disciples.';
  }

  @override
  String get notificationCellSplitNotRequired =>
      'This cell group no longer exceeds 12 disciples. Splitting is not needed.';

  @override
  String get splitCellTitle => 'Split cell group';

  @override
  String get splitCellSourceCellLabel => 'Source cell group';

  @override
  String get splitCellNewCellSection => 'New cell group';

  @override
  String get splitCellSelectLeaderHelper => 'New cell group leader';

  @override
  String get splitCellSelectLeaderHelperHint =>
      'Choose a helper from the source cell as leader';

  @override
  String get splitCellNoHelpers =>
      'This cell has no helpers. Assign helpers in My cell group before splitting.';

  @override
  String get splitCellSelectMembers => 'Disciples for the new cell group';

  @override
  String splitCellSelectMembersHint(int max) {
    return 'Select up to $max disciples from the source cell';
  }

  @override
  String splitCellMembersMaxReached(int max) {
    return 'Maximum $max disciples for the new cell group';
  }

  @override
  String get splitCellLeaderRequired =>
      'Select a helper as leader of the new cell group';

  @override
  String get splitCellMembersRequired =>
      'Select at least one disciple for the new cell group';

  @override
  String get splitCellLeaderBusy =>
      'That helper already leads another cell group';

  @override
  String get splitCellSuccess =>
      'New cell group created and disciples transferred';

  @override
  String get splitCellCreateAction => 'Create new cell group';

  @override
  String get splitCellLoadError => 'Could not load the source cell group';

  @override
  String get splitCellLeaderAccountSection => 'Leader account';

  @override
  String get splitCellLeaderAccountHint =>
      'An app login will be created for the helper selected as leader of the new cell group.';

  @override
  String get splitCellLeaderAlreadyHasAccount =>
      'This helper already has a leader account in the system.';

  @override
  String get splitCellLeaderAccountRequired =>
      'Enter email and password to create the leader account';

  @override
  String get splitCellLeaderBlocked =>
      'That helper is blocked as a leader and cannot lead a cell group';

  @override
  String get memberLeadershipPromotedToLeader => 'Promoted to leader';

  @override
  String get memberLeadershipPromotedToVolunteer => 'Promoted to registrar';

  @override
  String get memberLeadershipCreatedAsLeader => 'Created as leader';

  @override
  String get menuCellsOverCapacity => 'Cells to split';

  @override
  String get cellsOverCapacityTitle => 'Cell groups over 12 disciples';

  @override
  String get cellsOverCapacityDenied =>
      'You do not have permission to split cell groups';

  @override
  String get cellsOverCapacityNoChurch =>
      'No church is assigned to your account';

  @override
  String get cellsOverCapacityLoadError => 'Could not load cell groups';

  @override
  String get cellsOverCapacityEmpty => 'No cell groups exceed the limit';

  @override
  String cellsOverCapacityEmptySubtitle(int max) {
    return 'All cell groups have $max disciples or fewer';
  }

  @override
  String cellsOverCapacityIntro(int max) {
    return 'These cell groups exceed $max disciples. Tap one to create a new cell group and transfer disciples.';
  }

  @override
  String cellsOverCapacityLeaderLabel(String name) {
    return 'Leader: $name';
  }

  @override
  String get cellMemberCapacityAdminNotified =>
      'Disciple registered. The administrator was alerted: the cell exceeds 12 disciples.';

  @override
  String get cellMemberRegisterLeaderOnlyAtCapacity =>
      'With 12 or more disciples, only the cell leader can register a new disciple.';

  @override
  String get menuAdminNotifications => 'Church alerts';

  @override
  String get adminNotificationsTitle => 'Church alerts';

  @override
  String get adminNotificationsDenied =>
      'You do not have permission to view church alerts';

  @override
  String get adminNotificationsEmptyTitle => 'No alerts';

  @override
  String get adminNotificationsEmptySubtitle =>
      'You will receive alerts here when a cell exceeds 12 disciples.';

  @override
  String get visitRegDenied =>
      'Only the leader can register visits for their members.';

  @override
  String get visitRegTitle => 'Register visit';

  @override
  String get visitRegPrayerFollowUpRequired =>
      'Indicate whether prayer was performed and if follow-up is needed.';

  @override
  String get visitRegInvalidMember =>
      'The member does not have a valid identifier.';

  @override
  String get visitRegSaved => 'Visit registered';

  @override
  String get visitRegSaveFailed => 'Could not register the visit.';

  @override
  String get visitRegSelectOption => 'Select an option';

  @override
  String get visitRegDate => 'Visit date *';

  @override
  String get visitRegPlace => 'Visit place *';

  @override
  String get visitRegSelectPlace => 'Select place';

  @override
  String get visitRegDuration => 'Approximate visit duration';

  @override
  String get visitRegDurationHint => 'E.g. 30 min, 1 hour';

  @override
  String get visitRegPrayerTitle => 'Prayer performed *';

  @override
  String get visitRegPrayerRequests => 'Prayer requests';

  @override
  String get visitRegPrayerRequestsHint =>
      'Optional: shared reasons or requests';

  @override
  String get visitRegFollowUpTitle => 'Needs follow-up *';

  @override
  String get visitRegSpiritualState => 'Spiritual state (optional)';

  @override
  String get visitRegSpiritualUnspecified => 'Unspecified';

  @override
  String get visitRegComment => 'Comment *';

  @override
  String get visitRegCommentHint => 'Visit summary, topics covered...';

  @override
  String get visitRegCommentRequired => 'Write a comment';

  @override
  String get visitRegSaveButton => 'Save visit';

  @override
  String get addressAutocompleteApiKey =>
      'Configure the Google Maps API key in maps_api_key.dart';

  @override
  String get addressAutocompleteLoadError =>
      'Could not load Google Maps suggestions.';

  @override
  String get leaderNoLeaderAssigned => 'No leader assigned';

  @override
  String get leaderFallbackName => 'Leader';

  @override
  String get serviceGenericError => 'Unexpected error. Please try again.';

  @override
  String get serviceUnavailable =>
      'Service unavailable. Check your connection.';

  @override
  String get servicePermissionDenied =>
      'You do not have permission for this operation.';

  @override
  String get visitServicePermissionDenied =>
      'You do not have permission to register visits.';

  @override
  String get visitServiceSaveError => 'Error saving visit. Please try again.';

  @override
  String get visitDashboardPermissionDenied =>
      'You do not have permission to view the visits dashboard.';

  @override
  String get visitDashboardIndexBuilding =>
      'The visits index is being created in Firebase. Wait a few minutes and try again.';

  @override
  String get visitDashboardIndexMissing =>
      'A Firestore index for visits is missing. Run: firebase deploy --only firestore:indexes';

  @override
  String get visitDashboardDateFormatError =>
      'Error formatting chart dates. Restart the app and try again.';

  @override
  String visitDashboardLoadUnexpected(String code) {
    return 'Unexpected error loading visits ($code).';
  }

  @override
  String visitDashboardLoadError(String message) {
    return 'Error loading visits: $message';
  }

  @override
  String get churchOfficePastor => 'Pastor';

  @override
  String get churchOfficeLeader => 'Leaders';

  @override
  String get churchOfficeJuniorElder => 'Junior elder';

  @override
  String get churchOfficeElder => 'Elder';

  @override
  String get churchOfficeSeniorElder => 'Senior elder';

  @override
  String get churchOfficeVolunteer => 'Volunteer';

  @override
  String get assignableRolesRegistrarExclusive =>
      'The Registrar role is exclusive and cannot be combined with others.';

  @override
  String get assignableRolesVolunteerOnly =>
      'As a volunteer, only the Registrar role can be assigned.';

  @override
  String get assignableRolesHint =>
      'Select app access permissions. You can combine Leader and Supervisor on one account. Registrar must be alone.';

  @override
  String get adminsDenied =>
      'Only the super administrator can manage administrators.';

  @override
  String get adminsTitle => 'Administrators';

  @override
  String get adminsNoChurch => 'No church assigned';

  @override
  String adminsChurchLabel(String id) {
    return 'Church ($id)';
  }

  @override
  String get adminsBlockTitle => 'Block administrator';

  @override
  String get adminsUnblockTitle => 'Unblock administrator';

  @override
  String adminsBlockConfirm(String name) {
    return 'Block \"$name\"? They will not be able to sign in until you unblock them.';
  }

  @override
  String adminsUnblockConfirm(String name) {
    return 'Unblock \"$name\" and allow access again?';
  }

  @override
  String get adminsBlocked => 'Administrator blocked';

  @override
  String get adminsUnblocked => 'Administrator unblocked';

  @override
  String get adminsLoadError =>
      'Could not load administrators. Check Firestore and the \"users\" collection index.';

  @override
  String get adminsEmpty => 'No administrators registered yet';

  @override
  String get adminsRegister => 'Register administrator';

  @override
  String get adminsSearchHint => 'Search by name, email or church…';

  @override
  String adminsShowBlocked(int count) {
    return 'Show blocked ($count)';
  }

  @override
  String adminsHideBlocked(int count) {
    return 'Hide blocked ($count)';
  }

  @override
  String get adminsAllBlocked => 'All administrators are blocked';

  @override
  String get churchesDenied =>
      'Only the super administrator can manage churches.';

  @override
  String get churchesTitle => 'Churches';

  @override
  String get churchesBlockTitle => 'Block church';

  @override
  String get churchesUnblockTitle => 'Unblock church';

  @override
  String churchesBlockConfirm(String name) {
    return 'Block \"$name\"? It cannot be assigned to new administrators until you unblock it.';
  }

  @override
  String churchesUnblockConfirm(String name) {
    return 'Unblock \"$name\" and allow use again?';
  }

  @override
  String get churchesBlocked => 'Church blocked';

  @override
  String get churchesUnblocked => 'Church unblocked';

  @override
  String get churchesLoadError =>
      'Could not load churches. Check Firestore and the \"churches\" collection rules.';

  @override
  String get churchesEmpty => 'No churches registered yet';

  @override
  String get churchesRegister => 'Register church';

  @override
  String get churchesSearchHint => 'Search by name or address…';

  @override
  String churchesShowBlocked(int count) {
    return 'Show blocked ($count)';
  }

  @override
  String churchesHideBlocked(int count) {
    return 'Hide blocked ($count)';
  }

  @override
  String get churchesAllBlocked => 'All churches are blocked';

  @override
  String get churchRegLoadError => 'Could not load church data.';

  @override
  String get churchRegPickAddress =>
      'Pick an address from the list to locate it on the map';

  @override
  String churchRegImageError(String error) {
    return 'Could not select image: $error';
  }

  @override
  String get churchRegSaved => 'Church registered';

  @override
  String get churchRegUpdated => 'Church data saved';

  @override
  String get churchRegNewTitle => 'New church';

  @override
  String get churchRegViewTitle => 'Church data';

  @override
  String get churchRegEditTitle => 'Edit church';

  @override
  String get churchRegCreateDenied =>
      'Only the super administrator can create churches.';

  @override
  String get churchRegViewDenied =>
      'You do not have permission to view this church data.';

  @override
  String get churchRegEditDenied =>
      'You do not have permission to edit this church data.';

  @override
  String get churchRegBlocked =>
      'This church is blocked. Contact the super administrator to reactivate it.';

  @override
  String get churchRegLogo => 'LOGO';

  @override
  String get churchRegLogoOptional => 'LOGO (optional)';

  @override
  String get churchRegLogoHint =>
      'You can save without a logo; the default will be used.';

  @override
  String get churchRegUploadLogo => 'Upload logo';

  @override
  String get churchRegRemoveLogo => 'Remove';

  @override
  String get churchRegSectionInfo => 'INFORMATION';

  @override
  String get churchRegName => 'Church name';

  @override
  String get churchRegNameRequired => 'Church name *';

  @override
  String get churchRegNameValidation => 'Enter the name';

  @override
  String get churchRegAddressSection => 'Address';

  @override
  String get churchSearchLabel => 'Church *';

  @override
  String get churchSearchClear => 'Clear selection';

  @override
  String get churchSearchTitle => 'Select church';

  @override
  String get churchSearchHint => 'Search by name or address…';

  @override
  String get churchSearchEmpty => 'No churches available';

  @override
  String churchSearchNoMatches(String query) {
    return 'No matches for \"$query\"';
  }

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordCurrent => 'Current password *';

  @override
  String get changePasswordNew => 'New password *';

  @override
  String get changePasswordConfirm => 'Confirm password *';

  @override
  String get changePasswordCurrentRequired => 'Enter your current password';

  @override
  String get changePasswordNewRequired => 'Enter the new password';

  @override
  String get changePasswordConfirmRequired => 'Confirm the new password';

  @override
  String get changePasswordMismatch => 'Passwords do not match';

  @override
  String get changePasswordSuccess => 'Password updated';

  @override
  String get changePasswordSubmit => 'Update password';

  @override
  String get editPersonalDataTitle => 'Personal data';

  @override
  String get editPersonalDataSaved => 'Data saved';

  @override
  String get editPersonalDataRoles => 'System roles';

  @override
  String get editPersonalDataPhoto => 'Profile photo';

  @override
  String get editPersonalDataPhotoHint => 'Optional. Shown on your account.';

  @override
  String get editPersonalDataUploadPhoto => 'Upload photo';

  @override
  String get editPersonalDataChangePhoto => 'Change photo';

  @override
  String get editPersonalDataRemovePhoto => 'Remove';

  @override
  String editPersonalDataImageError(String error) {
    return 'Could not select the image: $error';
  }

  @override
  String get pushChannelName => 'Member assignments';

  @override
  String get pushChannelDescription =>
      'Alerts when a member is assigned to you';

  @override
  String get authCreateUserFailed => 'Could not create the user account';

  @override
  String get firestoreLeaderNotFound => 'The leader no longer exists.';

  @override
  String get leaderRegNewTitle => 'New leader';

  @override
  String get leaderRegEditTitle => 'Edit leader';

  @override
  String get leaderRegSelectChurchOffice => 'Select the church office';

  @override
  String get leaderRegSelectAtLeastOneRole => 'Select at least one app role';

  @override
  String get leaderRegSuccessWithLogin =>
      'Leader registered. They can sign in with their email and password.';

  @override
  String get leaderRegUpdatedSuccess => 'Leader updated successfully';

  @override
  String get leaderRegEditDenied => 'Only the administrator can edit leaders.';

  @override
  String get leaderRegRegisterDenied =>
      'You do not have permission to register leaders.';

  @override
  String get leaderRegSectionChurchOffice => 'CHURCH OFFICE';

  @override
  String get leaderRegChurchOffice => 'Office *';

  @override
  String get leaderRegSelectChurchOfficeField => 'Select the office';

  @override
  String get leaderRegNoAccessAccountHint =>
      'No access account: roles will apply when the user is created.';

  @override
  String get leaderRegCell => 'Cell group';

  @override
  String get leaderRegCellHint => 'E.g.: N10, E4, L4';

  @override
  String get cellRegTitle => 'New cell group';

  @override
  String get cellEditTitle => 'Edit cell group';

  @override
  String get cellEditSuccess => 'Cell group updated';

  @override
  String get cellEditDenied => 'You do not have permission to edit cell groups';

  @override
  String get cellRegSectionData => 'Cell group data';

  @override
  String get cellRegSectionMeeting => 'Cell group meeting';

  @override
  String get cellRegMeetingDay => 'Day of the week';

  @override
  String get cellRegMeetingDayRequired => 'Select the cell group meeting day';

  @override
  String get cellRegSectionLeader => 'Assigned leader';

  @override
  String get cellRegLeaderRequired => 'Select the cell group leader';

  @override
  String get cellRegLeaderWrongChurch =>
      'That leader belongs to another church and cannot be assigned to this cell group';

  @override
  String get cellRegCode => 'Cell group code';

  @override
  String get cellRegCodeHint => 'E.g.: N10, E4, L4';

  @override
  String get cellRegCodeRequired => 'Enter the cell group code';

  @override
  String get cellRegCodeDuplicate =>
      'A cell group with this code already exists in this church';

  @override
  String get cellRegName => 'Name (optional)';

  @override
  String get cellRegAlias => 'Alias';

  @override
  String get cellRegAliasHint => 'e.g. cell.north.mb';

  @override
  String get cellRegAliasHelper => 'Bank alias for transfers';

  @override
  String get cellRegAliasEmpty => 'No alias';

  @override
  String get cellRegAliasEditAction => 'Edit alias';

  @override
  String get cellRegAliasSaveSuccess => 'Alias updated';

  @override
  String get cellRegNotes => 'Notes (optional)';

  @override
  String get cellRegSuccess => 'Cell group registered';

  @override
  String get cellRegDenied =>
      'You do not have permission to register cell groups';

  @override
  String get cellRegSectionDisciples => 'Disciples (optional)';

  @override
  String cellRegDisciplesHint(int max) {
    return 'Add up to $max new disciples or select ones not yet assigned to a cell group';
  }

  @override
  String get cellRegSelectExistingDisciple => 'Select existing';

  @override
  String get cellRegSelectDiscipleTitle => 'Select disciple';

  @override
  String get cellRegSelectDiscipleHint =>
      'Only disciples registered without a cell group assignment in your church are shown';

  @override
  String get cellRegSelectDiscipleRequiresChurch =>
      'Disciples cannot be selected without a church assigned to your account';

  @override
  String get cellRegSelectDiscipleSearchHint =>
      'Search by name, phone, or cell group';

  @override
  String get cellRegSelectDiscipleEmpty =>
      'No unassigned disciples. Register them from Cell group → Register disciple';

  @override
  String get cellRegSelectDiscipleLoadError => 'Could not load disciples';

  @override
  String cellRegDiscipleFromCell(String cell) {
    return 'Cell group: $cell';
  }

  @override
  String get cellRegDiscipleAlreadySelected =>
      'This disciple was already added';

  @override
  String get cellRegDiscipleExistingBadge => 'Existing';

  @override
  String get cellRegDiscipleUnassignedBadge => 'Unassigned';

  @override
  String get cellDiscipleUnassignedHint =>
      'Will be saved without a cell group. You can assign them when creating a cell group.';

  @override
  String get cellDiscipleUnassignedSuccess =>
      'Disciple registered without a cell group assignment';

  @override
  String cellRegDisciplesCount(int current, int max) {
    return '$current of $max';
  }

  @override
  String get cellRegDisciplesEmpty => 'No disciples added yet';

  @override
  String get cellRegAddDisciple => 'Add disciple';

  @override
  String get cellRegEditDisciple => 'Edit disciple';

  @override
  String cellRegDisciplesMaxReached(int max) {
    return 'Maximum $max disciples when registering the cell group';
  }

  @override
  String cellRegSuccessWithDisciples(int count) {
    return 'Cell group registered with $count disciple(s)';
  }

  @override
  String get menuViewCells => 'View cell groups';

  @override
  String get menuViewCellAttendanceReport => 'Disciple attendance';

  @override
  String get menuCellAbsenceByLeader => 'Absences by leader';

  @override
  String get menuCellAttendanceSessions => 'My attendance records';

  @override
  String get menuRegisterCellDisciple => 'Register disciple';

  @override
  String get cellDisciplePickCellTitle => 'Select cell group';

  @override
  String get cellDisciplePickCellHint =>
      'Choose the cell group to register the disciple in';

  @override
  String get cellsListTitle => 'Cell groups';

  @override
  String get cellsListSearchHint => 'Search by code, name, leader, or address';

  @override
  String get cellsListEmpty => 'No cell groups registered';

  @override
  String get cellsListLoadError => 'Could not load cell groups';

  @override
  String cellsListFilterOverCapacity(int max) {
    return 'More than $max disciples';
  }

  @override
  String cellsListMemberCount(int count) {
    return '$count disciples';
  }

  @override
  String get cellDiscipleTitle => 'Register disciple';

  @override
  String get cellDiscipleForCell => 'Cell group';

  @override
  String get cellDiscipleDenied =>
      'You do not have permission to register disciples';

  @override
  String get cellDiscipleSuccess => 'Disciple registered';

  @override
  String get cellDiscipleCellMissing => 'Cell group not found';

  @override
  String get cellDiscipleEmailOptional => 'Optional (no app login account)';

  @override
  String get cellDiscipleEmailLabel => 'Email (optional)';

  @override
  String get cellDiscipleEmailHelper =>
      'For contact only. Does not create an account or sign in to the app.';

  @override
  String get cellDiscipleChurchOfficeLabel => 'Church office *';

  @override
  String get cellDiscipleChurchOfficeHelper =>
      'Select the disciple\'s role or office in the church';

  @override
  String get cellDiscipleAdd => 'Register disciple';

  @override
  String get cellDiscipleListTitle => 'Disciples';

  @override
  String get cellDiscipleListEmpty => 'No disciples in this cell group yet';

  @override
  String cellDiscipleListCount(int count) {
    return '$count disciple(s)';
  }

  @override
  String get cellDiscipleDeleteTitle => 'Delete disciple';

  @override
  String get cellDiscipleDeleted => 'Disciple deleted';

  @override
  String get cellHelpersTitle => 'Cell group helpers';

  @override
  String cellHelpersHint(int max) {
    return 'Select up to $max disciples from this cell group as helpers';
  }

  @override
  String get cellHelpersEmpty => 'No helpers assigned yet';

  @override
  String get cellHelpersSelectAction => 'Select helpers';

  @override
  String cellHelpersCount(int current, int max) {
    return '$current of $max';
  }

  @override
  String cellHelpersMaxReached(int max) {
    return 'Maximum $max helpers per cell group';
  }

  @override
  String get cellHelpersSaved => 'Helpers updated';

  @override
  String get cellHelpersBadge => 'Helper';

  @override
  String get cellAttendanceRegisterTitle => 'Register attendance';

  @override
  String get cellAttendancePickCellTitle => 'Register attendance';

  @override
  String get cellAttendancePickCellHint =>
      'Select the cell group to register meeting attendance';

  @override
  String get cellAttendanceNoOwnCell => 'You do not have an assigned cell';

  @override
  String get cellAttendanceDenied =>
      'Only the cell group leader can register attendance';

  @override
  String get cellAttendanceNoDisciples =>
      'Assign disciples to the cell before registering attendance';

  @override
  String get cellAttendanceLeaderRequired =>
      'The cell group must have an assigned leader to register attendance';

  @override
  String get cellAttendanceMembersLoadError =>
      'Could not load cell group disciples';

  @override
  String get cellAttendanceSectionWhen => 'Date and time';

  @override
  String get cellAttendanceSectionWhere => 'Location';

  @override
  String get cellAttendanceSectionRoll => 'Disciple attendance';

  @override
  String get cellAttendanceSectionRollHint =>
      'Mark who attended the cell group meeting';

  @override
  String get cellAttendanceSessionDate => 'Meeting date';

  @override
  String get cellAttendanceSessionTime => 'Time';

  @override
  String get cellAttendanceSessionPlace => 'Meeting place';

  @override
  String get cellAttendanceSessionPlaceHint => 'Address or location reference';

  @override
  String get cellAttendancePlaceRequired => 'Enter the meeting place';

  @override
  String cellAttendanceDayDiffersInfo(String registeredDay, String actualDay) {
    return 'The meeting was on $actualDay, but the cell group is registered on $registeredDay.';
  }

  @override
  String get cellAttendanceDayChangeSwitch =>
      'Record with a different day for this meeting';

  @override
  String get cellAttendanceDayChangeSwitchHint =>
      'Applies only to this meeting, not the cell group\'s regular day';

  @override
  String get cellAttendanceDayChangeReason => 'Reason for day change';

  @override
  String get cellAttendanceDayReasonRequired =>
      'Explain why it was held on a different day';

  @override
  String get cellAttendanceLocationDiffersInfo =>
      'The place is different from the one registered for the cell group.';

  @override
  String get cellAttendanceLocationChangeSwitch =>
      'Record with a different place for this meeting';

  @override
  String get cellAttendanceLocationChangeSwitchHint =>
      'Applies only to this meeting, not the cell group\'s regular address';

  @override
  String get cellAttendanceLocationChangeReason => 'Reason for location change';

  @override
  String get cellAttendanceLocationReasonRequired =>
      'Explain why it was held in another place';

  @override
  String get cellAttendanceSectionNotes => 'Additional information';

  @override
  String get cellAttendanceOfferingCollected => 'Offering collected';

  @override
  String get cellAttendanceOfferingCollectedHint =>
      'Amount or detail (optional)';

  @override
  String get cellAttendanceOfferingAliasTitle => 'Offering transfer alias';

  @override
  String cellAttendanceOfferingAliasInfo(String alias) {
    return 'Transfer to: $alias';
  }

  @override
  String get cellAttendanceOfferingAliasMissing =>
      'This cell does not have a transfer alias yet';

  @override
  String get cellAttendanceObservations => 'Observations';

  @override
  String get cellAttendanceObservationsHint =>
      'Notes about the meeting (optional)';

  @override
  String cellAttendanceOfferingSummary(String amount) {
    return 'Offering: $amount';
  }

  @override
  String get cellAttendanceMarkAllPresent => 'All present';

  @override
  String get cellAttendanceMarkAllAbsent => 'All absent';

  @override
  String get cellAttendanceSaveAction => 'Save attendance';

  @override
  String get cellAttendanceSaved => 'Attendance saved';

  @override
  String get cellAttendanceUpdated => 'Attendance updated';

  @override
  String get cellAttendanceDeleted => 'Attendance deleted';

  @override
  String get cellAttendanceEditTitle => 'Edit attendance';

  @override
  String get cellAttendanceEditAction => 'Edit';

  @override
  String get cellAttendanceUpdateAction => 'Save changes';

  @override
  String get cellAttendanceDeleteTitle => 'Delete attendance';

  @override
  String get cellAttendanceDeleteAction => 'Delete';

  @override
  String cellAttendanceDeleteConfirm(String date) {
    return 'Delete attendance for $date?';
  }

  @override
  String get cellAttendanceSessionsTitle => 'My attendance records';

  @override
  String get cellAttendanceSessionsPickCellTitle => 'My attendance records';

  @override
  String get cellAttendanceSessionsPickCellHint =>
      'Select the cell group to view and manage recorded attendance';

  @override
  String get cellAttendanceSessionsDateRangeTitle => 'Date range';

  @override
  String cellAttendanceSessionsFromDate(String date) {
    return 'From $date';
  }

  @override
  String cellAttendanceSessionsToDate(String date) {
    return 'To $date';
  }

  @override
  String get cellAttendanceSessionsEmpty =>
      'No attendance records in this date range';

  @override
  String get cellAttendanceManageDenied =>
      'You do not have permission to manage attendance for this cell';

  @override
  String get cellAttendanceHistoryTitle => 'Recent attendance';

  @override
  String cellAttendanceHistoryRecentCount(int count) {
    return 'Last $count';
  }

  @override
  String cellAttendancePresentCount(int present, int total) {
    return '$present of $total present';
  }

  @override
  String get cellAttendanceDayChangedBadge => 'Different day';

  @override
  String get cellAttendanceLocationChangedBadge => 'Different place';

  @override
  String get cellAttendanceReportTitle => 'Disciple attendance';

  @override
  String get cellAttendanceReportPickCellTitle => 'Attendance by cell';

  @override
  String get cellAttendanceReportPickCellHint =>
      'Select a cell group to view disciple attendance';

  @override
  String get cellAttendanceReportNoOwnCell =>
      'You do not have an assigned cell';

  @override
  String get cellAttendanceReportDenied =>
      'You do not have permission to view the attendance report';

  @override
  String cellAttendanceReportSessionCount(int count) {
    return '$count meetings recorded';
  }

  @override
  String cellAttendanceReportFilteredSessionCount(int filtered, int total) {
    return '$filtered of $total meetings in range';
  }

  @override
  String get cellAttendanceReportWeekFilterTitle => 'Week range';

  @override
  String get cellAttendanceReportWeekFrom => 'From week';

  @override
  String get cellAttendanceReportWeekTo => 'To week';

  @override
  String get cellAttendanceReportWeekAll => 'All';

  @override
  String cellAttendanceReportWeekPreset(int count) {
    return 'Last $count wks';
  }

  @override
  String get cellAttendanceReportLegendTitle => 'Consecutive absence alerts';

  @override
  String get cellAttendanceReportLegendExcellent =>
      'Green: 0 or 1 consecutive absence';

  @override
  String get cellAttendanceReportLegendWarning =>
      'Yellow: 2 consecutive absences';

  @override
  String get cellAttendanceReportLegendCritical =>
      'Red: 3 or more consecutive absences';

  @override
  String get cellAbsenceByLeaderTitle => 'Absences by leader';

  @override
  String get cellAbsenceByLeaderDenied =>
      'Only the church administrator can view this report';

  @override
  String get cellAbsenceByLeaderNoChurch =>
      'Your account has no church assigned';

  @override
  String get cellAbsenceByLeaderLoadError =>
      'Could not load the absence report';

  @override
  String get cellAbsenceByLeaderEmpty =>
      'There are no cell groups with an assigned leader in your church';

  @override
  String cellAbsenceByLeaderCellLabel(String code) {
    return 'Cell $code';
  }

  @override
  String cellAbsenceByLeaderCriticalCount(int count) {
    return '$count disciples with 3+ consecutive absences';
  }

  @override
  String cellAbsenceByLeaderTotalCritical(int count) {
    return 'Total: $count disciples in red alert';
  }

  @override
  String get cellAbsenceByLeaderLeaderOk =>
      'No disciples with 3 or more consecutive absences';

  @override
  String get cellAttendanceReportMembersTitle => 'Disciples';

  @override
  String get cellAttendanceReportEmpty =>
      'No disciples in this cell or no attendance recorded yet';

  @override
  String cellAttendanceReportMemberStats(
    int present,
    int consecutive,
    int total,
  ) {
    return '$present present · $consecutive in a row · $total roll calls';
  }

  @override
  String get cellMemberAssignTitle => 'Cell disciples';

  @override
  String get cellMemberAssignAction => 'Assign disciples';

  @override
  String get cellDetailAssignDisciplesAction => 'Assign disciples';

  @override
  String get cellMemberAssignAdd => 'Add disciple';

  @override
  String get cellMemberRegisterNew => 'Register new disciple';

  @override
  String get cellMemberRegisterTitle => 'Register disciple in cell';

  @override
  String get cellMemberFormHint =>
      'Register disciples for this cell group. If a visit is requested, the cell group leader will be assigned.';

  @override
  String get cellMemberFormSubmit => 'Register in cell group';

  @override
  String get cellMemberWantsVisitSubtitle =>
      'If a visit is requested, this cell group\'s leader will be assigned automatically';

  @override
  String get cellMemberIsNewBelieverSubtitle =>
      'Turn on if this disciple should be registered as a new believer';

  @override
  String cellMemberVisitLeaderHint(String leader, String cell) {
    return '$leader will be assigned as leader (cell group $cell)';
  }

  @override
  String get cellMemberVisitNoLeader =>
      'This cell group has no assigned leader. Assign a leader to the cell group or turn off the visit request.';

  @override
  String get cellClaimLeadershipTitle => 'No cell leader assigned';

  @override
  String get cellClaimLeadershipSubtitle =>
      'This cell group has no leader. You can assign yourself to register visits and disciples.';

  @override
  String get cellClaimLeadershipAction => 'Assign myself as leader';

  @override
  String get cellClaimLeadershipSuccess =>
      'You are now the leader of this cell group.';

  @override
  String get cellClaimLeadershipAlreadyAssigned =>
      'You already lead another cell group. A leader can only lead one cell group.';

  @override
  String get cellClaimLeadershipDenied =>
      'You do not have permission to assign yourself as leader of this cell group.';

  @override
  String cellMemberRegisteredWithCellLeader(
    String name,
    String cell,
    String leader,
  ) {
    return '$name registered in $cell with visit assigned to $leader';
  }

  @override
  String get myAssignedCellTitle => 'My cell';

  @override
  String get myAssignedCellDenied =>
      'You do not have permission to view the assigned cell';

  @override
  String get myAssignedCellLoadError => 'Could not load cell information';

  @override
  String get myAssignedCellNoLeaderProfile =>
      'Your leader account is not linked to a leader profile in the system';

  @override
  String get myAssignedCellEmpty => 'You do not have an assigned cell';

  @override
  String myAssignedCellLeaderLabel(String name) {
    return 'Leader: $name';
  }

  @override
  String cellMemberRegisteredAndAssigned(String name, String cell) {
    return '$name registered and assigned to $cell';
  }

  @override
  String cellMemberAssignHint(String cell) {
    return 'Assign disciples without a cell to $cell. Cell assignment is separate from the disciple\'s assigned leader.';
  }

  @override
  String get cellMemberListTitle => 'Disciples';

  @override
  String get cellMemberListEmpty => 'No disciples assigned to this cell yet';

  @override
  String get cellMemberSelectTitle => 'Select disciples';

  @override
  String get cellMemberSelectHint =>
      'Only disciples assigned to this cell group\'s leader through pastoral registration, without another cell, are shown';

  @override
  String cellMemberSelectConfirm(int count) {
    return 'Assign $count';
  }

  @override
  String get cellMemberSelectRequiresChurch =>
      'Cannot assign disciples without a church on your account';

  @override
  String get cellMemberSelectSearchHint => 'Search by name, phone or leader';

  @override
  String get cellMemberSelectEmpty =>
      'No disciples from this cell group\'s leader are available to assign';

  @override
  String cellMemberSelectMaxReached(int max) {
    return 'Maximum $max disciple(s) per cell';
  }

  @override
  String cellMemberSelectLimitHint(int max, int total) {
    return 'You can select up to $max disciple(s). A cell holds $total at most.';
  }

  @override
  String cellMemberAssignLimitReached(int max) {
    return 'This cell already has the maximum of $max disciples. No more can be assigned.';
  }

  @override
  String cellMemberAssignLimitPartial(int assigned, int requested, int max) {
    return 'Assigned $assigned of $requested: a cell holds $max disciples at most.';
  }

  @override
  String get cellMemberSelectLoadError => 'Could not load disciples';

  @override
  String cellMemberAssigned(String name) {
    return '$name assigned to the cell';
  }

  @override
  String cellMemberAssignedMultiple(int count) {
    return '$count disciples assigned to the cell';
  }

  @override
  String get cellMemberUnassignTitle => 'Remove from cell';

  @override
  String cellMemberUnassignConfirm(String name) {
    return 'Remove $name from this cell?';
  }

  @override
  String get cellMemberUnassignAction => 'Remove';

  @override
  String cellMemberAssignGenderHint(String gender) {
    return 'Only disciples of the same sex as the cell leader can be assigned ($gender).';
  }

  @override
  String get cellMemberAssignLeaderGenderMissing =>
      'The cell leader has no sex on file. Complete their profile before assigning disciples.';

  @override
  String get cellMemberAssignCellLeaderRequired =>
      'This cell group must have an assigned leader before you can select disciples.';

  @override
  String get cellMemberAssignGenderMismatch =>
      'You can only assign disciples of the same sex as the cell leader.';

  @override
  String get cellMemberAssignLeaderExcluded =>
      'Leaders cannot be assigned as cell disciples.';

  @override
  String cellMemberSelectEmptyGender(String gender) {
    return 'No disciples from this cell group\'s leader match the leader\'s sex ($gender).';
  }

  @override
  String cellMemberSelectGenderHint(String gender) {
    return 'Only pastoral-registration disciples of this cell group\'s leader, matching sex ($gender), without another cell, are shown.';
  }

  @override
  String cellMemberRegisterGenderLocked(String gender) {
    return 'Must be $gender, same as the cell leader.';
  }

  @override
  String cellMemberUnassigned(String name) {
    return '$name is no longer assigned to this cell';
  }

  @override
  String get baptismCalendarTitle => 'Baptism calendar';

  @override
  String get baptismCalendarRegisterTitle => 'Register baptism date';

  @override
  String get baptismCalendarAdd => 'Register date';

  @override
  String get baptismCalendarTime => 'Time (optional)';

  @override
  String get baptismCalendarTimeHint => 'E.g.: 10:00';

  @override
  String get baptismCalendarLocation => 'Location (optional)';

  @override
  String get baptismCalendarNotes => 'Notes (optional)';

  @override
  String get baptismCalendarSuccess => 'Baptism date registered';

  @override
  String get baptismCalendarDeleted => 'Baptism date removed';

  @override
  String get baptismCalendarDenied =>
      'You do not have permission to view the baptism calendar';

  @override
  String get baptismCalendarLoadError => 'Could not load the baptism calendar';

  @override
  String get baptismCalendarEmpty => 'No baptisms scheduled';

  @override
  String get baptismCalendarSelectDay => 'Select a day on the calendar';

  @override
  String baptismCalendarDayTitle(String date) {
    return 'Baptisms on $date';
  }

  @override
  String get baptismCalendarDayEmpty => 'No baptisms scheduled for this day';

  @override
  String get baptismCalendarUpcoming => 'Upcoming baptisms';

  @override
  String get baptismCalendarDeleteTitle => 'Delete baptism date';

  @override
  String baptismCalendarDeleteConfirm(String date) {
    return 'Delete the baptism scheduled for $date?';
  }

  @override
  String get baptismCalendarAssignMembersAction => 'Assign believers';

  @override
  String get baptismCalendarAssignMembersTitle => 'Members for baptism';

  @override
  String get baptismCalendarAssignMembersHint =>
      'Select unbaptized believers who will be baptized on this date';

  @override
  String get baptismCalendarAssignMembersSearchHint =>
      'Search by name or phone';

  @override
  String get baptismCalendarAssignMembersEmpty =>
      'No unbaptized believers available to assign';

  @override
  String get memberIsBaptized => 'Baptized';

  @override
  String get memberIsBaptizedSubtitle =>
      'When enabled, they will not appear in the baptism calendar';

  @override
  String get baptismCalendarAssignMembersLoadError => 'Could not load members';

  @override
  String baptismCalendarAssignMembersConfirm(int count) {
    return 'Save ($count)';
  }

  @override
  String baptismCalendarAssignedCount(int count) {
    return '$count member(s) assigned';
  }

  @override
  String baptismCalendarMembersAssigned(int count) {
    return '$count member(s) assigned to the baptism';
  }

  @override
  String get baptismCalendarAddForDay => 'Schedule baptism for this day';

  @override
  String get baptismCalendarUpdated => 'Baptism updated';

  @override
  String get baptismCalendarSelectEvent => 'Event for this day';

  @override
  String get baptismCalendarMembersSection => 'Assigned members';

  @override
  String get baptismCalendarMembersEmpty => 'No members assigned yet';

  @override
  String get baptismCalendarDeleteAction => 'Delete baptism';

  @override
  String get baptismCalendarCreateBelieverToBaptize =>
      'Create new believer to baptize';

  @override
  String get baptismCalendarRegisterBelieverTitle =>
      'Register believer to baptize';

  @override
  String get baptismCalendarRegisterBelieverButton => 'Register believer';

  @override
  String get baptismCalendarBelieverCreatedScheduleFirst =>
      'Believer registered. Schedule the baptism for this day to assign them.';

  @override
  String baptismCalendarBelieverCreatedAndAssigned(String name) {
    return '$name registered and assigned to the baptism';
  }

  @override
  String get baptismCalendarBelieverAlreadyBaptized =>
      'This believer is already marked as baptized';

  @override
  String baptismCalendarBelieverAlreadyAssigned(String name) {
    return '$name is already assigned to this baptism';
  }

  @override
  String get baptismCalendarPastReadOnlyHint =>
      'This baptism date has passed. It cannot be edited; only confirm who was baptized.';

  @override
  String get baptismCalendarConfirmBaptizedSection => 'Confirm baptized';

  @override
  String get baptismCalendarConfirmBaptizedHint =>
      'Check the believers who were baptized on this date';

  @override
  String get baptismCalendarConfirmBaptizedAction => 'Save confirmation';

  @override
  String baptismCalendarConfirmBaptizedSuccess(int count) {
    return '$count believer(s) confirmed as baptized';
  }

  @override
  String get baptismCalendarRemoveMemberTitle => 'Remove from baptism';

  @override
  String baptismCalendarRemoveMemberConfirm(String name) {
    return 'Remove $name from this baptism?';
  }

  @override
  String get baptismCalendarRemoveMemberAction => 'Remove';

  @override
  String baptismCalendarRemoveMemberSuccess(String name) {
    return '$name is no longer assigned to this baptism';
  }

  @override
  String get leaderRegMobileRequired => 'Enter the mobile number';

  @override
  String get leaderRegSectionAppAccess => 'APP ACCESS';

  @override
  String get leaderRegEmailLoginHint =>
      'The leader will sign in with their email as username.';

  @override
  String get leaderRegEmailLabel => 'Email (login username)';

  @override
  String get leaderRegEmailLabelRequired => 'Email (login username) *';

  @override
  String get leaderRegEmailLockedHelper =>
      'The account was already created; the email cannot be changed here';

  @override
  String get leaderRegEmailAdminEditHelper =>
      'This will also update the sign-in email';

  @override
  String get leaderRegEmailLoginHelper =>
      'This will be the username to sign in';

  @override
  String get leaderRegEmailRequired => 'Enter the leader\'s email';

  @override
  String leaderRegEmailUpdateFailed(String message) {
    return 'Could not update the sign-in email: $message';
  }

  @override
  String get leaderRegPasswordRequired => 'Enter a password';

  @override
  String get leaderRegSubmitButton => 'Register leader';

  @override
  String get leaderRegLastName => 'Last name *';

  @override
  String get leaderRegLastNameRequired => 'Enter the last name';

  @override
  String get leaderRegFirstNames => 'First names *';

  @override
  String get leaderRegFirstNamesRequired => 'Enter the first names';

  @override
  String get leaderRegBirthDate => 'Date of birth';

  @override
  String get leaderRegAge => 'Age';

  @override
  String get adminRegNewTitle => 'New administrator';

  @override
  String get adminRegEditTitle => 'Edit administrator';

  @override
  String get adminRegNoChurches =>
      'No active churches. Create one or unblock an existing church.';

  @override
  String get adminRegCreateChurch => 'Create church';

  @override
  String get adminRegSelectChurch => 'Select a church';

  @override
  String get adminRegNewChurch => 'New church';

  @override
  String get adminRegChurchCreated =>
      'Church created. Select it from the list.';

  @override
  String get adminRegSelectChurchForAdmin =>
      'Select the church for this administrator.';

  @override
  String get adminRegUpdated => 'Administrator updated';

  @override
  String get adminRegSuccess => 'Administrator registered successfully';

  @override
  String get adminRegSaveProfileError => 'Error saving the profile.';

  @override
  String adminRegRegisterError(String error) {
    return 'Registration error: $error';
  }

  @override
  String get adminRegEditDenied =>
      'Only the super administrator can edit administrators.';

  @override
  String get adminRegRegisterDenied =>
      'Only the super administrator can register church administrators.';

  @override
  String get adminRegSectionAccount => 'ACCOUNT';

  @override
  String get adminRegEmailLockedHelper =>
      'The sign-in email cannot be changed from here.';

  @override
  String get adminRegSectionChurch => 'ASSIGNED CHURCH';

  @override
  String get adminRegChurchHint =>
      'This administrator will only manage the selected church.';

  @override
  String get adminRegPasswordRequired => 'Enter the password';

  @override
  String get adminRegRegisterButton => 'Register administrator';

  @override
  String get editPersonalDataSectionName => 'NAME';

  @override
  String get editPersonalDataSectionContact => 'CONTACT';

  @override
  String get churchServiceStorageNotConfigured =>
      'Firebase Storage is not enabled for this project. In Firebase Console → Storage, click \"Get started\", choose a location, and upload the logo again.';

  @override
  String get churchServicePermissionDenied =>
      'You do not have permission to manage churches.';

  @override
  String get churchServiceNotFound => 'The church no longer exists.';

  @override
  String get churchServiceUploadUnauthorized =>
      'Not authorized to upload the file. In debug this is usually App Check: register the debug token in Firebase Console (correct project), or wait 15 min if throttled.';

  @override
  String get churchServiceAppCheckError =>
      'App Check is not configured. In development: find \"App Check debug token\" in logcat, register it in Firebase Console → App Check → Android, then fully restart the app.';

  @override
  String get churchServiceAppCheckThrottled =>
      'App Check blocked due to too many attempts. Wait 15 minutes, register the debug token in Firebase Console, or temporarily disable App Check enforcement on Storage.';

  @override
  String churchServiceSaveError(String message) {
    return 'Error saving: $message';
  }

  @override
  String get userProfileAdminPermissionDenied =>
      'You do not have permission to manage administrators.';

  @override
  String userProfileError(String message) {
    return 'Error: $message';
  }

  @override
  String get supervisorServicePermissionDenied =>
      'You do not have permission to assign leaders to supervisors.';
}
