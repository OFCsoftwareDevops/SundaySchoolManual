import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BibleBook {
  final String name;
  final List<List<Map<String, dynamic>>> chapters;

  BibleBook({required this.name, required this.chapters});
}

class BibleVersionManager extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _currentVersion = 'kjv';
  String get currentVersion => _currentVersion;

  List<Map<String, dynamic>> _loadedBooks = [];
  bool _hasInitialLoad = false;

  final List<Map<String, String>> availableVersions = [
    {'code': 'web', 'name': 'World English Bible'},
    {'code': 'kjv', 'name': 'King James Version'},
  ];

  // SINGLE SOURCE OF TRUTH
  List<Map<String, dynamic>> get books => _loadedBooks;

  // Called once at startup
  Future<void> loadInitialBible() async {
    if (_hasInitialLoad) return;
    _hasInitialLoad = true;

    _isLoading = true;
    scheduleMicrotask(notifyListeners);

    _loadedBooks = await _loadBibleVersion(_currentVersion);
    _isLoading = false;
    scheduleMicrotask(notifyListeners);
  }

  // Called when user changes version
  Future<void> changeVersion(String newVersion) async {
    if (newVersion == _currentVersion) return;
    _isLoading = true;
    scheduleMicrotask(notifyListeners);

    _currentVersion = newVersion;
    _loadedBooks = await _loadBibleVersion(newVersion);

    _isLoading = false;
    scheduleMicrotask(notifyListeners);
  }

  // Core loading logic — used by both initial load and version switch
  Future<List<Map<String, dynamic>>> _loadBibleVersion(String version) async {
    // Check in-memory cache first
    if (_versionCache.containsKey(version)) {
      return _versionCache[version]!;
    }

    // Load, parse, cache in-memory
    final loaded = <Map<String, dynamic>>[];

    final files = [
      'genesis.json', 'exodus.json', 'leviticus.json', 'numbers.json', 'deuteronomy.json',
      'joshua.json', 'judges.json', 'ruth.json', '1samuel.json', '2samuel.json',
      '1kings.json', '2kings.json', '1chronicles.json', '2chronicles.json',
      'ezra.json', 'nehemiah.json', 'esther.json', 'job.json', 'psalms.json',
      'proverbs.json', 'ecclesiastes.json', 'songofsolomon.json',
      'isaiah.json', 'jeremiah.json', 'lamentations.json', 'ezekiel.json', 'daniel.json',
      'hosea.json', 'joel.json', 'amos.json', 'obadiah.json', 'jonah.json',
      'micah.json', 'nahum.json', 'habakkuk.json', 'zephaniah.json',
      'haggai.json', 'zechariah.json', 'malachi.json',
      'matthew.json', 'mark.json', 'luke.json', 'john.json', 'acts.json',
      'romans.json', '1corinthians.json', '2corinthians.json',
      'galatians.json', 'ephesians.json', 'philippians.json', 'colossians.json',
      '1thessalonians.json', '2thessalonians.json', '1timothy.json', '2timothy.json',
      'titus.json', 'philemon.json', 'hebrews.json', 'james.json',
      '1peter.json', '2peter.json', '1john.json', '2john.json', '3john.json',
      'jude.json', 'revelation.json',
    ];



    for (final file in files) {
      final path = 'assets/bible/$version/$file';
      String name = file.replaceAll('.json', '').replaceAll('_', ' ').split(' ').map((w) {
        if (w.length <= 3) return w[0].toUpperCase() + w.substring(1);
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      }).join(' ');

      try {
        final raw = await rootBundle.loadString(path);
        final data = json.decode(raw);

        final chapters = <List<Map<String, dynamic>>>[];

        if (data is List) {
          // WEB format
          final map = <int, List<Map<String, dynamic>>>{};
          int currentChapter = 1;
          int? currentVerse;
          final buffer = StringBuffer();

          for (var item in data) {
            if (item is! Map) continue;
            if (!['paragraph text', 'verse'].contains(item['type'])) continue;

            final ch = (item['chapterNumber'] as num?)?.toInt() ?? currentChapter;
            final verse = (item['verseNumber'] as num?)?.toInt();
            final text = (item['value'] ?? item['text'] ?? '').toString().trim();

            if (verse != null) {
              if (currentVerse != null && buffer.isNotEmpty) {
                map.putIfAbsent(currentChapter, () => []).add({
                  'verse': currentVerse,
                  'text': buffer.toString().trim(),
                });
                buffer.clear();
              }
              currentChapter = ch;
              currentVerse = verse;
              buffer.write(text);
            } else if (currentVerse != null) {
              buffer.write(' $text');
            }
          }
          if (currentVerse != null && buffer.isNotEmpty) {
            map.putIfAbsent(currentChapter, () => []).add({
              'verse': currentVerse,
              'text': buffer.toString().trim(),
            });
          }
          for (final key in map.keys.toList()..sort()) {
            chapters.add(map[key]!);
          }
        } else if (data is Map && data.containsKey('chapters')) {
          // KJV format
          for (var chap in data['chapters']) {
            if (chap is! Map) continue;
            final verses = <Map<String, dynamic>>[];
            for (var v in chap['verses'] ?? []) {
              if (v is Map) {
                final verse = int.tryParse(v['verse'].toString()) ?? 1;
                final text = (v['text'] as String?)?.trim() ?? '';
                if (text.isNotEmpty) verses.add({'verse': verse, 'text': text});
              }
            }
            verses.sort((a, b) => (a['verse'] as int).compareTo(b['verse'] as int));
            chapters.add(verses);
          }
        }

        if (chapters.isNotEmpty) {
          loaded.add({'name': name, 'chapters': chapters});
        }
      } catch (e) {
        // Skip missing files (e.g. NT in KJV)
      }
    }

    _versionCache[version] = loaded; // Cache in-memory
    return loaded;
  }

  static final Map<String, List<Map<String, dynamic>>> _versionCache = {};

  dynamic getCurrentChapterData(String bookName, int chapterNum) {
    try {
      final book = _loadedBooks.firstWhere((b) => b['name'] == bookName);
      final chapters = book['chapters'] as List;
      return chapters[chapterNum - 1];
    } catch (_) {
      return null;
    }
  }
}

