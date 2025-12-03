import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'bible.dart';

/*extension BiblePageContext on BuildContext {
  _BiblePageState? get bibleState {
    return dependOnInheritedWidgetOfExactType<_BiblePageScope>()?.state;
  }
}

class _BiblePageScope extends InheritedWidget {
  final _BiblePageState state;
  const _BiblePageScope({required this.state, required Widget child}) : super(child: child);

  @override
  bool updateShouldNotify(_BiblePageScope old) => false;
}*/

extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');
  }
}

/*class BiblePage extends StatefulWidget {
  const BiblePage({super.key});
  @override
  State<BiblePage> createState() => BiblePageState();
}

class BiblePageState extends State<BiblePage> {
  //String currentVersion = "web";
  // RAM CACHE — keeps the Bible in memory forever
  static List<Map<String, dynamic>>? cachedBible;
  static bool _hasLoadedOnce = false;
  bool _isFirstLoad = true;
  double _loadProgress = 0.0;
  String _currentBookName = "Preparing the Holy Bible...";
  //VoidCallback? onVersionChanged;

  static final List<Map<String, dynamic>> loaded = [];
  List<Map<String, dynamic>> books = [];
  Map<String, dynamic>? selectedBook;

  @override
  void initState() {
    super.initState();
    // Listen to the GLOBAL version manager (from Provider)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BibleVersionManager>().addListener(_onVersionChanged);
    });

    // Auto-detect preferred version on first launch
    _detectAndSetInitialVersion();
    Future.delayed(const Duration(milliseconds: 300), loadAllBooks);
  }

  @override
  void dispose() {
    // Remove listener safely
    context.read<BibleVersionManager>().removeListener(_onVersionChanged);
    super.dispose();
  }

  void _detectAndSetInitialVersion() async {
    try {
      await rootBundle.loadString('assets/bible/kjv/genesis.json');
      context.read<BibleVersionManager>().changeVersion('kjv');
    } catch (_) {
      context.read<BibleVersionManager>().changeVersion('web');
    }
  }

  void _onVersionChanged() {
    setState(() {
      _isFirstLoad = true;
      cachedBible = null;
      _hasLoadedOnce = false;
      _currentBookName = "Loading Bible...";
    });
    loadAllBooks();
  }

  Future<void> loadAllBooks() async {
    // Use the GLOBAL current version
    final currentVersion = context.read<BibleVersionManager>().currentVersion;
    final bool isLoading = context.read<BibleVersionManager>().isLoading;

    if (_hasLoadedOnce && cachedBible != null && !isLoading) {
      setState(() {
        books = cachedBible!;
        _isFirstLoad = false;
      });
      return;
    }

    setState(() {
      _currentBookName = isLoading
        ? "Switching to ${currentVersion.toUpperCase()}..."
        : "Loading ${currentVersion.toUpperCase()}...";
      _loadProgress = 0.0;
    });

    // HARDCODED LIST — BUT IT'S THE LAST TIME EVER
    final List<String> files = [
      'genesis.json', 'exodus.json', 'leviticus.json', 'numbers.json', 'deuteronomy.json',
      'joshua.json', 'judges.json', 'ruth.json', '1samuel.json', '2samuel.json',
      '1kings.json', '2kings.json', '1chronicles.json', '2chronicles.json',
      'ezra.json', 'nehemiah.json', 'esther.json', 'job.json', 'psalms.json',
      'proverbs.json', 'ecclesiastes.json', 'songofsolomon.json',
      'isaiah.json', 'jeremiah.json', 'lamentations.json', 'ezekiel.json', 'daniel.json',
      'hosea.json', 'joel.json', 'amos.json', 'obadiah.json', 'jonah.json',
      'micah.json', 'nahum.json', 'habakkuk.json', 'zephaniah.json',
      'haggai.json', 'zechariah.json', 'malachi.json',
      // New Testament — ONLY exist in WEB (for now)
      // These will be skipped silently when using KJV
      'matthew.json', 'mark.json', 'luke.json', 'john.json', 'acts.json',
      'romans.json', '1corinthians.json', '2corinthians.json',
      'galatians.json', 'ephesians.json', 'philippians.json', 'colossians.json',
      '1thessalonians.json', '2thessalonians.json', '1timothy.json', '2timothy.json',
      'titus.json', 'philemon.json', 'hebrews.json', 'james.json',
      '1peter.json', '2peter.json', '1john.json', '2john.json', '3john.json',
      'jude.json', 'revelation.json',
    ];

    final List<Map<String, dynamic>> loaded = [];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final path = 'assets/bible/$currentVersion/$file';

      // MAGIC NAME FIX — NO RENAMING EVER AGAIN
      String temp = file.replaceAll('.json', '').replaceAll('.JSON', '');
      String displayName = temp.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim();
      final name = displayName.split(' ').map((w) {
        if (w.isEmpty) return '';
        if (w.length <= 3) return w[0] + w.substring(1); // 1john → 1 John
        return w[0].toUpperCase() + w.substring(1);
      }).join(' ');

      setState(() {
        _currentBookName = "Loading $name...";
        _loadProgress = (i + 1) / files.length;
      });

      try {
        final raw = await rootBundle.loadString(path);
        final data = json.decode(raw);

        final chaptersMap = <int, List<Map<String, dynamic>>>{};
        int currentChapter = 1;
        int? currentVerse;
        final buffer = StringBuffer();

        // SUPPORT BOTH FORMATS
        if (data is List) {
          // WEB FORMAT: List of maps
          for (var item in data) {
            if (item is! Map) continue;

            // Skip headings, etc.
            if (item['type'] != 'paragraph text' && item['type'] != 'verse') continue;

            final ch = (item['chapterNumber'] as num?)?.toInt() ?? currentChapter;
            final verse = (item['verseNumber'] as num?)?.toInt();
            final text = (item['value'] as String? ?? item['text'] as String? ?? '').trim();

            if (verse != null) {
              // Save previous verse
              if (currentVerse != null && buffer.isNotEmpty) {
                chaptersMap.putIfAbsent(currentChapter, () => []).add({
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
        } else if (data is Map) {
          // NEW: Support real KJV format with "chapters" array
          if (data.containsKey('chapters') && data['chapters'] is List) {
            final chaptersList = data['chapters'] as List<dynamic>;
            final chaptersMap = <int, List<Map<String, dynamic>>>{};

            for (var chap in chaptersList) {
              if (chap is! Map) continue;
              
              // Handle chapter as String or int
              final chStr = chap['chapter']?.toString() ?? '1';
              final ch = int.tryParse(chStr) ?? 1;

              final versesList = chap['verses'] as List<dynamic>? ?? [];
              final verseListForChapter = <Map<String, dynamic>>[];

              for (var v in versesList) {
                if (v is! Map) continue;
                final verseNumStr = v['verse']?.toString() ?? '1';
                final verseNum = int.tryParse(verseNumStr) ?? 1;
                final text = (v['text'] as String?)?.trim() ?? '';

                if (text.isNotEmpty) {
                  verseListForChapter.add({'verse': verseNum, 'text': text});
                }
              }

              // Sort verses just in case
              verseListForChapter.sort((a, b) => (a['verse'] as int).compareTo(b['verse'] as int));
              chaptersMap[ch] = verseListForChapter;
            }

            // Convert to sorted chapter list
            final chapters = <List<Map<String, dynamic>>>[];
            for (var key in chaptersMap.keys.toList()..sort()) {
              chapters.add(chaptersMap[key]!);
            }

            loaded.add({'name': name, 'chapters': chapters});
            continue; // skip further processing
          }

          // FALLBACK: Old format with flat "verses" list (keep for backward compat)
          if (data.containsKey('verses')) {
            final verses = data['verses'] as List<dynamic>;
            final chaptersMap = <int, List<Map<String, dynamic>>>{};
            for (var v in verses) {
              if (v is! Map) continue;
              final ch = (v['chapter'] as num?)?.toInt() ?? 1;
              final verse = (v['verse'] as num?)?.toInt() ?? 1;
              final text = (v['text'] as String?)?.trim() ?? '';
              chaptersMap.putIfAbsent(ch, () => []).add({'verse': verse, 'text': text});
            }
            final chapters = <List<Map<String, dynamic>>>[];
            for (var key in chaptersMap.keys.toList()..sort()) {
              chapters.add(chaptersMap[key]!);
            }
            loaded.add({'name': name, 'chapters': chapters});
          }
        }
        /*} else if (data is Map && data.containsKey('verses')) {
          // KJV FORMAT: { "verses": [ { "chapter": 1, "verse": 1, "text": "..." }, ... ] }
          final verses = data['verses'] as List<dynamic>;
          for (var v in verses) {
            if (v is! Map) continue;
            final ch = (v['chapter'] as num?)?.toInt() ?? 1;
            final verse = (v['verse'] as num?)?.toInt() ?? 1;
            final text = (v['text'] as String?)?.trim() ?? '';

            chaptersMap.putIfAbsent(ch, () => []).add({'verse': verse, 'text': text});
          }
        }*/

        // Don't forget last verse!
        if (currentVerse != null && buffer.isNotEmpty) {
          chaptersMap.putIfAbsent(currentChapter, () => []).add({
            'verse': currentVerse,
            'text': buffer.toString().trim(),
          });
        }

        // Convert to sorted list
        final chapters = <List<Map<String, dynamic>>>[];
        for (var key in chaptersMap.keys.toList()..sort()) {
          chapters.add(chaptersMap[key]!);
        }

        loaded.add({'name': name, 'chapters': chapters});
      } catch (e) {
        debugPrint("Failed to load $path: $e");
      }
    }

    cachedBible = loaded;
    _hasLoadedOnce = true;

    /*BiblePageState.loaded.clear();
    BiblePageState.loaded.addAll(loaded);*/
    context.read<BibleVersionManager>().setLoadedBooks(loaded);

    if (mounted) {
      setState(() {
        books = loaded;
        _isFirstLoad = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIRST TIME ONLY — your beautiful loading screen
    if (_isFirstLoad && books.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_rounded, size: 90, color: Color(0xFF5D8668)),
              const SizedBox(height: 50),
              const Text(
                "Preparing the Holy Bible",
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Color(0xFF5D8668)),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 320,
                child: LinearProgressIndicator(
                  value: _loadProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5D8668)),
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "${(_loadProgress * 100).toInt()}%",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF5D8668)),
              ),
              const SizedBox(height: 12),
              Text(
                _currentBookName,
                style: const TextStyle(fontSize: 17, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (selectedBook != null) {
      return BookReader(book: selectedBook!, onBack: () => setState(() => selectedBook = null));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Holy Bible", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: const Color(0xFF5D8668),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Consumer<BibleVersionManager>(
                builder: (context, manager, child) {
                  return manager.isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : DropdownButton<String>(
                          value: manager.currentVersion,
                          dropdownColor: const Color(0xFF5D8668),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          items: manager.availableVersions
                              .map((v) => DropdownMenuItem(value: v['code'], child: Text(v['name']!)))
                              .toList(),
                          onChanged: (v) => v != null ? manager.changeVersion(v) : null,
                        );
                },
              ),
            ),
          ),
        ],
      ),
      body: _isFirstLoad && books.isEmpty
          ? _buildLoadingScreen()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTestament("Old Testament", 0, 39),
                const SizedBox(height: 32),
                _buildTestament("New Testament", 39, books.length),
              ],
            ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded, size: 90, color: Color(0xFF5D8668)),
            const SizedBox(height: 50),
            const Text(
              "Preparing the Holy Bible",
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Color(0xFF5D8668)),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 320,
              child: LinearProgressIndicator(
                value: _loadProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5D8668)),
                minHeight: 12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "${(_loadProgress * 100).toInt()}%",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF5D8668)),
            ),
            const SizedBox(height: 12),
            Text(
              _currentBookName,
              style: const TextStyle(fontSize: 17, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestament(String title, int start, int end) {
    final int safeEnd = (end > books.length) ? books.length : end;
    final int itemCount = (safeEnd - start).clamp(0, books.length); // ← THIS FIXES EVERYTHING

    if (itemCount <= 0) {
      return const SizedBox.shrink(); // nothing to show
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D8668),
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (context, i) {
            final book = books[start + i];
            final String bookName = book['name'];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
              child: ElevatedButton(
                onPressed: () => setState(() {
                  selectedBook = book;
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D8668),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black38,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  bookName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32), // Space before next testament
      ],
    );
  }
}*/

class BiblePage extends StatelessWidget {
  const BiblePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BibleVersionManager>(
      builder: (context, manager, child) {
        final books = manager.books;

        if (manager.isLoading || books.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.menu_book_rounded, size: 100, color: Color(0xFF5D8668)),
                  SizedBox(height: 40),
                  Text("Loading the Holy Bible...", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5D8668))),
                  SizedBox(height: 30),
                  CircularProgressIndicator(color: Color(0xFF5D8668)),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Holy Bible", style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF5D8668),
            foregroundColor: Colors.white,
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: manager.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : DropdownButton<String>(
                      value: manager.currentVersion,
                      dropdownColor: const Color(0xFF5D8668),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      items: manager.availableVersions
                        .map((v) => DropdownMenuItem(value: v['code'], child: Text(v['name']!)))
                        .toList(),
                      onChanged: (v) => v != null ? manager.changeVersion(v) : null,
                    ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTestament(context, "Old Testament", books, 0, 39),
              const SizedBox(height: 32),
              _buildTestament(context, "New Testament", books, 39, books.length),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTestament(BuildContext context, String title, List books, int start, int end) {
    final items = books.sublist(start, end.clamp(start, books.length));
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF5D8668))),
        ),
        ...items.map((book) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => BookReader(
                book: book,
                onBack: () => Navigator.pop(ctx),
              )),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D8668), foregroundColor: Colors.white),
            child: Text(book['name'], style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          ),
        )),
      ],
    );
  }
}

