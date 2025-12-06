import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../SundaySchool_app/bible_ref_parser.dart';
import 'bible_entry_point.dart';

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

      /*String name = file.replaceAll('.json', '').replaceAll('_', ' ').split(' ').map((w) {
        if (w.length <= 3) return w[0].toUpperCase() + w.substring(1);
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      }).join(' ');*/

      // Convert filename to display name with spaces
      String name = file
          .replaceAll('.json', '')
          // insert a space after leading digits (e.g. "1timothy" -> "1 timothy")
          .replaceFirstMapped(RegExp(r'^(\d+)(?=[A-Za-z])'), (m) => '${m[1]} ')
          // replace underscores/dashes with spaces if any
          .replaceAll(RegExp(r'[_\-]+'), ' ')
          // Capitalize words
          .split(' ')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
          .join(' ');

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

  // In your BibleVersionManager class

  String? getVerseText(String reference) {
    print('DEBUG: getVerseText called with: $reference'); // ← add this
    
    final refs = findBibleReferences(reference);
    print('DEBUG: Parsed references: $refs');

    if (refs.isEmpty) {
      print('DEBUG: No references parsed from: "$reference"');
      return null;
    }

    final ref = refs.first;

    print('DEBUG: Using ref - book: "${ref.book}", chapter: ${ref.chapter}, verse: ${ref.verseStart}-${ref.verseEnd}');
    print('DEBUG: Available books: ${books.map((b) => b['name']).toList()}');

    // 1. Find book with super-tolerant matching
    final book = books.firstWhereOrNull((b) {
      final name = (b['name'] as String).toLowerCase();
      final search = ref.book.toLowerCase();
      print('DEBUG: Comparing "$name" with "$search"');

      // Exact match
      if (name == search) return true;

      // Common aliases
      final aliases = {
        'psalm': 'psalms',
        'song of solomon': 'song of songs',
        'song of songs': 'song of solomon',
        'eccles': 'ecclesiastes',
        'rev': 'revelation',
        '1cor': '1 corinthians',
        '2cor': '2 corinthians',
        // add more if you ever see them
      };

      final normalized = aliases[search] ?? search;
      return name.contains(normalized) || normalized.contains(name);
    });

    if (book == null) return null;

    final chapters = book['chapters'] as List;
    if (ref.chapter <= 0 || ref.chapter > chapters.length) {
      return "Chapter ${ref.chapter} does not exist in ${book['name']}.";
    }

    final chapterData = chapters[ref.chapter - 1] as List;
    final int start = ref.verseStart;
    final int end = ref.verseEnd ?? start;

    // Clamp verses to what actually exists
    final int safeStart = start.clamp(1, chapterData.length);
    final int safeEnd = end.clamp(1, chapterData.length);

    if (safeStart > safeEnd) {
      return "No verses found for $reference.";
    }

    final verses = <String>[];
    for (int v = safeStart; v <= safeEnd; v++) {
      final item = chapterData[v - 1];
      final text = item is Map ? item['text'] ?? '' : item.toString();
      if (text.trim().isNotEmpty) {
        verses.add("$v $text".trim());
      }
    }

    return verses.isEmpty ? "Verse(s) not found." : verses.join("\n");
  }
  /*String? getVerseText(String reference) {
    // Example reference: "John 3:16" or "Romans 8:2-4"
    final ref = findBibleReferences(reference).firstOrNull;
    if (ref == null) return null;

    final book = books.firstWhereOrNull((b) => 
      (b['name'] as String).toLowerCase() == ref.book.toLowerCase());
    if (book == null) return null;

    final chapters = book['chapters'] as List;
    if (ref.chapter > chapters.length) return null;

    final chapterData = chapters[ref.chapter - 1] as List;
    final List<String> verses = [];

    int start = ref.verseStart;
    int end = ref.verseEnd ?? start;

    for (int v = start; v <= end; v++) {
      if (v <= chapterData.length) {
        final verse = chapterData[v - 1];
        final text = verse is Map 
        ? verse['text'] ?? '' 
        : verse.toString();
        verses.add("$v ${text.trim()}");
      }
    }

    return verses.join("\n");
  }*/
}