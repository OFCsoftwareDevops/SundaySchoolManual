// ── AGE GROUP ──
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum AgeGroup { teen, adult }

AgeGroup getCurrentAgeGroup() {
  final box = Hive.box('settings');
  final saved = box.get('selected_age_group', defaultValue: 'adult') as String;
  return saved == 'teen' ? AgeGroup.teen : AgeGroup.adult;
}

String ageGroupToFirestoreField(AgeGroup group) => group == AgeGroup.teen ? 'teen' : 'adult';

// ── LANGUAGE ──
String getCurrentLang(BuildContext? context) {
  if (context == null) {
    // During preload: use saved language from Hive (or English)
    final box = Hive.box('settings');
    final saved = box.get('preferred_language') as String?;
    if (saved != null && ['en', 'fr', 'yo'].contains(saved)) {
      return saved;
    }
    return 'en';
  }

  // Normal usage → use real context language
  final code = Localizations.localeOf(context).languageCode;
  // Fallback to English if language is not supported
  if (['en', 'fr', 'yo'].contains(code)) {
    return code;
  }
  return 'en';
}