// Keep your BookReader and ChapterReader exactly as before — they already work perfectly

// NEW SCREEN: Chapter Grid → Verse List
class BookReader extends StatelessWidget {
  final Map<String, dynamic> book;
  final VoidCallback onBack;

  const BookReader({
    super.key, 
    required this.book, 
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final chapters = book['chapters'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(book['name']),
        backgroundColor: const Color(0xFF5D8668),
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Consumer<BibleVersionManager>(
                builder: (context, manager, child) {
                  return manager.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : DropdownButton<String>(
                          value: manager.currentVersion,
                          dropdownColor: const Color(0xFF5D8668),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          items: manager.availableVersions
                              .map((v) => DropdownMenuItem(
                                    value: v['code'],
                                    child: Text(v['name']!),
                                  ))
                              .toList(),
                          onChanged: (v) => v != null ? manager.changeVersion(v) : null,
                        );
                },
              ),
            ),
          ),
        ],
      ),

      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          childAspectRatio: 1.3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: chapters.length,
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChapterReader(
                    chapterData: chapters[i],
                    bookName: book['name'],
                    chapterNum: i + 1,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF5D8668), Color(0xFF4A6B52)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text("${i + 1}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }
}

/*class ChapterReader extends StatelessWidget {
  final dynamic chapterData;
  final String bookName;
  final int chapterNum;

  const ChapterReader({
    super.key,
    required this.chapterData,
    required this.bookName,
    required this.chapterNum,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Extract raw verses
    final List<dynamic> rawVerses = chapterData is List<dynamic>
        ? chapterData
        : chapterData is Map<String, dynamic> && chapterData.containsKey('verses')
            ? chapterData['verses'] as List<dynamic>
            : <dynamic>[];

    // 2. Normalize + sort — THE ONLY VERSION THAT WILL NEVER COMPLAIN AGAIN
    final List<Map<String, dynamic>> versesToDisplay = rawVerses.map((v) {
      if (v is Map<String, dynamic>) {
        final int verseNum = v['verse'] is int
            ? v['verse'] as int
            : int.tryParse(v['verse'].toString()) ?? 1;

        final String verseText = (v['text'] as String?)?.trim() ?? v['text'].toString().trim();

        return {'verse': verseNum, 'text': verseText};
      }
      if (v is String) {
        return {'verse': rawVerses.indexOf(v) + 1, 'text': v.trim()};
      }
      return {'verse': 999, 'text': '[Invalid verse]'};
    }).toList()
      ..sort((a, b) => (a['verse'] as int).compareTo(b['verse'] as int));

    if (versesToDisplay.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("$bookName $chapterNum"), backgroundColor: const Color(0xFF5D8668), foregroundColor: Colors.white),
        body: const Center(child: Text("No verses found for this chapter.", style: TextStyle(fontSize: 18))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("$bookName $chapterNum"),
        backgroundColor: const Color(0xFF5D8668),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Consumer<BibleVersionManager>(
                builder: (context, manager, child) => manager.isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : DropdownButton<String>(
                        value: manager.currentVersion,
                        dropdownColor: const Color(0xFF5D8668),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        items: manager.availableVersions
                            .map((v) => DropdownMenuItem(value: v['code'], child: Text(v['name']!)))
                            .toList(),
                        onChanged: (v) => v != null ? manager.changeVersion(v) : null,
                      ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: versesToDisplay.length,
        itemBuilder: (context, i) {
          final verse = versesToDisplay[i];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 19, height: 1.8, color: Colors.black87),
                children: [
                  TextSpan(
                    text: "${verse['verse']} ",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D8668), fontSize: 17),
                  ),
                  TextSpan(text: verse['text'] as String),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}*/