/*import 'package:flutter/material.dart';

import 'bible_page.dart';

class BibleBook {
  final String name;
  final List<BibleChapter> chapters;

  BibleBook({required this.name, required this.chapters});

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    var chaptersList = json['chapters'] as List;
    return BibleBook(
      name: json['name'],
      chapters: chaptersList.map((c) => BibleChapter.fromJson(c)).toList(),
    );
  }
}

class BibleChapter {
  final int chapter;
  final List<BibleVerse> verses;

  BibleChapter({required this.chapter, required this.verses});

  factory BibleChapter.fromJson(Map<String, dynamic> json) {
    var versesList = json['verses'] as List;
    return BibleChapter(
      chapter: json['chapter'],
      verses: versesList.map((v) => BibleVerse.fromJson(v)).toList(),
    );
  }
}

class BibleVerse {
  final int verse;
  final String text;

  BibleVerse({required this.verse, required this.text});

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      verse: json['verse'],
      text: json['text'].toString().trim(),
    );
  }
}

// ADD THIS CLASS AT THE VERY BOTTOM OF YOUR FILE
class BibleVersionManager extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _hasLoadedInitial = false;

  String _currentVersion = 'kjv';
  String get currentVersion => _currentVersion;

  // THIS IS NOW THE SINGLE SOURCE OF TRUTH
  List<Map<String, dynamic>> _loadedBooks = [];

  final List<Map<String, String>> availableVersions = [
    {'code': 'web', 'name': 'World English Bible'},
    {'code': 'kjv', 'name': 'King James Version'},
    // Add more anytime
  ];

  // Called from BiblePage after it finishes loading
  void setLoadedBooks(List<Map<String, dynamic>> books) {
    _loadedBooks = books;
    notifyListeners();
  }

  Future<void> loadInitialBible() async {
    if (_hasLoadedInitial) return;
    _hasLoadedInitial = true;

    _isLoading = true;
    notifyListeners();

    await _loadAllBooksFromAssets(); // ← Put your full loadAllBooks() logic here

    _loadedBooks = _lastLoadedBooks; // or however you store it
    _isLoading = false;
    notifyListeners();
  }
  
  dynamic getCurrentChapterData(String bookName, int chapterNum) {
    if (_loadedBooks.isEmpty) return null;
    try {
      final book = _loadedBooks.firstWhere((b) => b['name'] == bookName);
      final chapters = book['chapters'] as List;
      return chapters[chapterNum - 1];
    } catch (_) {
      return null;
    }
  }

  /*/ This is the REAL source of truth — the cached Bible from BiblePage
  List<Map<String, dynamic>> get loadedBooks {
    return BiblePageState.cachedBible ?? [];
  }

  dynamic getCurrentChapterData(String bookName, int chapterNum) {
    final books = loadedBooks;
    if (books.isEmpty) return null;

    // Simple manual lookup – no firstWhereOrNull needed
    for (final book in books) {
      if (book['name'] == bookName) {
        final chapters = book['chapters'] as List<dynamic>;
        if (chapterNum > 0 && chapterNum <= chapters.length) {
          return chapters[chapterNum - 1];
        }
        return null;
      }
    }
    return null;
  }*/

  Future<void> changeVersion(String newVersion) async {
    if (newVersion == _currentVersion) return;

    _isLoading = true;           // ← add
    notifyListeners();

    _currentVersion = newVersion;
    _loadedBooks = []; // immediately clear old data
    notifyListeners();

    /*_currentVersion = newVersion;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 100)); // optional
    _isLoading = false;          // ← add
    notifyListeners(); */       // ← add
  }
}*/