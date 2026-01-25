// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Yoruba (`yo`).
class AppLocalizationsYo extends AppLocalizations {
  AppLocalizationsYo([String locale = 'yo']) : super(locale);

  @override
  String get appName => 'Ẹ̀kọ́ Sunday School';

  @override
  String get language => 'Ede';

  @override
  String get sundaySchoolLesson => 'Ẹ̀kọ́ Sunday School';

  @override
  String get noLessonToday => 'Kò sí ẹ̀kọ́ lónìí';

  @override
  String get noTeenLesson => 'Kò sí ẹ̀kọ́ fún àwọn ọ̀dọ́';

  @override
  String get noAdultLesson => 'Kò sí ẹ̀kọ́ fún àgbàlagbà';

  @override
  String get sundaySchoolManual => 'Ìwé Ilé-Ẹ̀kọ́ Ọjọ́ Sunday';

  @override
  String get accessWeeklyLessonsOffline => 'Wọlé sí àwọn ẹ̀kọ́ Bíbélì ọ̀sẹ̀ fún ọ̀dọ́ àti àgbàlagbà nígbàkúgbà, ní ibikíbi — àní láìsí ayélujára pàápàá!';

  @override
  String get builtForRccg => 'Ti a ṣe fún Ẹ̀gbẹ́ Kristẹni Onírẹ̀lẹ̀ ti Ọlọ́run!';

  @override
  String get getStarted => 'Bẹ̀rẹ̀';

  @override
  String get openFullChapter => 'Ṣí apakan kíkún →';

  @override
  String get close => 'Pa á';

  @override
  String get preparing => 'Ìmúrasílẹ̀...';

  @override
  String preparingWithProgress(Object progress, Object totalSteps) {
    return 'Ìmúrasílẹ̀... ($progress/$totalSteps)';
  }

  @override
  String get login => 'Wọlé';

  @override
  String get signInToCreateOrJoin => 'Wọlé láti ṣẹ̀dá tàbí darapọ̀ ilé ìjọ rẹ';

  @override
  String get google => 'Google';

  @override
  String get apple => 'Apple';

  @override
  String get guest => 'Àlùba';

  @override
  String get signInFailed => 'Wíwọ́ dárá ṣubú';

  @override
  String get applSignInFailed => 'Apple wíwọ́ dárá ṣubú';

  @override
  String get guestModeFailed => 'Ìyálé àlùba dárá ṣubú';

  @override
  String get guestUser => 'Oniborí àfojúkọ';

  @override
  String get guestMode => 'ìkọ̀kọ̀ àfojúkọ';

  @override
  String get anonymous => 'Àkọjọ̀';

  @override
  String get continueWithGoogle => 'Tẹ̀síwájú pẹ̀lú Google';

  @override
  String get signInWithApple => 'Wọlé pẹ̀lú Apple';

  @override
  String get continueAsGuest => 'Tẹ̀síwájú gẹ́gẹ́ bí àlejò';

  @override
  String get guestDataWarning => 'Gbogbo dátà ti wa ni ipamọ́ fún ìgbà díẹ̀, wọn yóò parẹ́ lẹ́yìn tí o bá jáde.';

  @override
  String get fullAccessDescription => 'Wiwọlé pátápátá: dá tàbí darapọ̀ mọ́ ṣọ́ọ̀ṣì rẹ';

  @override
  String get limitedAccessDescription => 'Wiwọlé díẹ̀: lo ipò gbogbogbò nìkan';

  @override
  String get profile => 'Profáìlì';

  @override
  String get settings => 'Àwọn ètò';

  @override
  String get bookmarks => 'Àwọn ìbalẹ̀';

  @override
  String get streaks => 'Àwọn ìdì';

  @override
  String get leaderboard => 'Tabili àwọn olódájú';

  @override
  String get assignments => 'Ìṣẹ̀ àkọ́kọ́';

  @override
  String get teachers => 'Àwọn oníkòó';

  @override
  String get appSuggestions => 'Àwọn ìpinnu app';

  @override
  String get adminTools => 'Àwọn ọ̀rọ̀ aláṣẹ';

