import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LanguageService {
  static const String _boxName = 'settings';
  static const String _key = 'preferred_language';

  /// Returns the language to use right now
  /// Priority: saved → device locale → 'en'
  static String getCurrentLanguage() {
    final box = Hive.box(_boxName);
    final saved = box.get(_key) as String?;

    if (saved != null && ['en', 'fr'/*, 'yo'*/].contains(saved)) {
      return saved;
    }

    return 'en'; // default for preload & first launch
  }

  /// Save user choice
  static Future<void> saveLanguage(String langCode) async {
    final box = Hive.box(_boxName);
    await box.put(_key, langCode);
  }

  /// Only call this when you have BuildContext
  static String getLanguageFromContext(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return ['en', 'fr'/*, 'yo'*/].contains(code) ? code : 'en';
  }
}