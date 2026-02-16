import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsProvider extends ChangeNotifier {
  String? _selectedAgeGroup;
  String _preferredLanguage = 'en'; // default

  SettingsProvider() {
    final box = Hive.box('settings');
    _selectedAgeGroup = box.get('selected_age_group') as String?;
    _preferredLanguage = box.get('preferred_language', defaultValue: 'en') as String;

    // Listen to Hive box changes
    box.watch().listen((event) {
      if (event.key == 'selected_age_group') {
        _selectedAgeGroup = event.value as String?;
        notifyListeners();
      } else if (event.key == 'preferred_language') {
        _preferredLanguage = event.value as String? ?? 'en';
        notifyListeners();
      }
    });
  }

  String get selectedAgeGroup => _selectedAgeGroup ?? 'adult';
  String get preferredLanguage => _preferredLanguage;

  // Optional: methods to update (can call from SettingsScreen)
  Future<void> updateAgeGroup(String group) async {
    final box = Hive.box('settings');
    await box.put('selected_age_group', group);
    // notifyListeners() called automatically via watch
  }

  Future<void> updateLanguage(String lang) async {
    final box = Hive.box('settings');
    await box.put('preferred_language', lang);
    // notifyListeners() called automatically
  }
}