  @override
  String get colorPalette => 'Palette àwọ';

  @override
  String get parish => 'Ìjọ ìsìn';

  @override
  String get joinCode => 'Kòòdù ìdarapọ̀';

  @override
  String get pastor => 'Alagba';

  @override
  String get notAvailable => 'Kò sí';

  @override
  String get deleteAccount => 'Pa àkọọlẹ rẹ';

  @override
  String deletionScheduledOn(Object date) {
    return 'Àkọọlẹ ti ṣètò fún ìparẹ́ pátápátá ní:\n$date';
  }

  @override
  String get logInToCancel => 'Wọlé ṣáájú ọjọ́ yìí láti fagilẹ ìparẹ́ àti dá àkọọlẹ rẹ padà.';

  @override
  String get permanentDeletionWarning => 'Àkọọlẹ rẹ àti gbogbo dátà yóò parẹ́ pátápátátá lẹ́yìn ọjọ́ ọgbọ̀n.\nO lè fagilẹ nígbàkúgbà nípa wíwọlé padà.';

  @override
  String get deleteAccountDialogTitle => 'Pa àkọọlẹ rẹ?';

  @override
  String get deleteAccountDialogContent => '• Àkọọlẹ rẹ yóò parẹ́ pátápátá ní ọjọ́ ọgbọ̀n.\n• Gbogbo dátà rẹ (àwọn àmì ìfihàn, ìtẹ̀síwájú, iṣẹ́, ipò) yóò parẹ́.\n• O lè fagilẹ nígbàkúgbà nípa wíwọlé padà.\n\nṢé o dá ọ lójú?';

  @override
  String get cancelDeletion => 'Fagilẹ Ìparẹ́';

  @override
  String get deleteIn30Days => 'Pa ní ọjọ́ ọgbọ̀n';

  @override
  String get deletionScheduledButton => 'Ìparẹ́ ti ṣètò';

  @override
  String get accountDeletionScheduledSnack => 'Àkọọlẹ ti ṣètò fún ìparẹ́ ní ọjọ́ ọgbọ̀n. Wọlé láti fagilẹ.';

  @override
  String get deletionCancelledSnack => 'Ìparẹ́ àkọọlẹ ti fagilẹ! Káàbọ̀ padà 🎉';

  @override
  String get feedback => 'Ìdáhún';

  @override
  String get rateAppOnGooglePlay => 'Ìdánilójú app lórí Google Play';

  @override
  String get suggestAFeature => 'Ìmọ̀ràn nǹkan kan';

  @override
  String get preferences => 'Àwọn ìfẹ́';

  @override
  String get signIn => 'Wọlé';

  @override
  String get register => 'Ìforítilẹ̀';

  @override
  String get join => 'Darapọ̀';

  @override
  String get registerParish => 'Ìforítilẹ̀ ilé ìjọ';

  @override
  String get createChurch => 'Ṣẹ̀dá ilé ìjọ';

  @override
  String get joinChurch => 'Darapọ̀ ilé ìjọ';

  @override
  String get selectChurch => 'Yan ilé ìjọ kan';

  @override
  String get churchAccessCode => 'Koodu wíwọ́ ilé ìjọ';

  @override
  String get churchName => 'Orúkọ ilé ìjọ';

  @override
  String get pastorName => 'Orúkọ òjìṣẹ́';

  @override
  String get leaveChurch => 'Kúrò nínú ilé ìjọ';

  @override
  String get selectYourChurch => 'Yan ilé ìjọ rẹ';

  @override
  String get noChurchSelected => 'Kò há yan ilé ìjọ';

  @override
  String get joinedSuccessfully => 'O ti darapọ̀ ní àṣeyọrí!';

  @override
  String get shareAsLessonPdf => 'Pín gẹ́gẹ́ PDF';

  @override
  String get shareLink => 'Pín àsopọ̀';

  @override
  String get saveLessonPrompt => 'Wọlé kí o darapọ̀ ilé ìjọ láti gbé àwọn ẹ̀kọ́';

  @override
  String get lessonRemovedFromSaved => 'Ẹ̀kọ́ yìí tí wá kúrò nínú àwọn tí a gbé';

