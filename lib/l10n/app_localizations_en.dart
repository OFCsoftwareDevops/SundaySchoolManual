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
  String get sundaySchoolLesson => 'Sunday School Lesson';

  @override
  String get noLessonToday => 'No Lesson Available Today';

  @override
  String get noTeenLesson => 'No Teen Lesson available';

  @override
  String get noAdultLesson => 'No Adult Lesson available';
}
