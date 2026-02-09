import 'package:hive_flutter/hive_flutter.dart';

import '../../database/lesson_data.dart';

class HiveBoxes {
  static const lessonsCache         = 'lessons_cache';
  static const assignmentsCache     = 'assignments_cache';
  static const furtherReadingsCache = 'further_readings_cache';
  static const bookmarksCache       = 'bookmarks_cache';
  static const userCache            = 'user_cache';

  static Box<LessonDay> get lessons       => Hive.box<LessonDay>(lessonsCache);
  static Box<LessonDay> get assignments   => Hive.box<LessonDay>(assignmentsCache);
  static Box<dynamic>    get furtherReadings => Hive.box(furtherReadingsCache);
  static Box<dynamic>   get bookmarks     => Hive.box(bookmarksCache);
  static Box<dynamic>   get userBox       => Hive.box(userCache);
}

class UserCacheKeys {
  static String prefix(String uid, String name) => '${name}_$uid';

  // Bookmarks (full list)
  static String bookmarks(String uid) => prefix(uid, 'bookmarks');

  // Profile basics
  static String photo(String uid)    => prefix(uid, 'profile_photo');
  static String displayName(String uid) => prefix(uid, 'profile_display_name');
  static String email(String uid)    => prefix(uid, 'profile_email');
  static String uidCheck(String uid) => prefix(uid, 'profile_uid'); // optional sanity check

  // If you later cache user responses or other per-user data:
  // static String responses(String uid)   => prefix(uid, 'responses_all');
  // static String responseForDate(String uid, String dateStr) => '${prefix(uid, 'response')}_$dateStr';
}

class HiveHelper {
  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(LessonDayAdapter());
    Hive.registerAdapter(SectionNotesAdapter());
    Hive.registerAdapter(ContentBlockAdapter());

    await Future.wait([
      Hive.openBox<LessonDay>(HiveBoxes.lessonsCache),
      Hive.openBox<LessonDay>(HiveBoxes.assignmentsCache),
      Hive.openBox(HiveBoxes.furtherReadingsCache),
      Hive.openBox<dynamic>(HiveBoxes.bookmarksCache),
      Hive.openBox<dynamic>(HiveBoxes.userCache),
      Hive.openBox('settings'),
    ]);
  }

  static Future<void> clearUserData() async {
    await HiveBoxes.bookmarks.clear();
    await HiveBoxes.userBox.clear();
  }
}