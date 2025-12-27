// lib/services/last_position_manager.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LastPositionManager {
  static const String _keyBook = 'last_book';
  static const String _keyChapter = 'last_chapter';
  static const String _keyVerse = 'last_verse';
  static const String _keyScreen = 'last_screen'; // "home", "book_grid", "chapter"

  // Save current position
  static Future<void> save({
    required String screen, // "home", "book_grid", "chapter"
    String? bookName,
    int? chapter,
    int? verse,
  }) async {

    if (kDebugMode) {
      print('🗂️ SAVING POSITION: screen=$screen, book=$bookName, chapter=$chapter, verse=$verse');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyScreen, screen);
    if (bookName != null) await prefs.setString(_keyBook, bookName);
    if (chapter != null) await prefs.setInt(_keyChapter, chapter);
    if (verse != null) await prefs.setInt(_keyVerse, verse);

    if (kDebugMode) {
      print('✅ SAVE COMPLETE: Data written to prefs');
    }
  }

  // Get last position (returns null on first launch)
  static Future<Map<String, dynamic>?> getLast() async {
    if (kDebugMode) print('📂 LOADING last position...');

    final prefs = await SharedPreferences.getInstance();
    final screen = prefs.getString(_keyScreen);
    if (screen == null) {
      if (kDebugMode) print('❌ No saved position found');
      return null;
    }

    final data = {
      'screen': screen,
      'book': prefs.getString(_keyBook),
      'chapter': prefs.getInt(_keyChapter),
      'verse': prefs.getInt(_keyVerse),
    };
    if (kDebugMode) print('✅ LOADED: $data');
    return data;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyScreen);
    await prefs.remove(_keyBook);
    await prefs.remove(_keyChapter);
    await prefs.remove(_keyVerse);
  }
}