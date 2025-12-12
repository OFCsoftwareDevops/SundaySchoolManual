// lib/services/current_church.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrentChurch extends ChangeNotifier {
  String? _churchId;
  String? _churchName;

  String? get churchId => _churchId;
  String? get churchName => _churchName;
  bool get isSet => _churchId != null;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('church_id');
    final name = prefs.getString('church_name');
    if (id != null && name != null) {
      _churchId = id;
      _churchName = name;
      notifyListeners();
    }
  }

  // To save church Id code
  Future<void> setChurch(String id, String name) async {
    _churchId = id;
    _churchName = name;
    notifyListeners();

    // Save to disk
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('church_id', id);
    await prefs.setString('church_name', name);
  }

  // To remove church Id code
  Future<void> clear() async {
    _churchId = null;
    _churchName = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('church_id');
    await prefs.remove('church_name');
  }

  static final CurrentChurch instance = CurrentChurch._internal();
  factory CurrentChurch() => instance;
  CurrentChurch._internal();
  /* SHOW CHURCH NAME IN APP BAR
    Consumer<CurrentChurch>(
    builder: (context, church, child) {
      return AppBar(
        title: Text(church.churchName ?? "Sunday School Manual"),
      );
    },
  )*/
}