import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../SundaySchool_app/lesson_bible_ref_parser.dart';
import 'bible_entry_point.dart';


class BibleBook {
  final String name;
  final List<List<Map<String, dynamic>>> chapters;

  BibleBook({required this.name, required this.chapters});
}

class BibleVersionManager extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _currentVersion = '';
  String get currentVersion => _currentVersion;

  List<Map<String, dynamic>> _loadedBooks = [];
  bool _hasInitialLoad = false;

  final List<Map<String, String>> availableVersions = [
    {'code': 'kjv', 'name': 'King James Version'},
    {'code': 'asv', 'name': 'American Standard Version'},
    {'code': 'bbe', 'name': 'Bible in Basic English'},
    {'code': 'web', 'name': 'World English Bible'},
    {'code': 'ylt', 'name': 'Youngs Literal Translation'},
    {'code': 'lsg', 'name': 'Louis Segond 1910'},
  ];

  // Map English book names to translation keys
  static const Map<String, String> _bookTranslationKeys = {
    'Genesis': 'bibleGenesis',
    'Exodus': 'bibleExodus',
    'Leviticus': 'bibleLeviticus',
    'Numbers': 'bibleNumbers',
    'Deuteronomy': 'bibleDeuteronomy',
    'Joshua': 'bibleJoshua',
    'Judges': 'bibleJudges',
    'Ruth': 'bibleRuth',
    '1 Samuel': 'bible1Samuel',
    '2 Samuel': 'bible2Samuel',
    '1 Kings': 'bible1Kings',
    '2 Kings': 'bible2Kings',
    '1 Chronicles': 'bible1Chronicles',
    '2 Chronicles': 'bible2Chronicles',
    'Ezra': 'bibleEzra',
    'Nehemiah': 'bibleNehemiah',
    'Esther': 'bibleEsther',
    'Job': 'bibleJob',
    'Psalms': 'biblePsalms',
    'Proverbs': 'bibleProverbs',
    'Ecclesiastes': 'bibleEcclesiastes',
    'Songofsolomon': 'bibleSongOfSolomon',
    'Isaiah': 'bibleIsaiah',
    'Jeremiah': 'bibleJeremiah',
    'Lamentations': 'bibleLamentations',
    'Ezekiel': 'bibleEzekiel',
    'Daniel': 'bibleDaniel',
    'Hosea': 'bibleHosea',
    'Joel': 'bibleJoel',
    'Amos': 'bibleAmos',
    'Obadiah': 'bibleObadiah',
    'Jonah': 'bibleJonah',
    'Micah': 'bibleMicah',
    'Nahum': 'bibleNahum',
    'Habakkuk': 'bibleHabakkuk',
    'Zephaniah': 'bibleZephaniah',
    'Haggai': 'bibleHaggai',
    'Zechariah': 'bibleZechariah',
    'Malachi': 'bibleMalachi',
    'Matthew': 'bibleMatthew',
    'Mark': 'bibleMark',
    'Luke': 'bibleLuke',
    'John': 'bibleJohn',
    'Acts': 'bibleActs',
    'Romans': 'bibleRomans',
    '1 Corinthians': 'bible1Corinthians',
    '2 Corinthians': 'bible2Corinthians',
    'Galatians': 'bibleGalatians',
    'Ephesians': 'bibleEphesians',
    'Philippians': 'biblePhilippians',
    'Colossians': 'bibleColossians',
    '1 Thessalonians': 'bible1Thessalonians',
    '2 Thessalonians': 'bible2Thessalonians',
    '1 Timothy': 'bible1Timothy',
    '2 Timothy': 'bible2Timothy',
    'Titus': 'bibleTitus',
    'Philemon': 'biblePhilemon',
    'Hebrews': 'bibleHebrews',
    'James': 'bibleJames',
    '1 Peter': 'bible1Peter',
    '2 Peter': 'bible2Peter',
    '1 John': 'bible1John',
    '2 John': 'bible2John',
    '3 John': 'bible3John',
    'Jude': 'bibleJude',
    'Revelation': 'bibleRevelation',
  };

  // Get translated book name, falling back to English if translation missing
  static String getTranslatedBookName(String englishName, AppLocalizations? l10n) {
    if (l10n == null) return englishName;
    
    final key = _bookTranslationKeys[englishName];
    if (key == null) return englishName;
    
    // Access the translation via the generated method
    switch (key) {
      case 'bibleGenesis': return l10n.bibleGenesis;
      case 'bibleExodus': return l10n.bibleExodus;
      case 'bibleLeviticus': return l10n.bibleLeviticus;
      case 'bibleNumbers': return l10n.bibleNumbers;
      case 'bibleDeuteronomy': return l10n.bibleDeuteronomy;
      case 'bibleJoshua': return l10n.bibleJoshua;
      case 'bibleJudges': return l10n.bibleJudges;
      case 'bibleRuth': return l10n.bibleRuth;
      case 'bible1Samuel': return l10n.bible1Samuel;
      case 'bible2Samuel': return l10n.bible2Samuel;
      case 'bible1Kings': return l10n.bible1Kings;
      case 'bible2Kings': return l10n.bible2Kings;
      case 'bible1Chronicles': return l10n.bible1Chronicles;
      case 'bible2Chronicles': return l10n.bible2Chronicles;
      case 'bibleEzra': return l10n.bibleEzra;
      case 'bibleNehemiah': return l10n.bibleNehemiah;
      case 'bibleEsther': return l10n.bibleEsther;
      case 'bibleJob': return l10n.bibleJob;
      case 'biblePsalms': return l10n.biblePsalms;
      case 'bibleProverbs': return l10n.bibleProverbs;
      case 'bibleEcclesiastes': return l10n.bibleEcclesiastes;
      case 'bibleSongOfSolomon': return l10n.bibleSongOfSolomon;
      case 'bibleIsaiah': return l10n.bibleIsaiah;
      case 'bibleJeremiah': return l10n.bibleJeremiah;
      case 'bibleLamentations': return l10n.bibleLamentations;
      case 'bibleEzekiel': return l10n.bibleEzekiel;
      case 'bibleDaniel': return l10n.bibleDaniel;
      case 'bibleHosea': return l10n.bibleHosea;
      case 'bibleJoel': return l10n.bibleJoel;
      case 'bibleAmos': return l10n.bibleAmos;
      case 'bibleObadiah': return l10n.bibleObadiah;
      case 'bibleJonah': return l10n.bibleJonah;
      case 'bibleMicah': return l10n.bibleMicah;
      case 'bibleNahum': return l10n.bibleNahum;
      case 'bibleHabakkuk': return l10n.bibleHabakkuk;
      case 'bibleZephaniah': return l10n.bibleZephaniah;
      case 'bibleHaggai': return l10n.bibleHaggai;
      case 'bibleZechariah': return l10n.bibleZechariah;
      case 'bibleMalachi': return l10n.bibleMalachi;
      case 'bibleMatthew': return l10n.bibleMatthew;
      case 'bibleMark': return l10n.bibleMark;
      case 'bibleLuke': return l10n.bibleLuke;
      case 'bibleJohn': return l10n.bibleJohn;
      case 'bibleActs': return l10n.bibleActs;
      case 'bibleRomans': return l10n.bibleRomans;
      case 'bible1Corinthians': return l10n.bible1Corinthians;
      case 'bible2Corinthians': return l10n.bible2Corinthians;
      case 'bibleGalatians': return l10n.bibleGalatians;
      case 'bibleEphesians': return l10n.bibleEphesians;
      case 'biblePhilippians': return l10n.biblePhilippians;
      case 'bibleColossians': return l10n.bibleColossians;
      case 'bible1Thessalonians': return l10n.bible1Thessalonians;
      case 'bible2Thessalonians': return l10n.bible2Thessalonians;
      case 'bible1Timothy': return l10n.bible1Timothy;
      case 'bible2Timothy': return l10n.bible2Timothy;
      case 'bibleTitus': return l10n.bibleTitus;
      case 'biblePhilemon': return l10n.biblePhilemon;
      case 'bibleHebrews': return l10n.bibleHebrews;
      case 'bibleJames': return l10n.bibleJames;
      case 'bible1Peter': return l10n.bible1Peter;
      case 'bible2Peter': return l10n.bible2Peter;
      case 'bible1John': return l10n.bible1John;
      case 'bible2John': return l10n.bible2John;
      case 'bible3John': return l10n.bible3John;
      case 'bibleJude': return l10n.bibleJude;
      case 'bibleRevelation': return l10n.bibleRevelation;
      default: return englishName;
    }
  }

  // SINGLE SOURCE OF TRUTH
  List<Map<String, dynamic>> get books => _loadedBooks;

  String getDefaultVersion() {
    final savedLang = Hive.box('settings').get('preferred_language') as String?;

    // If user saved French → use LSG
    if (savedLang == 'fr') {
      return 'lsg';
    }

    // Everything else → KJV (including no saved value, 'en', or anything else)
    return 'kjv';
  }

  // Called once at startup
  Future<void> loadInitialBible() async {
    if (_hasInitialLoad) return;
    _hasInitialLoad = true;

    _isLoading = true;
    scheduleMicrotask(notifyListeners);

    _currentVersion = getDefaultVersion();

    try {
      _loadedBooks = await _loadBibleVersion(_currentVersion);
    } catch (e, stack) {
      debugPrint('Bible load error: $e\n$stack');
    }

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
    if (kDebugMode) {
      debugPrint('DEBUG: getVerseText called with: $reference');
    } // ← add this
    
    final refs = findBibleReferences(reference);
    if (kDebugMode) {
      debugPrint('DEBUG: Parsed references: $refs');
    }

    if (refs.isEmpty) {
      if (kDebugMode) {
        debugPrint('DEBUG: No references parsed from: "$reference"');
      }
      return null;
    }

    final ref = refs.first;

    if (kDebugMode) {
      debugPrint('DEBUG: Using ref - book: "${ref.book}", chapter: ${ref.chapter}, verse: ${ref.verseStart}-${ref.verseEnd}');
      debugPrint('DEBUG: Available books: ${books.map((b) => b['name']).toList()}');
    }

    // 1. Find book with super-tolerant matching
    final book = books.firstWhereOrNull((b) {
      final name = (b['name'] as String).toLowerCase();
      final search = ref.book.toLowerCase();
      if (kDebugMode) {
        debugPrint('DEBUG: Comparing "$name" with "$search"');
      }

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
}