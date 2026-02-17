import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_yo.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('yo')
  ];

  /// The name of the app
  ///
  /// In en, this message translates to:
  /// **'Sunday School Lessons'**
  String get appName;

  /// Language preference label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Title when a lesson exists for the selected date
  ///
  /// In en, this message translates to:
  /// **'Sunday School Lesson'**
  String get sundaySchoolLesson;

  /// Title when no lesson exists for the selected date
  ///
  /// In en, this message translates to:
  /// **'No Lesson Available Today'**
  String get noLessonToday;

  /// Shown when there is no teen lesson
  ///
  /// In en, this message translates to:
  /// **'No Teen Lesson available'**
  String get noTeenLesson;

  /// Shown when there is no adult lesson
  ///
  /// In en, this message translates to:
  /// **'No Adult Lesson available'**
  String get noAdultLesson;

  /// Title for the app or manual section
  ///
  /// In en, this message translates to:
  /// **'RCCG - Sunday School Manual'**
  String get sundaySchoolManual;

  /// Promotional subtitle highlighting offline access to lessons
  ///
  /// In en, this message translates to:
  /// **'Access your weekly Teen and Adult Bible study lessons anytime, anywhere — even offline!'**
  String get accessWeeklyLessonsOffline;

  /// Branding statement for RCCG users
  ///
  /// In en, this message translates to:
  /// **'Built for the Redeemed Christian Church of God!'**
  String get builtForRccg;

  /// Call-to-action button to begin using the app
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Button text to open the full chapter view
  ///
  /// In en, this message translates to:
  /// **'Open full chapter →'**
  String get openFullChapter;

  /// Button text to close a dialog or screen
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Loading indicator text shown during preparation/setup
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get preparing;

  /// Loading indicator with progress counter (e.g. during multi-step process)
  ///
  /// In en, this message translates to:
  /// **'Preparing... ({progress}/{totalSteps})'**
  String preparingWithProgress(Object progress, Object totalSteps);

  /// Login button label
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Subtitle text on login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to create or join your church'**
  String get signInToCreateOrJoin;

  /// Google sign-in option label
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// Apple sign-in option label
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// Guest/anonymous login option
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// Error message when sign-in fails
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed'**
  String get signInFailed;

  /// Error message when Apple sign-in fails
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed'**
  String get applSignInFailed;

  /// Error message when guest login fails
  ///
  /// In en, this message translates to:
  /// **'Guest mode failed'**
  String get guestModeFailed;

  /// Default name for guest users
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUser;

  /// Label indicating user is in guest/anonymous mode
  ///
  /// In en, this message translates to:
  /// **'guest mode'**
  String get guestMode;

  /// Anonymous user label
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// Button label for Google sign-in
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Button label for Apple sign-in (iOS only)
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// Button label for guest/anonymous mode
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// Warning shown below guest login button about data loss
  ///
  /// In en, this message translates to:
  /// **'All data are temporarily saved and lost after logout.'**
  String get guestDataWarning;

  /// Explanation of benefits when choosing regular login
  ///
  /// In en, this message translates to:
  /// **'Full access: create or join your church'**
  String get fullAccessDescription;

  /// Explanation of limitations in guest mode
  ///
  /// In en, this message translates to:
  /// **'Limited access: use general mode only'**
  String get limitedAccessDescription;

  /// User profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Bookmarks/saved items section
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// Daily streaks section
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get streaks;

  /// Leaderboard/rankings section
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// Assignments section for users
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignments;

  /// Sound effect toggle
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get soundEffects;

  /// No description provided for @ageGroup.
  ///
  /// In en, this message translates to:
  /// **'Age Group'**
  String get ageGroup;

  /// Teachers/grading section for admins
  ///
  /// In en, this message translates to:
  /// **'Teachers'**
  String get teachers;

  /// App suggestions/feedback section
  ///
  /// In en, this message translates to:
  /// **'App Suggestions'**
  String get appSuggestions;

  /// Admin tools section
  ///
  /// In en, this message translates to:
  /// **'Admin Tools'**
  String get adminTools;

  /// Color palette customization
  ///
  /// In en, this message translates to:
  /// **'Color Palette'**
  String get colorPalette;

  /// Label for the name of the user's parish/church
  ///
  /// In en, this message translates to:
  /// **'Parish'**
  String get parish;

  /// Label for the 6-digit code used to join a parish/church
  ///
  /// In en, this message translates to:
  /// **'Join Code'**
  String get joinCode;

  /// Label for the name of the pastor of the parish/church
  ///
  /// In en, this message translates to:
  /// **'Pastor'**
  String get pastor;

  /// Fallback text shown when a value (e.g. pastor name, access code) is missing or not set
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// Main button / section title for account deletion
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// Shown when deletion is already scheduled, with date
  ///
  /// In en, this message translates to:
  /// **'Account scheduled for permanent deletion on:\n{date}'**
  String deletionScheduledOn(Object date);

  /// Instruction when deletion is scheduled
  ///
  /// In en, this message translates to:
  /// **'Log in before this date to cancel deletion and restore your account.'**
  String get logInToCancel;

  /// Warning text before initiating deletion
  ///
  /// In en, this message translates to:
  /// **'Your account and all data will be permanently deleted after 30 days.\nYou can cancel anytime by logging back in.'**
  String get permanentDeletionWarning;

  /// Title of confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountDialogTitle;

  /// Detailed warning in confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'• Your account will be permanently deleted in 30 days.\n• All your data (bookmarks, streaks, assignments, leaderboard) will be gone.\n• You can cancel this anytime by simply logging back in.\n\nAre you sure?'**
  String get deleteAccountDialogContent;

  /// Button label to cancel a scheduled account deletion
  ///
  /// In en, this message translates to:
  /// **'Cancel Deletion'**
  String get cancelDeletion;

  /// Confirm deletion button in dialog
  ///
  /// In en, this message translates to:
  /// **'Delete in 30 Days'**
  String get deleteIn30Days;

  /// Button text when deletion is already scheduled
  ///
  /// In en, this message translates to:
  /// **'Deletion Scheduled'**
  String get deletionScheduledButton;

  /// SnackBar message after scheduling deletion
  ///
  /// In en, this message translates to:
  /// **'Account scheduled for deletion in 30 days. Log in to cancel.'**
  String get accountDeletionScheduledSnack;

  /// SnackBar message after cancelling deletion
  ///
  /// In en, this message translates to:
  /// **'Account deletion cancelled! Welcome back 🎉'**
  String get deletionCancelledSnack;

  /// Feedback section header
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// Menu item to rate app
  ///
  /// In en, this message translates to:
  /// **'Rate App in store'**
  String get rateAppInStore;

  /// Menu item to suggest features
  ///
  /// In en, this message translates to:
  /// **'Suggest a Feature'**
  String get suggestAFeature;

  /// User preferences section
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// Sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Register button
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Join button
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// Register a new parish/church
  ///
  /// In en, this message translates to:
  /// **'Register a Parish'**
  String get registerParish;

  /// Create a new church
  ///
  /// In en, this message translates to:
  /// **'Create Church'**
  String get createChurch;

  /// Join an existing church
  ///
  /// In en, this message translates to:
  /// **'Join Church'**
  String get joinChurch;

  /// Select church dialog title
  ///
  /// In en, this message translates to:
  /// **'Select a Church'**
  String get selectChurch;

  /// Access code for joining a church
  ///
  /// In en, this message translates to:
  /// **'Church Access Code'**
  String get churchAccessCode;

  /// Name of the church
  ///
  /// In en, this message translates to:
  /// **'Church Name'**
  String get churchName;

  /// Name of the pastor
  ///
  /// In en, this message translates to:
  /// **'Pastor\'s Name *'**
  String get pastorName;

  /// Leave the current church
  ///
  /// In en, this message translates to:
  /// **'Leave Church'**
  String get leaveChurch;

  /// Church selection prompt
  ///
  /// In en, this message translates to:
  /// **'Select your church'**
  String get selectYourChurch;

  /// Message when no church is selected
  ///
  /// In en, this message translates to:
  /// **'No Church Selected'**
  String get noChurchSelected;

  /// Confirmation message shown after the user successfully joins a parish or church
  ///
  /// In en, this message translates to:
  /// **'Joined successfully!'**
  String get joinedSuccessfully;

  /// Share lesson as PDF option
  ///
  /// In en, this message translates to:
  /// **'Share as PDF'**
  String get shareAsLessonPdf;

  /// Share lesson link option
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get shareLink;

  /// Prompt to sign in to save lessons
  ///
  /// In en, this message translates to:
  /// **'Sign in and join a church to save lessons'**
  String get saveLessonPrompt;

  /// Success message when lesson is removed from saved
  ///
  /// In en, this message translates to:
  /// **'Lesson removed from saved'**
  String get lessonRemovedFromSaved;

  /// Success message when lesson is saved
  ///
  /// In en, this message translates to:
  /// **'Lesson saved! 📚'**
  String get lessonSaved;

  /// Generic operation failed message
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get operationFailed;

  /// Tooltip for remove from saved lessons button
  ///
  /// In en, this message translates to:
  /// **'Remove from saved lessons'**
  String get removedFromSavedLessons;

  /// Tooltip for save lesson button
  ///
  /// In en, this message translates to:
  /// **'Save this lesson'**
  String get saveThisLesson;

  /// Message when a Bible verse is temporarily unavailable
  ///
  /// In en, this message translates to:
  /// **'Verse temporarily unavailable'**
  String get verseTemporarilyUnavailable;

  /// Tooltip for remove from saved readings button
  ///
  /// In en, this message translates to:
  /// **'Remove from saved readings'**
  String get removedFromSavedReadings;

  /// Tooltip for save reading button
  ///
  /// In en, this message translates to:
  /// **'Save this reading'**
  String get saveThisReading;

  /// Error message when user hasn't selected a church
  ///
  /// In en, this message translates to:
  /// **'Please select your church first!'**
  String get pleaseSelectYourChurchFirst;

  /// Validation message for assignment responses
  ///
  /// In en, this message translates to:
  /// **'Please enter at least one answer to the question.'**
  String get pleaseEnterAtLeastOneAnswer;

  /// Success message after submitting assignment
  ///
  /// In en, this message translates to:
  /// **'Your answers have been submitted successfully!'**
  String get yourAnswersHaveBeenSubmitted;

  /// Error message when assignment save fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save your answers. Please try again.'**
  String get failedToSaveYourAnswers;

  /// Error message for unauthorized access
  ///
  /// In en, this message translates to:
  /// **'Global admins only — no church selected.'**
  String get globalAdminsOnlyNoChurch;

  /// Button to add another response field
  ///
  /// In en, this message translates to:
  /// **'Add another response'**
  String get addAnotherResponse;

  /// Empty state message
  ///
  /// In en, this message translates to:
  /// **'No submissions yet.'**
  String get noSubmissionsYet;

  /// Current submission status label
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get currentStatus;

  /// Status: assignment submitted
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// Status: assignment not submitted
  ///
  /// In en, this message translates to:
  /// **'Not Submitted'**
  String get notSubmitted;

  /// Status: assignment graded
  ///
  /// In en, this message translates to:
  /// **'Graded'**
  String get graded;

  /// Button to view feedback
  ///
  /// In en, this message translates to:
  /// **'View Feedback'**
  String get viewFeedback;

  /// Button to leave feedback
  ///
  /// In en, this message translates to:
  /// **'Leave Feedback'**
  String get leaveFeedback;

  /// Title of lesson
  ///
  /// In en, this message translates to:
  /// **'Lesson Title'**
  String get lessonTitle;

  /// Topic of lesson
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get topic;

  /// Bible passage reference
  ///
  /// In en, this message translates to:
  /// **'BIBLE PASSAGE:'**
  String get biblePassage;

  /// Label for guest user
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUserLabel;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// Button or label to start answering the weekly assignment
  ///
  /// In en, this message translates to:
  /// **'Weekly Assignment'**
  String get answerWeeklyAssignment;

  /// Prompt shown when user needs to log in to access/submit assignment
  ///
  /// In en, this message translates to:
  /// **'Login For Assignment'**
  String get loginForAssignment;

  /// Prompt shown when user needs to sign in to submit assignment
  ///
  /// In en, this message translates to:
  /// **'Sign in to Submit'**
  String get signinToSubmit;

  /// Day of week: Monday
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// Day of week: Tuesday
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// Day of week: Wednesday
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// Day of week: Thursday
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// Day of week: Friday
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// Day of week: Saturday
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// Day of week: Sunday
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @monthShortJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthShortJan;

  /// No description provided for @monthShortFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthShortFeb;

  /// No description provided for @monthShortMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthShortMar;

  /// No description provided for @monthShortApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthShortApr;

  /// No description provided for @monthShortMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthShortMay;

  /// No description provided for @monthShortJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthShortJun;

  /// No description provided for @monthShortJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthShortJul;

  /// No description provided for @monthShortAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthShortAug;

  /// No description provided for @monthShortSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthShortSep;

  /// No description provided for @monthShortOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthShortOct;

  /// No description provided for @monthShortNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthShortNov;

  /// No description provided for @monthShortDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthShortDec;

  /// Month: January
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// Month: February
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// Month: March
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// Month: April
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// Month: May
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// Month: June
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// Month: July
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// Month: August
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// Month: September
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// Month: October
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// Month: November
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// Month: December
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// Message when switched to general lessons
  ///
  /// In en, this message translates to:
  /// **'Switched to General (Global) lessons'**
  String get switchedToGeneral;

  /// Title for share lesson dialog
  ///
  /// In en, this message translates to:
  /// **'Share Lesson'**
  String get shareLesson;

  /// Reading streak page title
  ///
  /// In en, this message translates to:
  /// **'Reading Streak'**
  String get readingStreak;

  /// Label for today's reading section
  ///
  /// In en, this message translates to:
  /// **'Today\'s Reading:'**
  String get todaysReading;

  /// Empty state message for today's reading
  ///
  /// In en, this message translates to:
  /// **'No Reading'**
  String get noReading;

  /// Button to mark reading as complete
  ///
  /// In en, this message translates to:
  /// **'Complete Reading'**
  String get completeReading;

  /// Display of reading timer
  ///
  /// In en, this message translates to:
  /// **'Time till streak… ({remainingSeconds} s)'**
  String readingTimer(Object remainingSeconds);

  /// Label for memory verse section
  ///
  /// In en, this message translates to:
  /// **'Memory verse:'**
  String get memoryVerse;

  /// Label for prayer section
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get prayer;

  /// Empty state message for bookmarks
  ///
  /// In en, this message translates to:
  /// **'No Bookmarks Yet'**
  String get noBookmarksYet;

  /// Prompt to sign in to save favorites
  ///
  /// In en, this message translates to:
  /// **'Sign in to save your favorites'**
  String get signInToSaveFavorites;

  /// Message about bookmarks syncing across devices
  ///
  /// In en, this message translates to:
  /// **'Bookmarks, lessons, and readings will sync across your devices.'**
  String get bookmarksSyncMessage;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// French language option
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get francais;

  /// Message when content is copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;

  /// Error message for invalid lesson ID
  ///
  /// In en, this message translates to:
  /// **'Invalid saved lesson id'**
  String get invalidSavedLessonId;

  /// Error message when lesson is not found
  ///
  /// In en, this message translates to:
  /// **'Lesson not found'**
  String get lessonNotFound;

  /// Error message when saved lesson content is unavailable
  ///
  /// In en, this message translates to:
  /// **'Saved lesson content not available'**
  String get savedLessonContentNotAvailable;

  /// Validation message to add a comment
  ///
  /// In en, this message translates to:
  /// **'Please add a comment'**
  String get pleaseAddAComment;

  /// Success message after feedback submission
  ///
  /// In en, this message translates to:
  /// **'Thank you! Feedback submitted.'**
  String get thankYouFeedbackSubmitted;

  /// Error message when sharing church fails
  ///
  /// In en, this message translates to:
  /// **'Error sharing church: {error}'**
  String errorSharingChurch(Object error);

  /// Confirmation message after leaving church
  ///
  /// In en, this message translates to:
  /// **'You have left the church'**
  String get youHaveLeftTheChurch;

  /// Message when user not logged in to view assignments
  ///
  /// In en, this message translates to:
  /// **'Please log in to view your assignments'**
  String get pleaseLogInToViewAssignments;

  /// Title for teen assignment responses
  ///
  /// In en, this message translates to:
  /// **'Teen Responses'**
  String get teenResponses;

  /// Title for adult assignment responses
  ///
  /// In en, this message translates to:
  /// **'Adult Responses'**
  String get adultResponses;

  /// Button to edit responses
  ///
  /// In en, this message translates to:
  /// **'Edit Responses'**
  String get editResponses;

  /// Display of user's assignment score
  ///
  /// In en, this message translates to:
  /// **'Your Score: {score} / {total}'**
  String yourScore(Object score, Object total);

  /// Label for my responses section
  ///
  /// In en, this message translates to:
  /// **'My Responses:'**
  String get myResponses;

  /// No description provided for @assignmentGradedToast.
  ///
  /// In en, this message translates to:
  /// **'Your assignment has been graded'**
  String get assignmentGradedToast;

  /// Label for submitted responses
  ///
  /// In en, this message translates to:
  /// **'Your submitted responses'**
  String get yourSubmittedResponses;

  /// Message indicating assignment has been graded
  ///
  /// In en, this message translates to:
  /// **'This assignment has been graded'**
  String get assignmentGraded;

  /// Indicates graded assignment cannot be edited
  ///
  /// In en, this message translates to:
  /// **'Graded — cannot edit'**
  String get gradedNoEdit;

  /// Message when no assignment question exists
  ///
  /// In en, this message translates to:
  /// **'No question available.'**
  String get noQuestionAvailable;

  /// Message when no question is available for the selected day
  ///
  /// In en, this message translates to:
  /// **'No question available for this day.'**
  String get noQuestionAvailableForThisDay;

  /// Title of the user's assignment page/section
  ///
  /// In en, this message translates to:
  /// **'My Assignment'**
  String get myAssignment;

  /// Title for the current week's assignment
  ///
  /// In en, this message translates to:
  /// **'This Week\'s Assignment'**
  String get thisWeeksAssignment;

  /// Due date label with formatted date placeholder
  ///
  /// In en, this message translates to:
  /// **'Due: {dateFormatted}'**
  String dueDateFormatted(Object dateFormatted);

  /// Label indicating the assignment was graded by a teacher
  ///
  /// In en, this message translates to:
  /// **'Graded by Teacher'**
  String get gradedByTeacher;

  /// Section header for teacher's feedback
  ///
  /// In en, this message translates to:
  /// **'Teacher\'s Feedback:'**
  String get teachersFeedback;

  /// Shown when teacher left no feedback
  ///
  /// In en, this message translates to:
  /// **'No teacher feedback provided.'**
  String get noTeacherFeedbackProvided;

  /// Status message for submitted assignment with edit instruction
  ///
  /// In en, this message translates to:
  /// **'Submitted — tap Edit to change'**
  String get submittedTapEditToChange;

  /// Placeholder text for response input field
  ///
  /// In en, this message translates to:
  /// **'Write your response here...'**
  String get writeYourResponseHere;

  /// Button label to submit responses
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Shown while loading the assignment question
  ///
  /// In en, this message translates to:
  /// **'Loading question...'**
  String get loadingQuestion;

  /// Header for teen or adult responses (dynamic based on type)
  ///
  /// In en, this message translates to:
  /// **'Responses'**
  String get teenOrAdultResponses;

  /// Label for the assignment question
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// Header for list of submissions
  ///
  /// In en, this message translates to:
  /// **'Submissions'**
  String get submissions;

  /// Formatted display of an individual answer
  ///
  /// In en, this message translates to:
  /// **'Answer {i}: {answer}'**
  String answerWithIndex(Object i, Object answer);

  /// Button to reset/clear form or selections
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Button or action to grade an assignment
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get grade;

  /// Title for teenage lesson
  ///
  /// In en, this message translates to:
  /// **'Teenager Sunday School Lesson'**
  String get teenSundaySchoolLesson;

  /// Title for adult lesson
  ///
  /// In en, this message translates to:
  /// **'Adult Sunday School Lesson'**
  String get adultSundaySchoolLesson;

  /// Warning message about being signed out
  ///
  /// In en, this message translates to:
  /// **'You\'ll be signed out and returned to the login screen.'**
  String get youWillBeSignedOut;

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Leave without joining?'**
  String get leaveWithoutJoining;

  /// Subtitle for registering parish
  ///
  /// In en, this message translates to:
  /// **'Set up your parish and become its admin'**
  String get setUpYourParish;

  /// Subtitle for joining parish
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code provided by your parish admin'**
  String get enterSixDigitCode;

  /// Message when color hex is copied
  ///
  /// In en, this message translates to:
  /// **'Copied: {hex}'**
  String copiedHex(Object hex);

  /// Title for RCCG general lessons
  ///
  /// In en, this message translates to:
  /// **'RCCG Sunday School (General)'**
  String get rccgSundaySchoolGeneral;

  /// Title of saved items page
  ///
  /// In en, this message translates to:
  /// **'Saved Items'**
  String get savedItems;

  /// Generic error loading data message
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorLoadingData(Object error);

  /// Empty state for leaderboard
  ///
  /// In en, this message translates to:
  /// **'No rankings yet in this category.'**
  String get noRankingsYet;

  /// Error message for bible book parsing
  ///
  /// In en, this message translates to:
  /// **'Could not determine book or chapter'**
  String get couldNotDetermineBook;

  /// Error when bible book not found in version
  ///
  /// In en, this message translates to:
  /// **'Book not found in current Bible version'**
  String get bookNotFoundInBibleVersion;

  /// Prompt to sign in to save bookmarks
  ///
  /// In en, this message translates to:
  /// **'Sign in and join a church to save bookmarks'**
  String get signInAndJoinToBookmarks;

  /// Message when bookmark is removed
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmarkRemoved;

  /// Message when item is bookmarked
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get bookmarked;

  /// Error when church not selected
  ///
  /// In en, this message translates to:
  /// **'Please select your church first!'**
  String get pleaseSelectChurchFirst;

  /// Error when request fails to send
  ///
  /// In en, this message translates to:
  /// **'Could not send request'**
  String get couldNotSendRequest;

  /// Thank-you message shown after sending a request
  ///
  /// In en, this message translates to:
  /// **'Thank you, {name}!'**
  String thankYouPastor(Object name);

  /// Title for create church screen
  ///
  /// In en, this message translates to:
  /// **'Create Your Church'**
  String get createYourChurch;

  /// Validation message for form
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get pleaseFillAllRequiredFields;

  /// Warning message before leaving church
  ///
  /// In en, this message translates to:
  /// **'You will no longer be connected to this church.'**
  String get leaveChurchMessage;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Error message for access denied
  ///
  /// In en, this message translates to:
  /// **'Access Restricted'**
  String get accessRestricted;

  /// Button label for church settings
  ///
  /// In en, this message translates to:
  /// **'Manage Church Settings'**
  String get manageChurchSettings;

  /// Help text for getting church code
  ///
  /// In en, this message translates to:
  /// **'Ask your pastor for the code'**
  String get askYourPastor;

  /// Section title for primary colors
  ///
  /// In en, this message translates to:
  /// **'Primary Colors'**
  String get primaryColors;

  /// Section title for secondary colors
  ///
  /// In en, this message translates to:
  /// **'Secondary Colors'**
  String get secondaryColors;

  /// Section title for neutral colors
  ///
  /// In en, this message translates to:
  /// **'Neutral & Background'**
  String get neutralAndBackground;

  /// Section title for status colors
  ///
  /// In en, this message translates to:
  /// **'Status Colors'**
  String get statusColors;

  /// Section title for grey scale colors
  ///
  /// In en, this message translates to:
  /// **'Grey Scale'**
  String get greyScale;

  /// Section title for dark theme colors
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// Members stat card title
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// Lesson completion stat card title
  ///
  /// In en, this message translates to:
  /// **'Lesson Completion'**
  String get lessonCompletion;

  /// Daily active users stat card title
  ///
  /// In en, this message translates to:
  /// **'Daily Active'**
  String get dailyActive;

  /// Weekly active users stat card title
  ///
  /// In en, this message translates to:
  /// **'Weekly Active'**
  String get weeklyActive;

  /// Activity chart title
  ///
  /// In en, this message translates to:
  /// **'Activity (Last 7 Days)'**
  String get activity;

  /// Lesson progress chart title
  ///
  /// In en, this message translates to:
  /// **'Lesson Progress'**
  String get lessonProgress;

  /// Alerts section title
  ///
  /// In en, this message translates to:
  /// **'Alerts & Highlights'**
  String get alertsAndHighlights;

  /// Message after scheduling test notification
  ///
  /// In en, this message translates to:
  /// **'Test notification scheduled in 30 seconds!'**
  String get testNotificationScheduled;

  /// Message about notification timing permission
  ///
  /// In en, this message translates to:
  /// **'Exact timing denied. Reminder will be approximate.'**
  String get exactTimingDenied;

  /// Button to add item
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @yoruba.
  ///
  /// In en, this message translates to:
  /// **'Yoruba'**
  String get yoruba;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navBible.
  ///
  /// In en, this message translates to:
  /// **'Bible'**
  String get navBible;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @pleaseLogInToViewStreak.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view your streak.'**
  String get pleaseLogInToViewStreak;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode • Using cached lessons'**
  String get offlineMode;

  /// No description provided for @newLesson.
  ///
  /// In en, this message translates to:
  /// **'New Lesson!'**
  String get newLesson;

  /// No description provided for @openButton.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get openButton;

  /// No description provided for @leaveButton.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveButton;

  /// No description provided for @leaveChurchDialog.
  ///
  /// In en, this message translates to:
  /// **'Leave Church?'**
  String get leaveChurchDialog;

  /// No description provided for @oldTestament.
  ///
  /// In en, this message translates to:
  /// **'Old Testament'**
  String get oldTestament;

  /// No description provided for @newTestament.
  ///
  /// In en, this message translates to:
  /// **'New Testament'**
  String get newTestament;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available!'**
  String get updateAvailable;

  /// No description provided for @updateMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version is ready with improvements and fixes.\nDownload it now?'**
  String get updateMessage;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @invalidSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit code'**
  String get invalidSixDigitCode;

  /// No description provided for @invalidServerResponse.
  ///
  /// In en, this message translates to:
  /// **'Invalid server response'**
  String get invalidServerResponse;

  /// No description provided for @failedToJoinChurch.
  ///
  /// In en, this message translates to:
  /// **'Failed to join church'**
  String get failedToJoinChurch;

  /// No description provided for @signOutWarning.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be signed out and returned to the login screen.'**
  String get signOutWarning;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @connectToChurch.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get you connected to your church'**
  String get connectToChurch;

  /// No description provided for @joinParish.
  ///
  /// In en, this message translates to:
  /// **'Join Parish'**
  String get joinParish;

  /// No description provided for @enterChurchCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Church Code'**
  String get enterChurchCode;

  /// No description provided for @askPastorForCode.
  ///
  /// In en, this message translates to:
  /// **'Ask your pastor for the code'**
  String get askPastorForCode;

  /// No description provided for @mustBeSignedIn.
  ///
  /// In en, this message translates to:
  /// **'You must be signed in'**
  String get mustBeSignedIn;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request Sent!'**
  String get requestSent;

  /// Summary shown after a church creation request is sent
  ///
  /// In en, this message translates to:
  /// **'Your request to create:\n\n🏛️ {churchName}\n📍 {parishName}\n🌍 {country}\n\nhas been sent.'**
  String requestSummary(Object churchName, Object parishName, Object country);

  /// No description provided for @approvalNotice.
  ///
  /// In en, this message translates to:
  /// **'You will receive a notification within 24 hours when approved.'**
  String get approvalNotice;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get gotIt;

  /// No description provided for @churchAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A church with this name already exists. Please contact support.'**
  String get churchAlreadyExists;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Error: {toString}'**
  String genericError(Object toString);

  /// No description provided for @churchInformation.
  ///
  /// In en, this message translates to:
  /// **'Church Information'**
  String get churchInformation;

  /// No description provided for @parishName.
  ///
  /// In en, this message translates to:
  /// **'Parish / Branch Name *'**
  String get parishName;

  /// No description provided for @adminEmail.
  ///
  /// In en, this message translates to:
  /// **'Admin Email *'**
  String get adminEmail;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptional;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country *'**
  String get country;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @bibleGenesis.
  ///
  /// In en, this message translates to:
  /// **'Genesis'**
  String get bibleGenesis;

  /// No description provided for @bibleExodus.
  ///
  /// In en, this message translates to:
  /// **'Exodus'**
  String get bibleExodus;

  /// No description provided for @bibleLeviticus.
  ///
  /// In en, this message translates to:
  /// **'Leviticus'**
  String get bibleLeviticus;

  /// No description provided for @bibleNumbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get bibleNumbers;

  /// No description provided for @bibleDeuteronomy.
  ///
  /// In en, this message translates to:
  /// **'Deuteronomy'**
  String get bibleDeuteronomy;

  /// No description provided for @bibleJoshua.
  ///
  /// In en, this message translates to:
  /// **'Joshua'**
  String get bibleJoshua;

  /// No description provided for @bibleJudges.
  ///
  /// In en, this message translates to:
  /// **'Judges'**
  String get bibleJudges;

  /// No description provided for @bibleRuth.
  ///
  /// In en, this message translates to:
  /// **'Ruth'**
  String get bibleRuth;

  /// No description provided for @bible1Samuel.
  ///
  /// In en, this message translates to:
  /// **'1 Samuel'**
  String get bible1Samuel;

  /// No description provided for @bible2Samuel.
  ///
  /// In en, this message translates to:
  /// **'2 Samuel'**
  String get bible2Samuel;

  /// No description provided for @bible1Kings.
  ///
  /// In en, this message translates to:
  /// **'1 Kings'**
  String get bible1Kings;

  /// No description provided for @bible2Kings.
  ///
  /// In en, this message translates to:
  /// **'2 Kings'**
  String get bible2Kings;

  /// No description provided for @bible1Chronicles.
  ///
  /// In en, this message translates to:
  /// **'1 Chronicles'**
  String get bible1Chronicles;

  /// No description provided for @bible2Chronicles.
  ///
  /// In en, this message translates to:
  /// **'2 Chronicles'**
  String get bible2Chronicles;

  /// No description provided for @bibleEzra.
  ///
  /// In en, this message translates to:
  /// **'Ezra'**
  String get bibleEzra;

  /// No description provided for @bibleNehemiah.
  ///
  /// In en, this message translates to:
  /// **'Nehemiah'**
  String get bibleNehemiah;

  /// No description provided for @bibleEsther.
  ///
  /// In en, this message translates to:
  /// **'Esther'**
  String get bibleEsther;

  /// No description provided for @bibleJob.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get bibleJob;

  /// No description provided for @biblePsalms.
  ///
  /// In en, this message translates to:
  /// **'Psalms'**
  String get biblePsalms;

  /// No description provided for @bibleProverbs.
  ///
  /// In en, this message translates to:
  /// **'Proverbs'**
  String get bibleProverbs;

  /// No description provided for @bibleEcclesiastes.
  ///
  /// In en, this message translates to:
  /// **'Ecclesiastes'**
  String get bibleEcclesiastes;

  /// No description provided for @bibleSongOfSolomon.
  ///
  /// In en, this message translates to:
  /// **'Song of Solomon'**
  String get bibleSongOfSolomon;

  /// No description provided for @bibleIsaiah.
  ///
  /// In en, this message translates to:
  /// **'Isaiah'**
  String get bibleIsaiah;

  /// No description provided for @bibleJeremiah.
  ///
  /// In en, this message translates to:
  /// **'Jeremiah'**
  String get bibleJeremiah;

  /// No description provided for @bibleLamentations.
  ///
  /// In en, this message translates to:
  /// **'Lamentations'**
  String get bibleLamentations;

  /// No description provided for @bibleEzekiel.
  ///
  /// In en, this message translates to:
  /// **'Ezekiel'**
  String get bibleEzekiel;

  /// No description provided for @bibleDaniel.
  ///
  /// In en, this message translates to:
  /// **'Daniel'**
  String get bibleDaniel;

  /// No description provided for @bibleHosea.
  ///
  /// In en, this message translates to:
  /// **'Hosea'**
  String get bibleHosea;

  /// No description provided for @bibleJoel.
  ///
  /// In en, this message translates to:
  /// **'Joel'**
  String get bibleJoel;

  /// No description provided for @bibleAmos.
  ///
  /// In en, this message translates to:
  /// **'Amos'**
  String get bibleAmos;

  /// No description provided for @bibleObadiah.
  ///
  /// In en, this message translates to:
  /// **'Obadiah'**
  String get bibleObadiah;

  /// No description provided for @bibleJonah.
  ///
  /// In en, this message translates to:
  /// **'Jonah'**
  String get bibleJonah;

  /// No description provided for @bibleMicah.
  ///
  /// In en, this message translates to:
  /// **'Micah'**
  String get bibleMicah;

  /// No description provided for @bibleNahum.
  ///
  /// In en, this message translates to:
  /// **'Nahum'**
  String get bibleNahum;

  /// No description provided for @bibleHabakkuk.
  ///
  /// In en, this message translates to:
  /// **'Habakkuk'**
  String get bibleHabakkuk;

  /// No description provided for @bibleZephaniah.
  ///
  /// In en, this message translates to:
  /// **'Zephaniah'**
  String get bibleZephaniah;

  /// No description provided for @bibleHaggai.
  ///
  /// In en, this message translates to:
  /// **'Haggai'**
  String get bibleHaggai;

  /// No description provided for @bibleZechariah.
  ///
  /// In en, this message translates to:
  /// **'Zechariah'**
  String get bibleZechariah;

  /// No description provided for @bibleMalachi.
  ///
  /// In en, this message translates to:
  /// **'Malachi'**
  String get bibleMalachi;

  /// No description provided for @bibleMatthew.
  ///
  /// In en, this message translates to:
  /// **'Matthew'**
  String get bibleMatthew;

  /// No description provided for @bibleMark.
  ///
  /// In en, this message translates to:
  /// **'Mark'**
  String get bibleMark;

  /// No description provided for @bibleLuke.
  ///
  /// In en, this message translates to:
  /// **'Luke'**
  String get bibleLuke;

  /// No description provided for @bibleJohn.
  ///
  /// In en, this message translates to:
  /// **'John'**
  String get bibleJohn;

  /// No description provided for @bibleActs.
  ///
  /// In en, this message translates to:
  /// **'Acts'**
  String get bibleActs;

  /// No description provided for @bibleRomans.
  ///
  /// In en, this message translates to:
  /// **'Romans'**
  String get bibleRomans;

  /// No description provided for @bible1Corinthians.
  ///
  /// In en, this message translates to:
  /// **'1 Corinthians'**
  String get bible1Corinthians;

  /// No description provided for @bible2Corinthians.
  ///
  /// In en, this message translates to:
  /// **'2 Corinthians'**
  String get bible2Corinthians;

  /// No description provided for @bibleGalatians.
  ///
  /// In en, this message translates to:
  /// **'Galatians'**
  String get bibleGalatians;

  /// No description provided for @bibleEphesians.
  ///
  /// In en, this message translates to:
  /// **'Ephesians'**
  String get bibleEphesians;

  /// No description provided for @biblePhilippians.
  ///
  /// In en, this message translates to:
  /// **'Philippians'**
  String get biblePhilippians;

  /// No description provided for @bibleColossians.
  ///
  /// In en, this message translates to:
  /// **'Colossians'**
  String get bibleColossians;

  /// No description provided for @bible1Thessalonians.
  ///
  /// In en, this message translates to:
  /// **'1 Thessalonians'**
  String get bible1Thessalonians;

  /// No description provided for @bible2Thessalonians.
  ///
  /// In en, this message translates to:
  /// **'2 Thessalonians'**
  String get bible2Thessalonians;

  /// No description provided for @bible1Timothy.
  ///
  /// In en, this message translates to:
  /// **'1 Timothy'**
  String get bible1Timothy;

  /// No description provided for @bible2Timothy.
  ///
  /// In en, this message translates to:
  /// **'2 Timothy'**
  String get bible2Timothy;

  /// No description provided for @bibleTitus.
  ///
  /// In en, this message translates to:
  /// **'Titus'**
  String get bibleTitus;

  /// No description provided for @biblePhilemon.
  ///
  /// In en, this message translates to:
  /// **'Philemon'**
  String get biblePhilemon;

  /// No description provided for @bibleHebrews.
  ///
  /// In en, this message translates to:
  /// **'Hebrews'**
  String get bibleHebrews;

  /// No description provided for @bibleJames.
  ///
  /// In en, this message translates to:
  /// **'James'**
  String get bibleJames;

  /// No description provided for @bible1Peter.
  ///
  /// In en, this message translates to:
  /// **'1 Peter'**
  String get bible1Peter;

  /// No description provided for @bible2Peter.
  ///
  /// In en, this message translates to:
  /// **'2 Peter'**
  String get bible2Peter;

  /// No description provided for @bible1John.
  ///
  /// In en, this message translates to:
  /// **'1 John'**
  String get bible1John;

  /// No description provided for @bible2John.
  ///
  /// In en, this message translates to:
  /// **'2 John'**
  String get bible2John;

  /// No description provided for @bible3John.
  ///
  /// In en, this message translates to:
  /// **'3 John'**
  String get bible3John;

  /// No description provided for @bibleJude.
  ///
  /// In en, this message translates to:
  /// **'Jude'**
  String get bibleJude;

  /// No description provided for @bibleRevelation.
  ///
  /// In en, this message translates to:
  /// **'Revelation'**
  String get bibleRevelation;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// No description provided for @removeHighlight.
  ///
  /// In en, this message translates to:
  /// **'Remove highlight'**
  String get removeHighlight;

  /// No description provided for @verseSelected.
  ///
  /// In en, this message translates to:
  /// **'verse selected'**
  String get verseSelected;

  /// No description provided for @versesSelected.
  ///
  /// In en, this message translates to:
  /// **'verses selected'**
  String get versesSelected;

  /// No description provided for @advertsDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Adverts fund the app and server maintenance, for your pleasure.'**
  String get advertsDisclosure;

  /// No description provided for @inviteYourFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Your Friends'**
  String get inviteYourFriends;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @pleaseAddComment.
  ///
  /// In en, this message translates to:
  /// **'Please add a comment'**
  String get pleaseAddComment;

  /// No description provided for @feedbackSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Feedback submitted.'**
  String get feedbackSubmitted;

  /// No description provided for @yourSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Your Suggestions'**
  String get yourSuggestions;

  /// No description provided for @suggestionsHelpApp.
  ///
  /// In en, this message translates to:
  /// **'Your suggestions make the app better for all!'**
  String get suggestionsHelpApp;

  /// No description provided for @tellUsWhatYouThink.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you think...'**
  String get tellUsWhatYouThink;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get submitFeedback;

  /// No description provided for @rateAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Hii... To rate the app, please go to Settings ...'**
  String get rateAppSettings;

  /// No description provided for @pleaseSignInStreak.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view your streak.'**
  String get pleaseSignInStreak;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'day streak'**
  String get dayStreak;

  /// No description provided for @freezesAvailable.
  ///
  /// In en, this message translates to:
  /// **'Freezes available'**
  String get freezesAvailable;

  /// No description provided for @freezesDescription.
  ///
  /// In en, this message translates to:
  /// **'Freezes let you skip a day without breaking your streak.'**
  String get freezesDescription;

  /// No description provided for @lastCompleted.
  ///
  /// In en, this message translates to:
  /// **'Last Completed'**
  String get lastCompleted;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @progressNextFreeze.
  ///
  /// In en, this message translates to:
  /// **'Progress to next freeze'**
  String get progressNextFreeze;

  /// No description provided for @daysUntilNextFreeze.
  ///
  /// In en, this message translates to:
  /// **'day(s) until next freeze.'**
  String get daysUntilNextFreeze;

  /// No description provided for @howFreezesWork.
  ///
  /// In en, this message translates to:
  /// **'How freezes work'**
  String get howFreezesWork;

  /// No description provided for @freezeExplanation.
  ///
  /// In en, this message translates to:
  /// **'If you miss a day, a freeze will be consumed to keep your streak.'**
  String get freezeExplanation;

  /// No description provided for @savedItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Items'**
  String get savedItemsTitle;

  /// No description provided for @noBookmarksYetMessage.
  ///
  /// In en, this message translates to:
  /// **'No Bookmarks Yet'**
  String get noBookmarksYetMessage;

  /// No description provided for @saveFavoriteScriptures.
  ///
  /// In en, this message translates to:
  /// **'Save your favorite scriptures to read them anytime.'**
  String get saveFavoriteScriptures;

  /// No description provided for @deleteBookmark.
  ///
  /// In en, this message translates to:
  /// **'Delete bookmark'**
  String get deleteBookmark;

  /// No description provided for @yourNote.
  ///
  /// In en, this message translates to:
  /// **'Your Note'**
  String get yourNote;

  /// No description provided for @noSavedLessons.
  ///
  /// In en, this message translates to:
  /// **'No Saved Lessons'**
  String get noSavedLessons;

  /// No description provided for @saveLessonsToReview.
  ///
  /// In en, this message translates to:
  /// **'Save lessons to review them later.'**
  String get saveLessonsToReview;

  /// No description provided for @openLesson.
  ///
  /// In en, this message translates to:
  /// **'Open lesson'**
  String get openLesson;

  /// No description provided for @deleteLesson.
  ///
  /// In en, this message translates to:
  /// **'Delete lesson'**
  String get deleteLesson;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @noFurtherReadings.
  ///
  /// In en, this message translates to:
  /// **'No Further Readings'**
  String get noFurtherReadings;

  /// No description provided for @saveReadingMaterials.
  ///
  /// In en, this message translates to:
  /// **'Save reading materials to explore them later.'**
  String get saveReadingMaterials;

  /// No description provided for @deleteReading.
  ///
  /// In en, this message translates to:
  /// **'Delete reading'**
  String get deleteReading;

  /// No description provided for @lessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessons;

  /// No description provided for @readings.
  ///
  /// In en, this message translates to:
  /// **'Readings'**
  String get readings;

  /// No description provided for @adult.
  ///
  /// In en, this message translates to:
  /// **'Adult'**
  String get adult;

  /// No description provided for @teen.
  ///
  /// In en, this message translates to:
  /// **'Teen'**
  String get teen;

  /// No description provided for @church.
  ///
  /// In en, this message translates to:
  /// **'Church'**
  String get church;

  /// No description provided for @global.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get global;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get errorWithMessage;

  /// No description provided for @yourRank.
  ///
  /// In en, this message translates to:
  /// **'Your Rank:'**
  String get yourRank;

  /// No description provided for @anonymousStudent.
  ///
  /// In en, this message translates to:
  /// **'Anonymous Student'**
  String get anonymousStudent;

  /// No description provided for @pointsLabel.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get pointsLabel;

  /// No description provided for @refreshAssignments.
  ///
  /// In en, this message translates to:
  /// **'Refresh assignments'**
  String get refreshAssignments;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty!'**
  String get empty;

  /// No description provided for @noAssignmentsInQuarter.
  ///
  /// In en, this message translates to:
  /// **'No assignments in this quarter.'**
  String get noAssignmentsInQuarter;

  /// Title for my assignments page
  ///
  /// In en, this message translates to:
  /// **'My Assignments'**
  String get myAssignments;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr', 'yo'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
    case 'yo': return AppLocalizationsYo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
