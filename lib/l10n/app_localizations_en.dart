// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sunday School Lessons';

  @override
  String get language => 'Language';

  @override
  String get sundaySchoolLesson => 'Sunday School Lesson';

  @override
  String get noLessonToday => 'No Lesson Available Today';

  @override
  String get noTeenLesson => 'No Teen Lesson available';

  @override
  String get noAdultLesson => 'No Adult Lesson available';

  @override
  String get sundaySchoolManual => 'Sunday School Manual';

  @override
  String get accessWeeklyLessonsOffline => 'Access your weekly Teen and Adult Bible study lessons anytime, anywhere — even offline!';

  @override
  String get builtForRccg => 'Built for the Redeemed Christian Church of God!';

  @override
  String get getStarted => 'Get Started';

  @override
  String get openFullChapter => 'Open full chapter →';

  @override
  String get close => 'Close';

  @override
  String get preparing => 'Preparing...';

  @override
  String preparingWithProgress(Object progress, Object totalSteps) {
    return 'Preparing... ($progress/$totalSteps)';
  }

  @override
  String get login => 'Login';

  @override
  String get signInToCreateOrJoin => 'Sign in to create or join your church';

  @override
  String get google => 'Google';

  @override
  String get apple => 'Apple';

  @override
  String get guest => 'Guest';

  @override
  String get signInFailed => 'Sign-in failed';

  @override
  String get applSignInFailed => 'Apple sign-in failed';

  @override
  String get guestModeFailed => 'Guest mode failed';

  @override
  String get guestUser => 'Guest User';

  @override
  String get guestMode => 'guest mode';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get guestDataWarning => 'All data are temporarily saved and lost after logout.';

  @override
  String get fullAccessDescription => 'Full access: create or join your church';

  @override
  String get limitedAccessDescription => 'Limited access: use general mode only';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get streaks => 'Streaks';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get assignments => 'Assignments';

  @override
  String get teachers => 'Teachers';

  @override
  String get appSuggestions => 'App Suggestions';

  @override
  String get adminTools => 'Admin Tools';

  @override
  String get colorPalette => 'Color Palette';

  @override
  String get parish => 'Parish';

  @override
  String get joinCode => 'Join Code';

  @override
  String get pastor => 'Pastor';

  @override
  String get notAvailable => 'Not available';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String deletionScheduledOn(Object date) {
    return 'Account scheduled for permanent deletion on:\n$date';
  }

  @override
  String get logInToCancel => 'Log in before this date to cancel deletion and restore your account.';

  @override
  String get permanentDeletionWarning => 'Your account and all data will be permanently deleted after 30 days.\nYou can cancel anytime by logging back in.';

  @override
  String get deleteAccountDialogTitle => 'Delete Account?';

  @override
  String get deleteAccountDialogContent => '• Your account will be permanently deleted in 30 days.\n• All your data (bookmarks, streaks, assignments, leaderboard) will be gone.\n• You can cancel this anytime by simply logging back in.\n\nAre you sure?';

  @override
  String get cancelDeletion => 'Cancel Deletion';

  @override
  String get deleteIn30Days => 'Delete in 30 Days';

  @override
  String get deletionScheduledButton => 'Deletion Scheduled';

  @override
  String get accountDeletionScheduledSnack => 'Account scheduled for deletion in 30 days. Log in to cancel.';

  @override
  String get deletionCancelledSnack => 'Account deletion cancelled! Welcome back 🎉';

  @override
  String get feedback => 'Feedback';

  @override
  String get rateAppOnGooglePlay => 'Rate App on Google Play';

  @override
  String get suggestAFeature => 'Suggest a Feature';

  @override
  String get preferences => 'Preferences';

  @override
  String get signIn => 'Sign In';

  @override
  String get register => 'Register';

  @override
  String get join => 'Join';

  @override
  String get registerParish => 'Register a Parish';

  @override
  String get createChurch => 'Create Church';

  @override
  String get joinChurch => 'Join Church';

  @override
  String get selectChurch => 'Select a Church';

  @override
  String get churchAccessCode => 'Church Access Code';

  @override
  String get churchName => 'Church Name';

  @override
  String get pastorName => 'Pastor Name';

  @override
  String get leaveChurch => 'Leave Church';

  @override
  String get selectYourChurch => 'Select your church';

  @override
  String get noChurchSelected => 'No Church Selected';

  @override
  String get joinedSuccessfully => 'Joined successfully!';

  @override
  String get shareAsLessonPdf => 'Share as PDF';

  @override
  String get shareLink => 'Share Link';

  @override
  String get saveLessonPrompt => 'Sign in and join a church to save lessons';

  @override
  String get lessonRemovedFromSaved => 'Lesson removed from saved';

  @override
  String get lessonSaved => 'Lesson saved! 📚';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get removedFromSavedLessons => 'Remove from saved lessons';

  @override
  String get saveThisLesson => 'Save this lesson';

  @override
  String get verseTemporarilyUnavailable => 'Verse temporarily unavailable';

  @override
  String get removedFromSavedReadings => 'Remove from saved readings';

  @override
  String get saveThisReading => 'Save this reading';

  @override
  String get pleaseSelectYourChurchFirst => 'Please select your church first!';

  @override
  String get pleaseEnterAtLeastOneAnswer => 'Please enter at least one answer to the question.';

  @override
  String get yourAnswersHaveBeenSubmitted => 'Your answers have been submitted successfully!';

  @override
  String get failedToSaveYourAnswers => 'Failed to save your answers. Please try again.';

  @override
  String get globalAdminsOnlyNoChurch => 'Global admins only — no church selected.';

  @override
  String get addAnotherResponse => 'Add another response';

  @override
  String get noSubmissionsYet => 'No submissions yet.';

  @override
  String get currentStatus => 'Current Status';

  @override
  String get submitted => 'Submitted';

  @override
  String get notSubmitted => 'Not Submitted';

  @override
  String get graded => 'Graded';

  @override
  String get viewFeedback => 'View Feedback';

  @override
  String get leaveFeedback => 'Leave Feedback';

  @override
  String get lessonTitle => 'Lesson Title';

  @override
  String get topic => 'Topic';

  @override
  String get biblePassage => 'BIBLE PASSAGE:';

  @override
  String get guestUserLabel => 'Guest User';

  @override
  String get loading => 'Loading';

  @override
  String get answerWeeklyAssignment => 'Answer Weekly Assignment';

  @override
  String get loginForAssignment => 'Login For Assignment';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get switchedToGeneral => 'Switched to General (Global) lessons';

  @override
  String get shareLesson => 'Share Lesson';

  @override
  String get readingStreak => 'Reading Streak';

  @override
  String get todaysReading => 'Today\'s Reading:';

  @override
  String get noReading => 'No Reading';

  @override
  String get completeReading => 'Complete Reading';

  @override
  String readingTimer(Object remainingSeconds) {
    return 'Time till streak… ($remainingSeconds s)';
  }

  @override
  String get memoryVerse => 'Memory verse:';

  @override
  String get prayer => 'Prayer';

  @override
  String get noBookmarksYet => 'No Bookmarks Yet';

  @override
  String get signInToSaveFavorites => 'Sign in to save your favorites';

  @override
  String get bookmarksSyncMessage => 'Bookmarks, lessons, and readings will sync across your devices.';

  @override
  String get english => 'English';

  @override
  String get francais => 'Français';

  @override
  String get copied => 'Copied!';

  @override
  String get invalidSavedLessonId => 'Invalid saved lesson id';

  @override
  String get lessonNotFound => 'Lesson not found';

  @override
  String get savedLessonContentNotAvailable => 'Saved lesson content not available';

  @override
  String get pleaseAddAComment => 'Please add a comment';

  @override
  String get thankYouFeedbackSubmitted => 'Thank you! Feedback submitted.';

  @override
  String errorSharingChurch(Object error) {
    return 'Error sharing church: $error';
  }

  @override
  String get youHaveLeftTheChurch => 'You have left the church';

  @override
  String get pleaseLogInToViewAssignments => 'Please log in to view your assignments';

  @override
  String get teenResponses => 'Teen Responses';

  @override
  String get adultResponses => 'Adult Responses';

  @override
  String get editResponses => 'Edit Responses';

  @override
  String yourScore(Object score, Object total) {
    return 'Your Score: $score / $total';
  }

  @override
  String get myResponses => 'My Responses:';

  @override
  String get yourSubmittedResponses => 'Your submitted responses';

  @override
  String get assignmentGraded => 'This assignment has been graded';

  @override
  String get gradedNoEdit => 'Graded — cannot edit';

  @override
  String get noQuestionAvailable => 'No question available.';

  @override
  String get noQuestionAvailableForThisDay => 'No question available for this day.';

  @override
  String get myAssignment => 'My Assignment';

  @override
  String get thisWeeksAssignment => 'This Week\'s Assignment';

  @override
  String dueDateFormatted(Object dateFormatted) {
    return 'Due: $dateFormatted';
  }

  @override
  String get gradedByTeacher => 'Graded by Teacher';

  @override
  String get teachersFeedback => 'Teacher\'s Feedback:';

  @override
  String get noTeacherFeedbackProvided => 'No teacher feedback provided.';

  @override
  String get submittedTapEditToChange => 'Submitted — tap Edit to change';

  @override
  String get writeYourResponseHere => 'Write your response here...';

  @override
  String get submit => 'Submit';

  @override
  String get loadingQuestion => 'Loading question...';

  @override
  String get teenOrAdultResponses => 'Responses';

  @override
  String get question => 'Question';

  @override
  String get submissions => 'Submissions';

  @override
  String answerWithIndex(Object i, Object answer) {
    return 'Answer $i: $answer';
  }

  @override
  String get reset => 'Reset';

  @override
  String get grade => 'Grade';

  @override
  String get teenSundaySchoolLesson => 'Teenager Sunday School Lesson';

  @override
  String get adultSundaySchoolLesson => 'Adult Sunday School Lesson';

  @override
  String get youWillBeSignedOut => 'You\'ll be signed out and returned to the login screen.';

  @override
  String get leaveWithoutJoining => 'Leave without joining?';

  @override
  String get setUpYourParish => 'Set up your parish and become its admin';

  @override
  String get enterSixDigitCode => 'Enter the 6-digit code provided by your parish admin';

  @override
  String copiedHex(Object hex) {
    return 'Copied: $hex';
  }

  @override
  String get rccgSundaySchoolGeneral => 'RCCG Sunday School (General)';

  @override
  String get savedItems => 'Saved Items';

  @override
  String errorLoadingData(Object error) {
    return 'Error: $error';
  }

  @override
  String get noRankingsYet => 'No rankings yet in this category.';

  @override
  String get couldNotDetermineBook => 'Could not determine book or chapter';

  @override
  String get bookNotFoundInBibleVersion => 'Book not found in current Bible version';

  @override
  String get signInAndJoinToBookmarks => 'Sign in and join a church to save bookmarks';

  @override
  String get bookmarkRemoved => 'Bookmark removed';

  @override
  String get bookmarked => 'Bookmarked';

  @override
  String get pleaseSelectChurchFirst => 'Please select your church first!';

  @override
  String get couldNotSendRequest => 'Could not send request';

  @override
  String thankYouPastor(Object name) {
    return 'Thank you, $name!';
  }

  @override
  String get createYourChurch => 'Create Your Church';

  @override
  String get pleaseFillAllRequiredFields => 'Please fill all required fields';

  @override
  String get leaveChurchMessage => 'You will no longer be connected to this church.';

  @override
  String get cancel => 'Cancel';

  @override
  String get accessRestricted => 'Access Restricted';

  @override
  String get manageChurchSettings => 'Manage Church Settings';

  @override
  String get askYourPastor => 'Ask your pastor for the code';

  @override
  String get primaryColors => 'Primary Colors';

  @override
  String get secondaryColors => 'Secondary Colors';

  @override
  String get neutralAndBackground => 'Neutral & Background';

  @override
  String get statusColors => 'Status Colors';

  @override
  String get greyScale => 'Grey Scale';

  @override
  String get darkTheme => 'Dark Theme';

  @override
  String get members => 'Members';

  @override
  String get lessonCompletion => 'Lesson Completion';

  @override
  String get dailyActive => 'Daily Active';

  @override
  String get weeklyActive => 'Weekly Active';

  @override
  String get activity => 'Activity (Last 7 Days)';

  @override
  String get lessonProgress => 'Lesson Progress';

  @override
  String get alertsAndHighlights => 'Alerts & Highlights';

  @override
  String get testNotificationScheduled => 'Test notification scheduled in 30 seconds!';

  @override
  String get exactTimingDenied => 'Exact timing denied. Reminder will be approximate.';

  @override
  String get addItem => 'Add item';

  @override
  String get yoruba => 'Yoruba';

  @override
  String get navHome => 'Home';

  @override
  String get navBible => 'Bible';

  @override
  String get navAccount => 'Account';

  @override
  String get pleaseLogInToViewStreak => 'Please sign in to view your streak.';

  @override
  String get offlineMode => 'Offline Mode • Using cached lessons';

  @override
  String get newLesson => 'New Lesson!';

  @override
  String get openButton => 'OPEN';

  @override
  String get leaveButton => 'Leave';

  @override
  String get leaveChurchDialog => 'Leave Church?';

  @override
  String get oldTestament => 'Old Testament';

  @override
  String get newTestament => 'New Testament';

  @override
  String get updateAvailable => 'Update Available!';

  @override
  String get updateMessage => 'A new version is ready with improvements and fixes.\nDownload it now?';

  @override
  String get later => 'Later';

  @override
  String get updateNow => 'Update Now';

  @override
  String get invalidSixDigitCode => 'Please enter a valid 6-digit code';

  @override
  String get invalidServerResponse => 'Invalid server response';

  @override
  String get failedToJoinChurch => 'Failed to join church';

  @override
  String get signOutWarning => 'You\'ll be signed out and returned to the login screen.';

  @override
  String get stay => 'Stay';

  @override
  String get welcome => 'Welcome!';

  @override
  String get connectToChurch => 'Let\'s get you connected to your church';

  @override
  String get joinParish => 'Join Parish';

  @override
  String get enterChurchCode => 'Enter Church Code';

  @override
  String get askPastorForCode => 'Ask your pastor for the code';

  @override
  String get mustBeSignedIn => 'You must be signed in';

  @override
  String get requestSent => 'Request Sent!';

  @override
  String requestSummary(Object churchName, Object parishName, Object country) {
    return 'Your request to create:\n\n🏛️ $churchName\n📍 $parishName\n🌍 $country\n\nhas been sent.';
  }

  @override
  String get approvalNotice => 'You will receive a notification within 24 hours when approved.';

  @override
  String get gotIt => 'Got it!';

  @override
  String get churchAlreadyExists => 'A church with this name already exists. Please contact support.';

  @override
  String genericError(Object toString) {
    return 'Error: $toString';
  }

  @override
  String get churchInformation => 'Church Information';

  @override
  String get parishName => 'Parish / Branch Name *';

  @override
  String get adminEmail => 'Admin Email *';

  @override
  String get addressOptional => 'Address (optional)';

  @override
  String get country => 'Country *';

  @override
  String get submitRequest => 'Submit Request';

  @override
  String get bibleGenesis => 'Genesis';

  @override
  String get bibleExodus => 'Exodus';

  @override
  String get bibleLeviticus => 'Leviticus';

  @override
  String get bibleNumbers => 'Numbers';

  @override
  String get bibleDeuteronomy => 'Deuteronomy';

  @override
  String get bibleJoshua => 'Joshua';

  @override
  String get bibleJudges => 'Judges';

  @override
  String get bibleRuth => 'Ruth';

  @override
  String get bible1Samuel => '1 Samuel';

  @override
  String get bible2Samuel => '2 Samuel';

  @override
  String get bible1Kings => '1 Kings';

  @override
  String get bible2Kings => '2 Kings';

  @override
  String get bible1Chronicles => '1 Chronicles';

  @override
  String get bible2Chronicles => '2 Chronicles';

  @override
  String get bibleEzra => 'Ezra';

  @override
  String get bibleNehemiah => 'Nehemiah';

  @override
  String get bibleEsther => 'Esther';

  @override
  String get bibleJob => 'Job';

  @override
  String get biblePsalms => 'Psalms';

  @override
  String get bibleProverbs => 'Proverbs';

  @override
  String get bibleEcclesiastes => 'Ecclesiastes';

  @override
  String get bibleSongOfSolomon => 'Song of Solomon';

  @override
  String get bibleIsaiah => 'Isaiah';

  @override
  String get bibleJeremiah => 'Jeremiah';

  @override
  String get bibleLamentations => 'Lamentations';

  @override
  String get bibleEzekiel => 'Ezekiel';

  @override
  String get bibleDaniel => 'Daniel';

  @override
  String get bibleHosea => 'Hosea';

  @override
  String get bibleJoel => 'Joel';

  @override
  String get bibleAmos => 'Amos';

  @override
  String get bibleObadiah => 'Obadiah';

  @override
  String get bibleJonah => 'Jonah';

  @override
  String get bibleMicah => 'Micah';

  @override
  String get bibleNahum => 'Nahum';

  @override
  String get bibleHabakkuk => 'Habakkuk';

  @override
  String get bibleZephaniah => 'Zephaniah';

  @override
  String get bibleHaggai => 'Haggai';

  @override
  String get bibleZechariah => 'Zechariah';

  @override
  String get bibleMalachi => 'Malachi';

  @override
  String get bibleMatthew => 'Matthew';

  @override
  String get bibleMark => 'Mark';

  @override
  String get bibleLuke => 'Luke';

  @override
  String get bibleJohn => 'John';

  @override
  String get bibleActs => 'Acts';

  @override
  String get bibleRomans => 'Romans';

  @override
  String get bible1Corinthians => '1 Corinthians';

  @override
  String get bible2Corinthians => '2 Corinthians';

  @override
  String get bibleGalatians => 'Galatians';

  @override
  String get bibleEphesians => 'Ephesians';

  @override
  String get biblePhilippians => 'Philippians';

  @override
  String get bibleColossians => 'Colossians';

  @override
  String get bible1Thessalonians => '1 Thessalonians';

  @override
  String get bible2Thessalonians => '2 Thessalonians';

  @override
  String get bible1Timothy => '1 Timothy';

  @override
  String get bible2Timothy => '2 Timothy';

  @override
  String get bibleTitus => 'Titus';

  @override
  String get biblePhilemon => 'Philemon';

  @override
  String get bibleHebrews => 'Hebrews';

  @override
  String get bibleJames => 'James';

  @override
  String get bible1Peter => '1 Peter';

  @override
  String get bible2Peter => '2 Peter';

  @override
  String get bible1John => '1 John';

  @override
  String get bible2John => '2 John';

  @override
  String get bible3John => '3 John';

  @override
  String get bibleJude => 'Jude';

  @override
  String get bibleRevelation => 'Revelation';

  @override
  String get copy => 'Copy';

  @override
  String get share => 'Share';

  @override
  String get bookmark => 'Bookmark';

  @override
  String get removeHighlight => 'Remove highlight';

  @override
  String get verseSelected => 'verse selected';

  @override
  String get versesSelected => 'verses selected';

  @override
  String get advertsDisclosure => 'Adverts fund the app and server maintenance, for your pleasure.';

  @override
  String get inviteYourFriends => 'Invite Your Friends';

  @override
  String get signOut => 'Sign Out';

  @override
  String get pleaseAddComment => 'Please add a comment';

  @override
  String get feedbackSubmitted => 'Thank you! Feedback submitted.';

  @override
  String get yourSuggestions => 'Your Suggestions';

  @override
  String get suggestionsHelpApp => 'Your suggestions make the app better for all!';

  @override
  String get tellUsWhatYouThink => 'Tell us what you think...';

  @override
  String get submitFeedback => 'Submit Feedback';

  @override
  String get rateAppSettings => 'Hii... To rate the app, please go to Settings ...';

  @override
  String get pleaseSignInStreak => 'Please sign in to view your streak.';

  @override
  String get dayStreak => 'day streak';

  @override
  String get freezesAvailable => 'Freezes available';

  @override
  String get freezesDescription => 'Freezes let you skip a day without breaking your streak.';

  @override
  String get lastCompleted => 'Last Completed';

  @override
  String get never => 'Never';

  @override
  String get progressNextFreeze => 'Progress to next freeze';

  @override
  String get daysUntilNextFreeze => 'day(s) until next freeze (every 7-day streak awards 1 freeze)';

  @override
  String get howFreezesWork => 'How freezes work';

  @override
  String get freezeExplanation => 'If you miss a day, a freeze will be consumed to keep your streak.';

  @override
  String get savedItemsTitle => 'Saved Items';

  @override
  String get noBookmarksYetMessage => 'No Bookmarks Yet';

  @override
  String get saveFavoriteScriptures => 'Save your favorite scriptures to read them anytime.';

  @override
  String get deleteBookmark => 'Delete bookmark';

  @override
  String get yourNote => 'Your Note';

  @override
  String get noSavedLessons => 'No Saved Lessons';

  @override
  String get saveLessonsToReview => 'Save lessons to review them later.';

  @override
  String get openLesson => 'Open lesson';

  @override
  String get deleteLesson => 'Delete lesson';

  @override
  String get noteLabel => 'Note';

  @override
  String get noFurtherReadings => 'No Further Readings';

  @override
  String get saveReadingMaterials => 'Save reading materials to explore them later.';

  @override
  String get deleteReading => 'Delete reading';

  @override
  String get lessons => 'Lessons';

  @override
  String get readings => 'Readings';

  @override
  String get adult => 'Adult';

  @override
  String get teen => 'Teen';

  @override
  String get church => 'Church';

  @override
  String get global => 'Global';

  @override
  String get errorWithMessage => 'Error:';

  @override
  String get yourRank => 'Your Rank:';

  @override
  String get anonymousStudent => 'Anonymous Student';

  @override
  String get pointsLabel => 'pts';

  @override
  String get refreshAssignments => 'Refresh assignments';

  @override
  String get empty => 'Empty!';

  @override
  String get noAssignmentsInQuarter => 'No assignments in this quarter.';

  @override
  String get myAssignments => 'My Assignments';
}
