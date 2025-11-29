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
  String get sundaySchoolLesson => 'Leçon d’école du dimanche';

  @override
  String get noLessonToday => 'Aucune leçon aujourd’hui';

  @override
  String get noTeenLesson => 'Aucune leçon pour les adolescents';

  @override
  String get noAdultLesson => 'Aucune leçon pour les adultes';
}
