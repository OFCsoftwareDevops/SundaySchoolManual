import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bible.dart';
import 'bible_last_position_manager.dart';
import 'bible_page.dart';

/* HERE <<<< class BibleLoader extends StatefulWidget {
  final VoidCallback onLoaded;
  final bool resumeLastPosition;

  const BibleLoader({
    super.key, 
    required this.onLoaded, 
    this.resumeLastPosition = false,
  });

  @override
  State<BibleLoader> createState() => _BibleLoaderState();
}

/*class _BibleLoaderState extends State<BibleLoader> {
  bool _hasNavigated = false; // Prevent double navigation

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only run once when this widget appears (e.g. when user taps Bible tab)
    if (_hasNavigated) return;
    _hasNavigated = true;

    // Load Bible + decide where to go
    _loadBibleAndNavigate();
  }

  Future<void> _loadBibleAndNavigate() async {
    if (!mounted) return;

    try {
      // 1. Load the Bible data
      await context.read<BibleVersionManager>().loadInitialBible();
      print('Bible loaded, now checking last position...');

      // 2. Get last saved position
      final lastPos = await LastPositionManager.getLast();
      final manager = context.read<BibleVersionManager>();
      final books = manager.books;

      if (!mounted) return;

      Widget destination;

      if (lastPos == null || books.isEmpty) {
        print('No saved position → going to Bible home');
        destination = const BiblePage();
      } else {
        final String screen = lastPos['screen'] ?? 'home';
        final String bookName = lastPos['book'] ?? 'Genesis';
        final int chapterNum = (lastPos['chapter'] as num?)?.toInt() ?? 1;

        // Find the book safely
        final book = books.firstWhere(
          (b) => b['name'] == bookName,
          orElse: () => books[0],
        );

        final chaptersList = (book['chapters'] as List?) ?? [];

        if (chaptersList.isEmpty) {
          destination = const BiblePage();
        } else {
          final int safeChapter = chapterNum.clamp(1, chaptersList.length);

          if (screen == 'chapter') {
            print('Resuming chapter → $bookName $safeChapter');
            destination = ChapterReader(
              chapterData: chaptersList[safeChapter - 1],
              bookName: book['name'],
              chapterNum: safeChapter,
              totalChapters: chaptersList.length,
            );
          } else if (screen == 'book_grid') {
            print('Resuming book grid → $bookName');
            destination = BookReader(book: book);
          } else {
            destination = const BiblePage();
          }
        }
      }

      // 3. Notify parent that loading is done
      widget.onLoaded?.call();

      // 4. ONLY navigate if we're still mounted and inside a proper Navigator context
      if (!mounted) return;

      // This is the key fix: use the correct context that has a Navigator
      final navigatorContext = Navigator.of(context, rootNavigator: false).context;

      Navigator.of(navigatorContext).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );

    } catch (e) {
      print('Error in BibleLoader: $e');
      if (mounted) {
        widget.onLoaded?.call();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BiblePage()),
        );
      }
    }
  }

  /*Future<void> _loadBibleAndNavigate() async {
    // 1. Load the Bible data first
    await context.read<BibleVersionManager>().loadInitialBible();
    print('📖 Bible loaded, now checking last position...'); // ← ADD THIS

    // 2. Decide where to go
    final lastPos = await LastPositionManager.getLast();
    final manager = context.read<BibleVersionManager>();
    final books = manager.books;

    Widget destination;

    if (lastPos == null) {
      print('🏠 Going to home (BiblePage) - first time or no data');
      // First time ever → go to home screen
      destination = const BiblePage();
    } else {
      print('🔄 Resuming at: ${lastPos['screen']} - ${lastPos['book']} ${lastPos['chapter']}');
      final String screen = lastPos['screen'];
      final String bookName = lastPos['book'];
      final int chapterNum = lastPos['chapter'];

      // Find the book (fallback to Genesis if something went wrong)
      final book = books.firstWhere(
        (b) => b['name'] == bookName,
        orElse: () => books[0],
      );
      final chaptersList = book['chapters'] as List;

      // Clamp chapter number to valid range
      final safeChapter = chapterNum.clamp(1, chaptersList.length);

      if (screen == 'chapter') {
        destination = ChapterReader(
          chapterData: chaptersList[safeChapter - 1],
          bookName: book['name'],
          chapterNum: safeChapter,
          totalChapters: chaptersList.length,
        );
      } else if (screen == 'book_grid') {
        destination = BookReader(
          book: book,
        );
      } else {
        destination = const BiblePage();
      }
    }

    if (!mounted) return;

    if (destination != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => destination!),
      );
    }

    // ← CALL THIS when done
    widget.onLoaded?.call();
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.menu_book_rounded, size: 110, color: Color(0xFF5D8668)),
            SizedBox(height: 50),
            Text(
              "Preparing the Holy Bible",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF5D8668)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Color(0xFF5D8668), strokeWidth: 5),
            SizedBox(height: 30),
            Text("One moment please...", style: TextStyle(fontSize: 18, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}*/

    /*if (mounted) {
      print('🚀 Navigating to: ${destination.runtimeType}');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    }
  }


}*/

