import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bible.dart';
import 'bible_last_position_manager.dart';
import 'bible_page.dart';

class BibleLoader extends StatefulWidget {
  final VoidCallback? onLoaded;
  const BibleLoader({super.key, this.onLoaded});

  @override
  State<BibleLoader> createState() => _BibleLoaderState();
}

class _BibleLoaderState extends State<BibleLoader> {
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
  }

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
}

    /*if (mounted) {
      print('🚀 Navigating to: ${destination.runtimeType}');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    }
  }


}*/