  @override
  String get lessonSaved => 'Ẹ̀kọ́ ti gbé! 📚';

  @override
  String get operationFailed => 'Iṣẹ̀ dárá ṣubú';

  @override
  String get removedFromSavedLessons => 'Ìpalẹ̀ kúrò nínú àwọn tí a gbé';

  @override
  String get saveThisLesson => 'Gbé ẹ̀kọ́ yìí';

  @override
  String get verseTemporarilyUnavailable => 'Àsàlẹ̀ kò sí ní àkókò yìí';

  @override
  String get removedFromSavedReadings => 'Ìpalẹ̀ kúrò nínú àwọn tí a gbé';

  @override
  String get saveThisReading => 'Gbé ìpalẹ̀ yìí';

  @override
  String get pleaseSelectYourChurchFirst => 'Jọ̀wọ́ yan ilé ìjọ rẹ dájú!';

  @override
  String get pleaseEnterAtLeastOneAnswer => 'Jọ̀wọ́ tún orí àtijọ́ kan tàbí ju.';

  @override
  String get yourAnswersHaveBeenSubmitted => 'A ti gbà àwọn orí àtijọ́ rẹ!';

  @override
  String get failedToSaveYourAnswers => 'A kò le gbé àwọn orí àtijọ́ rẹ. Jọ̀wọ́ gbìyànjú lẹ́ẹ̀kansi.';

  @override
  String get globalAdminsOnlyNoChurch => 'Àdìmìnì àgbáyé nìkan — kò han ilé ìjọ.';

  @override
  String get addAnotherResponse => 'Fi orí àtijọ́ mìi sẹ̀';

  @override
  String get noSubmissionsYet => 'Kò si ẹnìkọ́kan tí o fi sẹ̀.';

  @override
  String get currentStatus => 'Àpẹ̀rẹ̀ ìgbà yìí';

  @override
  String get submitted => 'A ti fi sẹ̀';

  @override
  String get notSubmitted => 'Kò fi sẹ̀';

  @override
  String get graded => 'Àti ìyán';

  @override
  String get viewFeedback => 'Wo ìdáhún';

  @override
  String get leaveFeedback => 'Fi ìdáhún sẹ̀';

  @override
  String get lessonTitle => 'Àkọlé ẹ̀kọ́';

  @override
  String get topic => 'Ọrọ̀ àkọ́kọ́';

  @override
  String get biblePassage => 'ÀTẸ̀GÙN BÍBÉLÌ:';

  @override
  String get guestUserLabel => 'Olùmúlò àlùba';

  @override
  String get loading => 'Ń lo ìṣẹ';

  @override
  String get answerWeeklyAssignment => 'Dahùn iṣẹ́ ìdánilẹ́kọ̀ọ́ ọ̀sẹ̀';

  @override
  String get loginForAssignment => 'Wọlé láti dahùn iṣẹ́ ìdánilẹ́kọ̀ọ́';

  @override
  String get monday => 'Ọjọ́ Aje';

  @override
  String get tuesday => 'Ọjọ́ Ìsẹ̀gun';

  @override
  String get wednesday => 'Ọjọ́ Ọ̀rọ̀';

  @override
  String get thursday => 'Ọjọ́ Ọ̀bọ̀';

  @override
  String get friday => 'Ọjọ́ Ẹtì';

  @override
  String get saturday => 'Ọjọ́ Àbámẹ́ta';

  @override
  String get sunday => 'Ọjọ́ Àìkú';

  @override
  String get january => 'Ọṣù KìNní';

  @override
  String get february => 'Ọṣù Èrèlè';

  @override
  String get march => 'Ọṣù Ẹ̀rẹ̀nà';

  @override
  String get april => 'Ọṣù Ìgbé';

  @override
  String get may => 'Ọṣù Ẹ̀bibi';

  @override
  String get june => 'Ọṣù Òkúdu';

  @override
  String get july => 'Ọṣù Agẹmọ';

  @override
  String get august => 'Ọṣù Ọ̀gun';

  @override
  String get september => 'Ọṣù Owewe';

  @override
  String get october => 'Ọṣù Ọ̀wàrà';