class _BibleLoaderState extends State<BibleLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndMaybeResume());
  }

  Future<void> _loadAndMaybeResume() async {
    // 1. Load Bible data
    await context.read<BibleVersionManager>().loadInitialBible();

    if (!mounted) return;

    // 2. If we DON'T want to resume → just finish
    if (!widget.resumeLastPosition) {
      widget.onLoaded();
      return;
    }

    // 3. Try to resume last chapter
    final prefs = await SharedPreferences.getInstance();
    final String? screen = prefs.getString('last_screen');
    final String? bookName = prefs.getString('last_book');
    final int? chapter = prefs.getInt('last_chapter');

    if (screen != 'chapter' || bookName == null || chapter == null) {
      widget.onLoaded();
      return;
    }

    final manager = context.read<BibleVersionManager>();
    final book = manager.books.firstWhere(
      (b) => b['name'] == bookName,
      orElse: () => manager.books[0],
    );

    final chapters = book['chapters'] as List;
    if (chapter < 1 || chapter > chapters.length) {
      widget.onLoaded();
      return;
    }

    // SUCCESS → go straight to the chapter
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ChapterReader(
          chapterData: chapters[chapter - 1],
          bookName: book['name'],
          chapterNum: chapter,
          totalChapters: chapters.length,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, size: 110, color: Color(0xFF5D8668)),
            SizedBox(height: 50),
            Text(
              "Preparing the Holy Bible",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF5D8668)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Color(0xFF5D8668), strokeWidth: 5),
          ],
        ),
      ),
    );
  }
} >>>>>> HERE */

class BibleLoader extends StatefulWidget {
  const BibleLoader({super.key});
  @override State<BibleLoader> createState() => _BibleLoaderState();
}

class _BibleLoaderState extends State<BibleLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryResume());
  }

  Future<void> _tryResume() async {
    await context.read<BibleVersionManager>().loadInitialBible();
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final screen = prefs.getString('last_screen');

    if (screen != 'chapter') {
      //_showBiblePage();
      return;
    }

    final bookName = prefs.getString('last_book');
    final chapter = prefs.getInt('last_chapter');
    if (bookName == null || chapter == null) {
      //_showBiblePage();
      return;
    }

    final book = context.read<BibleVersionManager>().books.firstWhere(
          (b) => b['name'] == bookName,
          orElse: () => context.read<BibleVersionManager>().books[0],
        );

    final chapters = book['chapters'] as List;
    if (chapter < 1 || chapter > chapters.length) {
      //_showBiblePage();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChapterReader(
          chapterData: chapters[chapter - 1],
          bookName: book['name'],
          chapterNum: chapter,
          totalChapters: chapters.length,
        ),
      ),
    );
  }

  void _showBiblePage() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BiblePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF5D8668)),
      ),
    );
  }
}