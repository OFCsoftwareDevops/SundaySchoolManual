// lib/services/current_church.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrentChurch extends ChangeNotifier {
  String? _churchId;
  String? _churchName;

  String? get churchId => _churchId;
  String? get churchName => _churchName;
  bool get isSet => _churchId != null;

  Future<void> setChurch(String id, String name) async {
    _churchId = id;
    _churchName = name;
    notifyListeners();

    // Save to disk
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('church_id', id);
    await prefs.setString('church_name', name);
  }

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
}