  @override
  String get november => 'Ọṣù Bélú';

  @override
  String get december => 'Ọṣù Ọ̀pẹ̀';

  @override
  String get switchedToGeneral => 'Gba àwọn ẹ̀kọ́ Àpapọ̀ (Àgbáyé)';

  @override
  String get shareLesson => 'Pín ẹ̀kọ́';

  @override
  String get readingStreak => 'Ìdì Ìkàwe';

  @override
  String get todaysReading => 'Kíkà Òní:';

  @override
  String get noReading => 'Kò sí kíkà';

  @override
  String get completeReading => 'Kíkà Kíkún';

  @override
  String readingTimer(Object remainingSeconds) {
    return 'Ṣáájú ìtẹ̀síwájú… ($remainingSeconds s)';
  }

  @override
  String get memoryVerse => 'Àsàlẹ̀ tí a mọ̀:';

  @override
  String get prayer => 'Àdúrá';

  @override
  String get noBookmarksYet => 'Kò sí ìbalẹ̀ fun';

  @override
  String get signInToSaveFavorites => 'Wọlé láti gbé àwọn ìfẹ́ rẹ';

  @override
  String get bookmarksSyncMessage => 'Àwọn ìbalẹ̀, àwọn ẹ̀kọ́, àti àwọn ìpalẹ̀ yìó ní ìfasẹ̀sì ní gbogbo àwọn ẹrọ́ rẹ.';

  @override
  String get english => 'English';

  @override
  String get francais => 'Français';

  @override
  String get copied => 'Àtúkọ pẹ̀lú!';

  @override
  String get invalidSavedLessonId => 'ID ẹ̀kọ́ tí a gbé rẹ̀ láìtọ́';

  @override
  String get lessonNotFound => 'Ẹ̀kọ́ kò rí';

  @override
  String get savedLessonContentNotAvailable => 'Àkópọ̀ ẹ̀kọ́ tí a gbé kò sí';

  @override
  String get pleaseAddAComment => 'Jọ̀wọ́ fi àkiyèsi kan sẹ̀';

  @override
  String get thankYouFeedbackSubmitted => 'E ṣeun! Àkiyèsi ti síralẹ̀.';

  @override
  String errorSharingChurch(Object error) {
    return 'Àṣìṣe láti pín ilé ìjọ: $error';
  }

  @override
  String get youHaveLeftTheChurch => 'O ti kúrò nínú ilé ìjọ';

  @override
  String get pleaseLogInToViewAssignments => 'Jọ̀wọ́ wọlé láti wo àwọn ìṣẹ̀ àkọ́kọ́ rẹ';

  @override
  String get teenResponses => 'Àwọn ìdáhún àgẹ ọ̀dọ́';

  @override
  String get adultResponses => 'Àwọn ìdáhún àgbà';

  @override
  String get editResponses => 'Ṣatúnṣe àwọn ìdáhún';

  @override
  String yourScore(Object score, Object total) {
    return 'Ìdánilójú rẹ: $score / $total';
  }

  @override
  String get myResponses => 'Àwọn ìdáhún mi:';

  @override
  String get yourSubmittedResponses => 'Àwọn ìdáhún tí o fìsẹ̀';

  @override
  String get assignmentGraded => 'A ti ṣe àyẹ̀wò.';

  @override
  String get gradedNoEdit => 'A ti ṣe àyẹ̀wò — kò lè ṣàtúnṣe';

  @override
  String get noQuestionAvailable => 'Kò sí ìbéèrè.';

  @override
  String get noQuestionAvailableForThisDay => 'Kò sí ìbéèrè lónìí.';

  @override
  String get myAssignment => 'Iṣẹ́ mi';

  @override
  String get thisWeeksAssignment => 'Iṣẹ́ ọ̀sẹ̀ yìí';

  @override
  String dueDateFormatted(Object dateFormatted) {
    return 'Parí: $dateFormatted';
  }

  @override
  String get gradedByTeacher => 'Olùkọ́ ṣe àyẹ̀wò';

  @override
  String get teachersFeedback => 'Àlàyé olùkọ́:';

