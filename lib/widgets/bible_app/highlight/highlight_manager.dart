// services/highlight_manager.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Highlight {
  final String book;
  final int chapter;
  final int verse;
  final Color color;
  final DateTime timestamp;

  Highlight({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.color,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'book': book,
    'chapter': chapter,
    'verse': verse,
    'color': color.value, // Store as int (ARGB)
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory Highlight.fromJson(Map<String, dynamic> json) => Highlight(
    book: json['book'] as String,
    chapter: json['chapter'] as int,
    verse: json['verse'] as int,
    color: Color(json['color'] as int),
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
  );
}

class HighlightManager extends ChangeNotifier {
  // Private instance
  static final HighlightManager _instance = HighlightManager._internal();
  factory HighlightManager() => _instance;
  HighlightManager._internal();

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // In-memory cache
  final Map<String, Highlight> _highlights = {};

  // Unique key for each verse
  String _key(String book, int chapter, int verse) {
    return "${book}_$chapter:$verse";
  }

  // Public getters
  bool isHighlighted(String book, int chapter, int verse) =>
      _highlights.containsKey(_key(book, chapter, verse));

  Color? getHighlightColor(String book, int chapter, int verse) =>
      _highlights[_key(book, chapter, verse)]?.color;

  List<Highlight> getAllHighlights() => _highlights.values.toList();

  // Add or update highlight
  void addOrUpdateHighlight({
    required String book,
    required int chapter,
    required int verse,
    required Color color,
  }) {
    final key = _key(book, chapter, verse);
    final highlight = Highlight(
      book: book,
      chapter: chapter,
      verse: verse,
      color: color,
      timestamp: DateTime.now(),
    );

    _highlights[key] = highlight;
    notifyListeners();
    _saveToPrefs(); // Auto-save every time
  }

  // Remove highlight
  void removeHighlight(String book, int chapter, int verse) {
    final key = _key(book, chapter, verse);
    if (_highlights.remove(key) != null) {
      notifyListeners();
      _saveToPrefs();
    }
  }

  // Toggle highlight (useful for UI)
  void toggleHighlight({
    required String book,
    required int chapter,
    required int verse,
    required Color color,
  }) {
    if (isHighlighted(book, chapter, verse)) {
      removeHighlight(book, chapter, verse);
    } else {
      addOrUpdateHighlight(book: book, chapter: chapter, verse: verse, color: color);
    }
  }

  // Load from SharedPreferences on app start
  Future<void> loadFromPrefs() async {
    if (_isLoaded) return;
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('user_highlights');

      if (data == null || data.isEmpty) return;

      try {
        final List<dynamic> list = json.decode(data);
        _highlights.clear();
        for (var item in list) {
          final h = Highlight.fromJson(item as Map<String, dynamic>);
          _highlights[_key(h.book, h.chapter, h.verse)] = h;
        }
        notifyListeners();
      } catch (e) {
        debugPrint("Error loading highlights: $e");
      }
    _isLoaded = true;
    notifyListeners();
  }

  // Save to SharedPreferences
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> list =
        _highlights.values.map((h) => h.toJson()).toList();
    await prefs.setString('user_highlights', json.encode(list));
  }

  // Optional: Clear all highlights
  Future<void> clearAll() async {
    _highlights.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_highlights');
  }
}