class ChapterReader extends StatelessWidget {
  final dynamic chapterData;
  final String bookName;
  final int chapterNum;

  const ChapterReader({
    super.key,
    required this.chapterData,
    required this.bookName,
    required this.chapterNum,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BibleVersionManager>(
      builder: (context, manager, child) {
        // This rebuilds instantly when version changes
        final currentData = manager.getCurrentChapterData(bookName, chapterNum) ?? chapterData;

        final List<dynamic> rawVerses = currentData is List
            ? currentData
            : currentData is Map && currentData['verses'] is List
                ? currentData['verses']
                : <dynamic>[];

        final verses = rawVerses.map((v) {
          if (v is Map<String, dynamic>) {
            final num = v['verse'] is int ? v['verse'] as int : int.tryParse('${v['verse']}') ?? 1;
            final text = (v['text'] as String?)?.trim() ?? '${v['text']}'.trim();
            return {'verse': num, 'text': text};
          }
          if (v is String) return {'verse': rawVerses.indexOf(v) + 1, 'text': v.trim()};
          return {'verse': 999, 'text': '[Error]'};
        }).toList();

        verses.sort((a, b) => (a['verse'] as int).compareTo(b['verse'] as int));

        return Scaffold(
          appBar: AppBar(
            title: Text("$bookName $chapterNum"),
            backgroundColor: const Color(0xFF5D8668),
            foregroundColor: Colors.white,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: manager.isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                      : DropdownButton<String>(
                          value: manager.currentVersion,
                          dropdownColor: const Color(0xFF5D8668),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          items: manager.availableVersions
                              .map((v) => DropdownMenuItem(value: v['code'], child: Text(v['name']!)))
                              .toList(),
                          onChanged: (v) => v != null ? manager.changeVersion(v) : null,
                        ),
                ),
              ),
            ],
          ),
          body: verses.isEmpty
              ? const Center(child: Text("Loading chapter..."))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: verses.length,
                  itemBuilder: (context, i) {
                    final v = verses[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 19, height: 1.8, color: Colors.black87),
                          children: [
                            TextSpan(
                              text: "${v['verse']} ",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D8668), fontSize: 17),
                            ),
                            TextSpan(text: v['text'] as String),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}