  @override
  String get noTeacherFeedbackProvided => 'Kò sí àlàyé.';

  @override
  String get submittedTapEditToChange => 'A ránṣẹ́ — Ṣàtúnṣe';

  @override
  String get writeYourResponseHere => 'Kọ ìdáhùn síbí…';

  @override
  String get submit => 'Ránṣẹ́';

  @override
  String get loadingQuestion => 'Ń gba ìbéèrè…';

  @override
  String get teenOrAdultResponses => 'Ìdáhùn';

  @override
  String get question => 'Ìbéèrè';

  @override
  String get submissions => 'Fífi ránṣẹ́';

  @override
  String answerWithIndex(Object i, Object answer) {
    return 'Ìdáhùn $i: $answer';
  }

  @override
  String get reset => 'Tun bẹ̀rẹ̀';

  @override
  String get grade => 'Ṣe àyẹ̀wò';

  @override
  String get teenSundaySchoolLesson => 'Ẹ̀kọ́ Sunday School àgẹ ọ̀dọ́';

  @override
  String get adultSundaySchoolLesson => 'Ẹ̀kọ́ Sunday School àgbà';

  @override
  String get youWillBeSignedOut => 'A yóò tú ọ lọ́wọ́ àti padà sí ọ̀ṣè wíwọ́.';

  @override
  String get leaveWithoutJoining => 'Kúrò láìdarapọ̀?';

  @override
  String get setUpYourParish => 'Ṣe àkójọ ilé ìjọ rẹ àti jẹ́ nǹkan rẹ̀ àgba';

  @override
  String get enterSixDigitCode => 'Tún koodu mẹ́ẹ̀fadihlokan tí àgba ilé ìjọ rẹ fún';

  @override
  String copiedHex(Object hex) {
    return 'Dá: $hex';
  }

  @override
  String get rccgSundaySchoolGeneral => 'RCCG Sunday School (Àpapọ̀)';

  @override
  String get savedItems => 'Àwọn nkan tí a gbé';

  @override
  String errorLoadingData(Object error) {
    return 'Àṣìṣe: $error';
  }

  @override
  String get noRankingsYet => 'Kò sí àti ìyán ní ẹ̀ká yìí níbìí.';

  @override
  String get couldNotDetermineBook => 'Kò le túmo akúnlẹ̀ tàbí ìkòkò';

  @override
  String get bookNotFoundInBibleVersion => 'Akúnlẹ̀ kò rí nínú ìyálé Bíbélì tó wà níbìí';

  @override
  String get signInAndJoinToBookmarks => 'Wọlẹ àti darapọ ẹgbẹ kan láti tọjú àwọn àmì';

  @override
  String get bookmarkRemoved => 'Àmì tiíkúrò';

  @override
  String get bookmarked => 'Àmìlẹ';

  @override
  String get pleaseSelectChurchFirst => 'Jọ̀wọ́ yan ilé ìjọ rẹ dájú!';

  @override
  String get couldNotSendRequest => 'Kò le rán ìbeèrè náà';

  @override
  String thankYouPastor(Object name) {
    return 'E ṣeun, $name!';
  }

  @override
  String get createYourChurch => 'Ṣẹ̀dá ilé ìjọ rẹ';

  @override
  String get pleaseFillAllRequiredFields => 'Jọ̀wọ́ kun gbogbo àwọn ìpò tí a nilo';

  @override
  String get leaveChurchMessage => 'O kò le níní ìsopọ̀ pẹ̀lú ilé ìjọ yìí mọ́.';

  @override
  String get cancel => 'Fagile';

  @override
  String get accessRestricted => 'Wíwọ́ ti díkun';

  @override
  String get manageChurchSettings => 'Ṣatúnṣe àwọn ètò ilé ìjọ';

  @override
  String get askYourPastor => 'Béèrè koodu lọ́wọ́ àgba ilé ìjọ rẹ';

  @override
  String get primaryColors => 'Àwọn elu nǹkan pàtàkì';

  @override
  String get secondaryColors => 'Àwọn elu kejì';

  @override
  String get neutralAndBackground => 'Àlàáro àti ẹhin';

