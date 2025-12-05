// lib/services/last_position_manager.dart
import 'package:shared_preferences/shared_preferences.dart';

class LastPositionManager {
  static const String _keyBook = 'last_book';
  static const String _keyChapter = 'last_chapter';
  static const String _keyScreen = 'last_screen'; // "home", "book_grid", "chapter"

  // Save current position
  static Future<void> save({
    required String bookName,
    required int chapter,
    required String screen, // "home" | "book_grid" | "chapter"
  }) async {
    print('🗂️ SAVING: book=$bookName, chapter=$chapter, screen=$screen'); // ← ADD THIS
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBook, bookName);
    await prefs.setInt(_keyChapter, chapter);
    await prefs.setString(_keyScreen, screen);
    print('✅ SAVE COMPLETE: Data written to prefs'); // ← ADD THIS
  }

  // Get last position (returns null on first launch)
  static Future<Map<String, dynamic>?> getLast() async {
    print('📂 LOADING: Checking for saved data...'); // ← ADD THIS
    final prefs = await SharedPreferences.getInstance();
    final hasData = prefs.containsKey(_keyBook) &&
        prefs.containsKey(_keyChapter) &&
        prefs.containsKey(_keyScreen);

    if (!hasData) {
      print('❌ NO SAVED DATA FOUND'); // ← ADD THIS
      return null;
    }

    final data = {
      'book': prefs.getString(_keyBook)!,
      'chapter': prefs.getInt(_keyChapter)!,
      'screen': prefs.getString(_keyScreen)!,
    };
    print('✅ LOADED: $data'); // ← ADD THIS
    return data;
  }

  // Optional: reset to Genesis (e.g. for a "Start Over" button later)
  static Future<void> resetToGenesis() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBook);
    await prefs.remove(_keyChapter);
    await prefs.remove(_keyScreen);
  }
}