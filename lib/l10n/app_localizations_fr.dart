// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Leçons d’école du dimanche';

  @override
  String get language => 'Langue';

  @override
  String get sundaySchoolLesson => 'Leçon d\'école du dimanche';

  @override
  String get noLessonToday => 'Aucune leçon aujourd\'hui';

  @override
  String get noTeenLesson => 'Aucune leçon pour les adolescents';

  @override
  String get noAdultLesson => 'Aucune leçon pour les adultes';

  @override
  String get sundaySchoolManual => 'RCCG - Manuel d\'École du Dimanche';

  @override
  String get accessWeeklyLessonsOffline => 'Accédez à vos leçons bibliques hebdomadaires pour adolescents et adultes n\'importe quand, n\'importe où — même hors ligne !';

  @override
  String get builtForRccg => 'Conçu pour l\'Église Chrétienne Rachetée de Dieu !';

  @override
  String get getStarted => 'Commencer';

  @override
  String get openFullChapter => 'Ouvrir le chapitre complet →';

  @override
  String get close => 'Fermer';

  @override
  String get preparing => 'Préparation en cours...';

  @override
  String preparingWithProgress(Object progress, Object totalSteps) {
    return 'Préparation... ($progress/$totalSteps)';
  }

  @override
  String get login => 'Connexion';

  @override
  String get signInToCreateOrJoin => 'Connectez-vous pour créer ou rejoindre votre église';

  @override
  String get google => 'Google';

  @override
  String get apple => 'Apple';

  @override
  String get guest => 'Invité';

  @override
  String get signInFailed => 'Échec de la connexion';

  @override
  String get applSignInFailed => 'Échec de la connexion Apple';

  @override
  String get guestModeFailed => 'Échec du mode invité';

  @override
  String get guestUser => 'Utilisateur invité';

  @override
  String get guestMode => 'mode invité';

  @override
  String get anonymous => 'Anonyme';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get signInWithApple => 'Se connecter avec Apple';

  @override
  String get continueAsGuest => 'Continuer en tant qu\'invité';

  @override
  String get guestDataWarning => 'Toutes les données sont temporairement enregistrées et perdues après déconnexion.';

  @override
  String get fullAccessDescription => 'Accès complet : créer ou rejoindre votre église';

  @override
  String get limitedAccessDescription => 'Accès limité : utiliser uniquement le mode général';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get bookmarks => 'Signets';

  @override
  String get streaks => 'Séries';

  @override
  String get leaderboard => 'Classement';

  @override
  String get assignments => 'Devoirs';

  @override
  String get soundEffects => 'Effets sonores';

  @override
  String get ageGroup => 'Groupe d’âge';

  @override
  String get teachers => 'Professeurs';

  @override
  String get appSuggestions => 'Suggestions d\'application';

  @override
  String get adminTools => 'Outils d\'administration';

  @override
  String get colorPalette => 'Palette de couleurs';

  @override
  String get parish => 'Paroisse';

  @override
  String get joinCode => 'Code d\'accès';

  @override
  String get pastor => 'Pasteur';

  @override
  String get notAvailable => 'Non disponible';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String deletionScheduledOn(Object date) {
    return 'Compte programmé pour suppression définitive le :\n$date';
  }

  @override
  String get logInToCancel => 'Connectez-vous avant cette date pour annuler la suppression et restaurer votre compte.';

  @override
  String get permanentDeletionWarning => 'Votre compte et toutes vos données seront définitivement supprimés après 30 jours.\nVous pouvez annuler à tout moment en vous reconnectant.';

  @override
  String get deleteAccountDialogTitle => 'Supprimer le compte ?';

  @override
  String get deleteAccountDialogContent => '• Votre compte sera définitivement supprimé dans 30 jours.\n• Toutes vos données (signets, séries, devoirs, classement) seront perdues.\n• Vous pouvez annuler à tout moment en vous reconnectant simplement.\n\nÊtes-vous sûr ?';

  @override
  String get cancelDeletion => 'Annuler la suppression';

  @override
  String get deleteIn30Days => 'Supprimer dans 30 jours';

  @override
  String get deletionScheduledButton => 'Suppression programmée';

  @override
  String get accountDeletionScheduledSnack => 'Compte programmé pour suppression dans 30 jours. Connectez-vous pour annuler.';

  @override
  String get deletionCancelledSnack => 'Suppression du compte annulée ! Bienvenue à nouveau 🎉';

  @override
  String get feedback => 'Commentaires';

  @override
  String get rateAppInStore => 'Évaluer l’application sur l’App Store';

  @override
  String get suggestAFeature => 'Suggérer une fonctionnalité';

  @override
  String get preferences => 'Préférences';

  @override
  String get signIn => 'Se connecter';

  @override
  String get register => 'S\'inscrire';

  @override
  String get join => 'Rejoindre';

  @override
  String get registerParish => 'Enregistrer une paroisse';

  @override
  String get createChurch => 'Créer une église';

  @override
  String get joinChurch => 'Rejoindre une église';

  @override
  String get selectChurch => 'Sélectionner une église';

  @override
  String get churchAccessCode => 'Code d\'accès de l\'église';

  @override
  String get churchName => 'Nom de l\'église';

  @override
  String get pastorName => 'Nom du pasteur';

  @override
  String get leaveChurch => 'Quitter l\'église';

  @override
  String get selectYourChurch => 'Sélectionnez votre église';

  @override
  String get noChurchSelected => 'Aucune église sélectionnée';

  @override
  String get joinedSuccessfully => 'Inscription réussie !';

  @override
  String get shareAsLessonPdf => 'Partager en PDF';

  @override
  String get shareLink => 'Partager le lien';

  @override
  String get saveLessonPrompt => 'Connectez-vous et rejoignez une église pour enregistrer les leçons';

  @override
  String get lessonRemovedFromSaved => 'Leçon supprimée des enregistrements';

  @override
  String get lessonSaved => 'Leçon enregistrée! 📚';

  @override
  String get operationFailed => 'Opération échouée';

  @override
  String get removedFromSavedLessons => 'Supprimer des leçons enregistrées';

  @override
  String get saveThisLesson => 'Enregistrer cette leçon';

  @override
  String get verseTemporarilyUnavailable => 'Verset temporairement indisponible';

  @override
  String get removedFromSavedReadings => 'Supprimer des lectures enregistrées';

  @override
  String get saveThisReading => 'Enregistrer cette lecture';

  @override
  String get pleaseSelectYourChurchFirst => 'Veuillez d\'abord sélectionner votre église!';

  @override
  String get pleaseEnterAtLeastOneAnswer => 'Veuillez entrer au moins une réponse à la question.';

  @override
  String get yourAnswersHaveBeenSubmitted => 'Vos réponses ont été soumises avec succès!';

  @override
  String get failedToSaveYourAnswers => 'Impossible de sauvegarder vos réponses. Veuillez réessayer.';

  @override
  String get globalAdminsOnlyNoChurch => 'Admins mondiaux uniquement — aucune église sélectionnée.';

  @override
  String get addAnotherResponse => 'Ajouter une autre réponse';

  @override
  String get noSubmissionsYet => 'Pas encore de soumissions.';

  @override
  String get currentStatus => 'État actuel';

  @override
  String get submitted => 'Soumis';

  @override
  String get notSubmitted => 'Non soumis';

  @override
  String get graded => 'Noté';

  @override
  String get viewFeedback => 'Afficher les commentaires';

  @override
  String get leaveFeedback => 'Laisser des commentaires';

  @override
  String get lessonTitle => 'Titre de la leçon';

  @override
  String get topic => 'Sujet';

  @override
  String get biblePassage => 'PASSAGE BIBLIQUE:';

  @override
  String get guestUserLabel => 'Utilisateur invité';

  @override
  String get loading => 'Chargement';

  @override
  String get answerWeeklyAssignment => 'Devoir hebdomadaire';

  @override
  String get loginForAssignment => 'Connectez-vous pour répondre au devoir';

  @override
  String get signinToSubmit => 'Connectez-vous pour soumettre';

  @override
  String get monday => 'Lundi';

  @override
  String get tuesday => 'Mardi';

  @override
  String get wednesday => 'Mercredi';

  @override
  String get thursday => 'Jeudi';

  @override
  String get friday => 'Vendredi';

  @override
  String get saturday => 'Samedi';

  @override
  String get sunday => 'Dimanche';

  @override
  String get monthShortJan => 'Janv.';

  @override
  String get monthShortFeb => 'Févr.';

  @override
  String get monthShortMar => 'Mars';

  @override
  String get monthShortApr => 'Avr.';

  @override
  String get monthShortMay => 'Mai';

  @override
  String get monthShortJun => 'Juin';

  @override
  String get monthShortJul => 'Juil.';

  @override
  String get monthShortAug => 'Août';

  @override
  String get monthShortSep => 'Sept.';

  @override
  String get monthShortOct => 'Oct.';

  @override
  String get monthShortNov => 'Nov.';

  @override
  String get monthShortDec => 'Déc.';

  @override
  String get january => 'Janvier';

  @override
  String get february => 'Février';

  @override
  String get march => 'Mars';

  @override
  String get april => 'Avril';

  @override
  String get may => 'Mai';

  @override
  String get june => 'Juin';

  @override
  String get july => 'Juillet';

  @override
  String get august => 'Août';

  @override
  String get september => 'Septembre';

  @override
  String get october => 'Octobre';

  @override
  String get november => 'Novembre';

  @override
  String get december => 'Décembre';

  @override
  String get switchedToGeneral => 'Basculé vers les leçons générales (mondiales)';

  @override
  String get shareLesson => 'Partager leçon';

  @override
  String get readingStreak => 'Série de lecture';

  @override
  String get todaysReading => 'Lecture du jour:';

  @override
  String get noReading => 'Aucune lecture';

  @override
  String get completeReading => 'Lecture complète';

  @override
  String readingTimer(Object remainingSeconds) {
    return 'Avant la série… ($remainingSeconds s)';
  }

  @override
  String get memoryVerse => 'Verset mémorisé:';

  @override
  String get prayer => 'Prière';

  @override
  String get noBookmarksYet => 'Aucun signet pour le moment';

  @override
  String get signInToSaveFavorites => 'Connectez-vous pour enregistrer vos favoris';

  @override
  String get bookmarksSyncMessage => 'Les signets, les leçons et les lectures se synchronisent sur tous vos appareils.';

  @override
  String get english => 'English';

  @override
  String get francais => 'Français';

  @override
  String get copied => 'Copié!';

  @override
  String get invalidSavedLessonId => 'ID de leçon enregistrée invalide';

  @override
  String get lessonNotFound => 'Leçon non trouvée';

  @override
  String get savedLessonContentNotAvailable => 'Le contenu de la leçon enregistrée n\'est pas disponible';

  @override
  String get pleaseAddAComment => 'Veuillez ajouter un commentaire';

  @override
  String get thankYouFeedbackSubmitted => 'Merci! Commentaires soumis.';

  @override
  String errorSharingChurch(Object error) {
    return 'Erreur lors du partage de l\'église: $error';
  }

  @override
  String get youHaveLeftTheChurch => 'Vous avez quitté l\'église';

  @override
  String get pleaseLogInToViewAssignments => 'Veuillez vous connecter pour voir vos devoirs';

  @override
  String get teenResponses => 'Réponses adolescents';

  @override
  String get adultResponses => 'Réponses adultes';

  @override
  String get editResponses => 'Modifier les réponses';

  @override
  String yourScore(Object score, Object total) {
    return 'Votre score: $score / $total';
  }

  @override
  String get myResponses => 'Mes réponses:';

  @override
  String get assignmentGradedToast => 'Votre assignment a été évalué !';

  @override
  String get yourSubmittedResponses => 'Vos réponses soumises';

  @override
  String get assignmentGraded => 'Devoir noté.';

  @override
  String get gradedNoEdit => 'Noté — non modifiable';

  @override
  String get noQuestionAvailable => 'Aucune question disponible.';

  @override
  String get noQuestionAvailableForThisDay => 'Aucune question aujourd’hui.';

  @override
  String get myAssignment => 'Mon devoir';

  @override
  String get thisWeeksAssignment => 'Devoir de la semaine';

  @override
  String dueDateFormatted(Object dateFormatted) {
    return 'À rendre : $dateFormatted';
  }

  @override
  String get gradedByTeacher => 'Noté par l’enseignant';

  @override
  String get teachersFeedback => 'Commentaires :';

  @override
  String get noTeacherFeedbackProvided => 'Aucun commentaire.';

  @override
  String get submittedTapEditToChange => 'Envoyé — Modifier';

  @override
  String get writeYourResponseHere => 'Écrivez la réponse …';

  @override
  String get submit => 'Envoyer';

  @override
  String get loadingQuestion => 'Chargement…';

  @override
  String get teenOrAdultResponses => 'Réponses';

  @override
  String get question => 'Question';

  @override
  String get submissions => 'Soumissions';

  @override
  String answerWithIndex(Object i, Object answer) {
    return 'Réponse $i : $answer';
  }

  @override
  String get reset => 'Réinitialiser';

  @override
  String get grade => 'Noter';

  @override
  String get teenSundaySchoolLesson => 'Leçon d\'école du dimanche pour adolescents';

  @override
  String get adultSundaySchoolLesson => 'Leçon d\'école du dimanche pour adultes';

  @override
  String get youWillBeSignedOut => 'Vous serez déconnecté et revenir à l\'écran de connexion.';

  @override
  String get leaveWithoutJoining => 'Partir sans rejoindre?';

  @override
  String get setUpYourParish => 'Configurez votre paroisse et devenez son administrateur';

  @override
  String get enterSixDigitCode => 'Entrez le code à 6 chiffres fourni par l\'administrateur de votre paroisse';

  @override
  String copiedHex(Object hex) {
    return 'Copié: $hex';
  }

  @override
  String get rccgSundaySchoolGeneral => 'École du dimanche RCCG (Générale)';

  @override
  String get savedItems => 'Éléments enregistrés';

  @override
  String errorLoadingData(Object error) {
    return 'Erreur: $error';
  }

  @override
  String get noRankingsYet => 'Pas encore de classement dans cette catégorie.';

  @override
  String get couldNotDetermineBook => 'Impossible de déterminer le livre ou le chapitre';

  @override
  String get bookNotFoundInBibleVersion => 'Le livre n\'a pas été trouvé dans la version actuelle de la Bible';

  @override
  String get signInAndJoinToBookmarks => 'Connectez-vous et rejoignez une église pour enregistrer les signets';

  @override
  String get bookmarkRemoved => 'Signet supprimé';

  @override
  String get bookmarked => 'Marqué';

  @override
  String get pleaseSelectChurchFirst => 'Veuillez d\'abord sélectionner votre église!';

  @override
  String get couldNotSendRequest => 'Impossible d\'envoyer la demande';

  @override
  String thankYouPastor(Object name) {
    return 'Merci, $name!';
  }

  @override
  String get createYourChurch => 'Créez votre église';

  @override
  String get pleaseFillAllRequiredFields => 'Veuillez remplir tous les champs requis';

  @override
  String get leaveChurchMessage => 'Vous ne serez plus connecté à cette église.';

  @override
  String get cancel => 'Annuler';

  @override
  String get accessRestricted => 'Accès restreint';

  @override
  String get manageChurchSettings => 'Gérer les paramètres de l\'église';

  @override
  String get askYourPastor => 'Demandez le code à votre pasteur';

  @override
  String get primaryColors => 'Couleurs principales';

  @override
  String get secondaryColors => 'Couleurs secondaires';

  @override
  String get neutralAndBackground => 'Neutre et arrière-plan';

  @override
  String get statusColors => 'Couleurs d\'état';

  @override
  String get greyScale => 'Échelle de gris';

  @override
  String get darkTheme => 'Thème sombre';

  @override
  String get members => 'Membres';

  @override
  String get lessonCompletion => 'Complétion des leçons';

  @override
  String get dailyActive => 'Actifs quotidiens';

  @override
  String get weeklyActive => 'Actifs hebdomadaires';

  @override
  String get activity => 'Activité (7 derniers jours)';

  @override
  String get lessonProgress => 'Progrès des leçons';

  @override
  String get alertsAndHighlights => 'Alertes et mises en évidence';

  @override
  String get testNotificationScheduled => 'Notification de test programmée dans 30 secondes!';

  @override
  String get exactTimingDenied => 'Le minutage exact a été refusé. Le rappel sera approximatif.';

  @override
  String get addItem => 'Ajouter un élément';

  @override
  String get yoruba => 'Yoruba';

  @override
  String get navHome => 'Accueil';

  @override
  String get navBible => 'Bible';

  @override
  String get navAccount => 'Compte';

  @override
  String get pleaseLogInToViewStreak => 'Veuillez vous connecter pour voir votre série.';

  @override
  String get offlineMode => 'Mode hors ligne • Utilisation des leçons en cache';

  @override
  String get newLesson => 'Nouvelle leçon!';

  @override
  String get openButton => 'OUVRIR';

  @override
  String get leaveButton => 'Quitter';

  @override
  String get leaveChurchDialog => 'Quitter l\'église?';

  @override
  String get oldTestament => 'Ancien Testament';

  @override
  String get newTestament => 'Nouveau Testament';

  @override
  String get updateAvailable => 'Mise à jour disponible !';

  @override
  String get updateMessage => 'Une nouvelle version est prête avec des améliorations et des corrections.\nLa télécharger maintenant ?';

  @override
  String get later => 'Plus tard';

  @override
  String get updateNow => 'Mettre à jour';

  @override
  String get invalidSixDigitCode => 'Veuillez entrer un code valide à 6 chiffres';

  @override
  String get invalidServerResponse => 'Réponse du serveur invalide';

  @override
  String get failedToJoinChurch => 'Impossible de rejoindre l’église';

  @override
  String get signOutWarning => 'Vous serez déconnecté et renvoyé à l’écran de connexion.';

  @override
  String get stay => 'Rester';

  @override
  String get welcome => 'Bienvenue !';

  @override
  String get connectToChurch => 'Connectons-vous à votre église';

  @override
  String get joinParish => 'Rejoindre une paroisse';

  @override
  String get enterChurchCode => 'Entrer le code de l’église';

  @override
  String get askPastorForCode => 'Demandez le code à votre pasteur';

  @override
  String get mustBeSignedIn => 'Vous devez être connecté';

  @override
  String get requestSent => 'Demande envoyée !';

  @override
  String requestSummary(Object churchName, Object parishName, Object country) {
    return 'Votre demande de création :\n\n🏛️ \$churchName\n📍 \$parishName\n🌍 \$country\n\na été envoyée.';
  }

  @override
  String get approvalNotice => 'Vous recevrez une notification dans les 24 heures après approbation.';

  @override
  String get gotIt => 'D’accord !';

  @override
  String get churchAlreadyExists => 'Une église portant ce nom existe déjà. Veuillez contacter le support.';

  @override
  String genericError(Object toString) {
    return 'Erreur : $toString';
  }

  @override
  String get churchInformation => 'Informations sur l’église';

  @override
  String get parishName => 'Nom de la paroisse / branche *';

  @override
  String get adminEmail => 'Email de l’administrateur *';

  @override
  String get addressOptional => 'Adresse (facultatif)';

  @override
  String get country => 'Pays *';

  @override
  String get submitRequest => 'Envoyer la demande';

  @override
  String get bibleGenesis => 'Genèse';

  @override
  String get bibleExodus => 'Exode';

  @override
  String get bibleLeviticus => 'Lévitique';

  @override
  String get bibleNumbers => 'Nombres';

  @override
  String get bibleDeuteronomy => 'Deutéronome';

  @override
  String get bibleJoshua => 'Josué';

  @override
  String get bibleJudges => 'Juges';

  @override
  String get bibleRuth => 'Ruth';

  @override
  String get bible1Samuel => '1 Samuel';

  @override
  String get bible2Samuel => '2 Samuel';

  @override
  String get bible1Kings => '1 Rois';

  @override
  String get bible2Kings => '2 Rois';

  @override
  String get bible1Chronicles => '1 Chroniques';

  @override
  String get bible2Chronicles => '2 Chroniques';

  @override
  String get bibleEzra => 'Esdras';

  @override
  String get bibleNehemiah => 'Néhémie';

  @override
  String get bibleEsther => 'Esther';

  @override
  String get bibleJob => 'Job';

  @override
  String get biblePsalms => 'Psaumes';

  @override
  String get bibleProverbs => 'Proverbes';

  @override
  String get bibleEcclesiastes => 'Ecclésiaste';

  @override
  String get bibleSongOfSolomon => 'Cantique des Cantiques';

  @override
  String get bibleIsaiah => 'Ésaïe';

  @override
  String get bibleJeremiah => 'Jérémie';

  @override
  String get bibleLamentations => 'Lamentations';

  @override
  String get bibleEzekiel => 'Ézéchiel';

  @override
  String get bibleDaniel => 'Daniel';

  @override
  String get bibleHosea => 'Osée';

  @override
  String get bibleJoel => 'Joël';

  @override
  String get bibleAmos => 'Amos';

  @override
  String get bibleObadiah => 'Abdias';

  @override
  String get bibleJonah => 'Jonas';

  @override
  String get bibleMicah => 'Michée';

  @override
  String get bibleNahum => 'Nahum';

  @override
  String get bibleHabakkuk => 'Habakuk';

  @override
  String get bibleZephaniah => 'Sophonie';

  @override
  String get bibleHaggai => 'Aggée';

  @override
  String get bibleZechariah => 'Zacharie';

  @override
  String get bibleMalachi => 'Malachie';

  @override
  String get bibleMatthew => 'Matthieu';

  @override
  String get bibleMark => 'Marc';

  @override
  String get bibleLuke => 'Luc';

  @override
  String get bibleJohn => 'Jean';

  @override
  String get bibleActs => 'Actes';

  @override
  String get bibleRomans => 'Romains';

  @override
  String get bible1Corinthians => '1 Corinthiens';

  @override
  String get bible2Corinthians => '2 Corinthiens';

  @override
  String get bibleGalatians => 'Galates';

  @override
  String get bibleEphesians => 'Éphésiens';

  @override
  String get biblePhilippians => 'Philippiens';

  @override
  String get bibleColossians => 'Colossiens';

  @override
  String get bible1Thessalonians => '1 Thessaloniciens';

  @override
  String get bible2Thessalonians => '2 Thessaloniciens';

  @override
  String get bible1Timothy => '1 Timothée';

  @override
  String get bible2Timothy => '2 Timothée';

  @override
  String get bibleTitus => 'Tite';

  @override
  String get biblePhilemon => 'Philémon';

  @override
  String get bibleHebrews => 'Hébreux';

  @override
  String get bibleJames => 'Jacques';

  @override
  String get bible1Peter => '1 Pierre';

  @override
  String get bible2Peter => '2 Pierre';

  @override
  String get bible1John => '1 Jean';

  @override
  String get bible2John => '2 Jean';

  @override
  String get bible3John => '3 Jean';

  @override
  String get bibleJude => 'Jude';

  @override
  String get bibleRevelation => 'Apocalypse';

  @override
  String get copy => 'Copier';

  @override
  String get share => 'Partager';

  @override
  String get bookmark => 'Signet';

  @override
  String get removeHighlight => 'Supprimer la surbrillance';

  @override
  String get verseSelected => 'verset sélectionné';

  @override
  String get versesSelected => 'versets sélectionnés';

  @override
  String get advertsDisclosure => 'Les annonces financent l\'application et la maintenance du serveur, pour votre plaisir.';

  @override
  String get inviteYourFriends => 'Inviter vos amis';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get pleaseAddComment => 'Veuillez ajouter un commentaire';

  @override
  String get feedbackSubmitted => 'Merci ! Vos commentaires ont été soumis.';

  @override
  String get yourSuggestions => 'Vos suggestions';

  @override
  String get suggestionsHelpApp => 'Vos suggestions améliorent l\'application pour tous !';

  @override
  String get tellUsWhatYouThink => 'Dites-nous ce que vous pensez...';

  @override
  String get submitFeedback => 'Soumettre les commentaires';

  @override
  String get rateAppSettings => 'Salut... Pour évaluer l\'application, veuillez aller dans Paramètres ...';

  @override
  String get pleaseSignInStreak => 'Veuillez vous connecter pour voir votre série.';

  @override
  String get dayStreak => 'jour de série';

  @override
  String get freezesAvailable => 'Gels disponibles';

  @override
  String get freezesDescription => 'Les gels vous permettent de sauter un jour sans casser votre série.';

  @override
  String get lastCompleted => 'Dernier réalisé';

  @override
  String get never => 'Jamais';

  @override
  String get progressNextFreeze => 'Progression vers le gel suivant';

  @override
  String get daysUntilNextFreeze => 'jour(s) jusqu\'au gel suivant.';

  @override
  String get howFreezesWork => 'Comment fonctionnent les gels';

  @override
  String get freezeExplanation => 'Si vous manquez un jour, un gel sera consommé pour maintenir votre série.';

  @override
  String get savedItemsTitle => 'Éléments enregistrés';

  @override
  String get noBookmarksYetMessage => 'Aucun signet pour le moment';

  @override
  String get saveFavoriteScriptures => 'Enregistrez vos versets préférés pour les lire à tout moment.';

  @override
  String get deleteBookmark => 'Supprimer le signet';

  @override
  String get yourNote => 'Votre note';

  @override
  String get noSavedLessons => 'Aucune leçon enregistrée';

  @override
  String get saveLessonsToReview => 'Enregistrez les leçons pour les consulter plus tard.';

  @override
  String get openLesson => 'Ouvrir la leçon';

  @override
  String get deleteLesson => 'Supprimer la leçon';

  @override
  String get noteLabel => 'Note';

  @override
  String get noFurtherReadings => 'Aucune lecture complémentaire';

  @override
  String get saveReadingMaterials => 'Enregistrez les documents de lecture pour les explorer plus tard.';

  @override
  String get deleteReading => 'Supprimer la lecture';

  @override
  String get lessons => 'Leçons';

  @override
  String get readings => 'Lectures';

  @override
  String get adult => 'Adulte';

  @override
  String get teen => 'Adolescent';

  @override
  String get church => 'Église';

  @override
  String get global => 'Mondial';

  @override
  String get errorWithMessage => 'Erreur :';

  @override
  String get yourRank => 'Votre rang :';

  @override
  String get anonymousStudent => 'Étudiant anonyme';

  @override
  String get pointsLabel => 'pts';

  @override
  String get refreshAssignments => 'Actualiser les devoirs';

  @override
  String get empty => 'Vide!';

  @override
  String get noAssignmentsInQuarter => 'Aucun devoir dans ce trimestre.';

  @override
  String get myAssignments => 'Mes Devoirs';
}