  @override
  String get statusColors => 'Àwọn elu àpẹ̀rẹ̀';

  @override
  String get greyScale => 'Grey Scale';

  @override
  String get darkTheme => 'Ìyálé dúdú';

  @override
  String get members => 'Àwọn ọmọ ajọ';

  @override
  String get lessonCompletion => 'Ìkẹhin ẹ̀kọ́';

  @override
  String get dailyActive => 'Tó nrimọ̀ ojoojúmọ́';

  @override
  String get weeklyActive => 'Tó nrimọ̀ ní ọ̀sẹ̀';

  @override
  String get activity => 'Iṣẹ̀ (Ọjọ́ 7 tó kẹ́yìn)';

  @override
  String get lessonProgress => 'Iṣẹ̀lợra ẹ̀kọ́';

  @override
  String get alertsAndHighlights => 'Àwọn ìkìlọ àti àwọn ohun tí a ní àkíyèsi';

  @override
  String get testNotificationScheduled => 'Àkiyèsi ìdánwò ti ṣeé ọjọ́ nílẹ̀ àwọn iṣẹ̀jú 30!';

  @override
  String get exactTimingDenied => 'Àkókò gan-an ti díkun. Ìrántí yìí yóò jẹ́ àpapọ̀.';

  @override
  String get addItem => 'Fi nkan kan sẹ̀';

  @override
  String get yoruba => 'Èdè Yorùbá';

  @override
  String get navHome => 'Ilé';

  @override
  String get navBible => 'Bibeli';

  @override
  String get navAccount => 'Àkáọ̀nt';

  @override
  String get pleaseLogInToViewStreak => 'Jọ̀wọ́ wọ sísẹ̀ láti wo ìbámu rẹ.';

  @override
  String get offlineMode => 'Ìmọ̀ Ìgúnrin • Lilo àwọn ẹ̀kọ́ tí a sábè';

  @override
  String get newLesson => 'Ẹ̀kọ́ tuntun!';

  @override
  String get openButton => 'TI ÌPILẸ̀';

  @override
  String get leaveButton => 'Kúrò';

  @override
  String get leaveChurchDialog => 'Kúrò nínú ìlú?';

  @override
  String get oldTestament => 'Iwe Atijọ';

  @override
  String get newTestament => 'Iwe Titun';

  @override
  String get updateAvailable => 'Imudojúìwọ̀n tuntun wà!';

  @override
  String get updateMessage => 'Ẹ̀dà tuntun kan ti ṣetan pẹ̀lú àtúnṣe àti ìmúlò.\nṢe o fẹ́ gba a báyìí?';

  @override
  String get later => 'Lẹ́yìnna';

  @override
  String get updateNow => 'Ṣe imudojúìwọ̀n báyìí';

  @override
  String get invalidSixDigitCode => 'Jọ̀wọ́ tẹ kóòdù nọ́mbà mẹ́fà tó pé';

  @override
  String get invalidServerResponse => 'Ìdáhùn sẹ́fà àìtọ́';

  @override
  String get failedToJoinChurch => 'Kò lè darapọ̀ mọ́ ṣọ́ọ̀ṣì';

  @override
  String get signOutWarning => 'A ó jáde ọ́, a ó sì da ọ padà sí ojú-ìbẹ̀rẹ̀ ìwọlé.';

  @override
  String get stay => 'Dúró';

  @override
  String get welcome => 'Káàbọ̀!';

  @override
  String get connectToChurch => 'Ẹ jẹ́ ká so ọ pọ̀ mọ́ ṣọ́ọ̀ṣì rẹ';

  @override
  String get joinParish => 'Darapọ̀ mọ́ Páríṣì';

  @override
  String get enterChurchCode => 'Tẹ kóòdù ṣọ́ọ̀ṣì';

  @override
  String get askPastorForCode => 'Bẹ̀rẹ̀ lọ́wọ́ pásítọ̀ rẹ fún kóòdù';

  @override
  String get mustBeSignedIn => 'O gbọ́dọ̀ ti wọlé';

  @override
  String get requestSent => 'A rán ìbéèrè náà!';

  @override
  String requestSummary(Object churchName, Object parishName, Object country) {
    return 'Ìbéèrè rẹ láti dá sílẹ̀:\n\n🏛️ \$churchName\n📍 \$parishName\n🌍 \$country\n\nti ránṣẹ́.';
  }

  @override
  String get approvalNotice => 'Iwọ yóò gba ìkìlọ̀ láàárín wákàtí 24 lẹ́yìn ìfọwọ́sí.';

  @override
  String get gotIt => 'Mo ye!';

  @override
  String get churchAlreadyExists => 'Ṣọ́ọ̀ṣì kan pẹ̀lú orúkọ yìí ti wà tẹ́lẹ̀. Jọ̀wọ́ kan sí ìtìlẹ́yìn.';

  @override
  String genericError(Object toString) {
    return 'Àṣìṣe: $toString';
  }

  @override
  String get churchInformation => 'Alaye Ṣọ́ọ̀ṣì';

  @override
  String get parishName => 'Orúkọ Páríṣì / Ẹ̀ka *';

  @override
  String get adminEmail => 'Imeeli Alábòójútó *';

  @override
  String get addressOptional => 'Àdírẹ́sì (aṣàyàn)';

  @override
  String get country => 'Orílẹ̀-èdè *';

  @override
  String get submitRequest => 'Fi ìbéèrè ránṣẹ́';

  @override
  String get bibleGenesis => 'Genesis';

  @override
  String get bibleExodus => 'Exodus';

  @override
  String get bibleLeviticus => 'Leviticus';

  @override
  String get bibleNumbers => 'Àwọn Nọ́ẹ̀ẹ́';

  @override
  String get bibleDeuteronomy => 'Deuteronomio';

  @override
  String get bibleJoshua => 'Joshua';

  @override
  String get bibleJudges => 'Àwọn Onídìtì';

  @override
  String get bibleRuth => 'Ruth';

  @override
  String get bible1Samuel => '1 Samuel';

  @override
  String get bible2Samuel => '2 Samuel';

  @override
  String get bible1Kings => '1 Oba';

  @override
  String get bible2Kings => '2 Oba';

  @override
  String get bible1Chronicles => '1 Iwe Àwọn Ọjọ́';

  @override
  String get bible2Chronicles => '2 Iwe Àwọn Ọjọ́';

  @override
  String get bibleEzra => 'Ezra';

  @override
  String get bibleNehemiah => 'Nehemiah';

  @override
  String get bibleEsther => 'Esther';

  @override
  String get bibleJob => 'Job';

  @override
  String get biblePsalms => 'Àwọn Ewì';

  @override
  String get bibleProverbs => 'Àwọn Òwe';

  @override
  String get bibleEcclesiastes => 'Eklesiastis';

  @override
  String get bibleSongOfSolomon => 'Orin Iyalode';

  @override
  String get bibleIsaiah => 'Isaiah';

  @override
  String get bibleJeremiah => 'Jeremiah';

  @override
  String get bibleLamentations => 'Awọn Ariwi';

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
  String get bibleActs => 'Iwe Awọn Iṣẹ̀';

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
  String get bibleRevelation => 'Ifihàn';

  @override
  String get copy => 'Àtúkọ';

  @override
  String get share => 'Pín';

  @override
  String get bookmark => 'Àmì';

  @override
  String get removeHighlight => 'Yọ ìyalẹnu kúrò';

  @override
  String get verseSelected => 'ẹsẹ ti yan';

  @override
  String get versesSelected => 'àwọn ẹsẹ ti yan';

  @override
  String get advertsDisclosure => 'Àwọn ibi-ilana ni o finanse app ati aṣẹwádìí ọ̀pọ̀lọ, fun ayọ rẹ.';

  @override
  String get inviteYourFriends => 'Ṣe asopọ àwọn ọ̀rẹ́ rẹ';

  @override
  String get signOut => 'Jáde';

  @override
  String get pleaseAddComment => 'Jọ̀wọ́ fi àsìkò kan kun';

  @override
  String get feedbackSubmitted => 'O dupe! Ìfidìbá rẹ ti jáde.';

  @override
  String get yourSuggestions => 'Àwọn ìpinnu rẹ';

  @override
  String get suggestionsHelpApp => 'Àwọn ìpinnu rẹ ṣe ilò ìwé yìí fun gbogbo!';

  @override
  String get tellUsWhatYouThink => 'Sọ fún wa ètò rẹ...';

  @override
  String get submitFeedback => 'Fipilẹ̀ Ìfidìbá';

  @override
  String get rateAppSettings => 'Àáá... Láti ṣe ìwontunwonsi ìwé yìí, jọ̀wọ́ lọ sí Settings ...';

  @override
  String get pleaseSignInStreak => 'Jọ̀wọ́ wọlẹ láti wo òun rẹ ti kìkì.';

  @override
  String get dayStreak => 'ọjọ́ ti kìkì';

  @override
  String get freezesAvailable => 'Àwọn tutu tẹ́tẹ́';

  @override
  String get freezesDescription => 'Àwọn tutu ṣe agbára fun yin láti fọ́ ọjọ́ kan láìsẹ̀da òun rẹ.';

  @override
  String get lastCompleted => 'Ìpari tẹ́lẹ̀';

  @override
  String get never => 'Kò dájú';

  @override
  String get progressNextFreeze => 'Ọ̀nà sí tutu tẹ́lẹ̀';

  @override
  String get daysUntilNextFreeze => 'ọjọ́(s) títí òun tutu tẹ́lẹ̀ (òun ọgójú nígbà kọọkan tabi sẹ́tẹ́ ara 1 tutu)';

  @override
  String get howFreezesWork => 'Báwo ni àwọn tutu ṣe ìṣẹ̀';

  @override
  String get freezeExplanation => 'Tí ẹ bá kọ ọjọ́ kan, tutu yóò ti wà nípa láti pa òun rẹ.';

  @override
  String get savedItemsTitle => 'Àwọn nkan tí a gbé';

  @override
  String get noBookmarksYetMessage => 'Kò sí àmì fun';

  @override
  String get saveFavoriteScriptures => 'Gbé àwọn ẹsẹ tí o fẹ́ láti ka wọn ní àkókò gbogbo.';

  @override
  String get deleteBookmark => 'Yọ àmì kúrò';

  @override
  String get yourNote => 'Àsìkò rẹ';

  @override
  String get noSavedLessons => 'Kò sí ẹ̀kọ́ tí a gbé';

  @override
  String get saveLessonsToReview => 'Gbé àwọn ẹ̀kọ́ láti tẹ̀jọ́ wọn ní ìgbà ẹhìnrere.';

  @override
  String get openLesson => 'Ṣí ẹ̀kọ́';

  @override
  String get deleteLesson => 'Yọ ẹ̀kọ́ kúrò';

  @override
  String get noteLabel => 'Àsìkò';

  @override
  String get noFurtherReadings => 'Kò sí ìpalẹ̀ àfikun';

  @override
  String get saveReadingMaterials => 'Gbé ìpalẹ̀ láti ṣàwòran wọn ní òpólòpò.';

  @override
  String get deleteReading => 'Yọ ìpalẹ̀ kúrò';

  @override
  String get lessons => 'Àwọn ẹ̀kọ́';

  @override
  String get readings => 'Àwọn ìpalẹ̀';

  @override
  String get adult => 'Àgbà';

  @override
  String get teen => 'Ọ̀dọ́';

  @override
  String get church => 'Ilé ìjọ';

  @override
  String get global => 'Àgbáyé';

  @override
  String get errorWithMessage => 'Àṣìṣe:';

  @override
  String get yourRank => 'Àti rẹ:';

  @override
  String get anonymousStudent => 'Ọmọ-ẹ̀kọ́ Àkọjọ̀';

  @override
  String get pointsLabel => 'pts';

  @override
  String get refreshAssignments => 'Túnkatà àwọn';

  @override
  String get empty => 'Bẹ́loji!';

  @override
  String get noAssignmentsInQuarter => 'Kọ́ àwọn láti ẹ́ kọ́ɔkò yíì.';

  @override
  String get myAssignments => 'Mọ Àwọn';
}
