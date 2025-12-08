import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bible.dart';
import 'bible_page.dart';

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
      return;
    }

    final bookName = prefs.getString('last_book');
    final chapter = prefs.getInt('last_chapter');
    if (bookName == null || chapter == null) {
      return;
    }

    final book = context.read<BibleVersionManager>().books.firstWhere(
          (b) => b['name'] == bookName,
          orElse: () => context.read<BibleVersionManager>().books[0],
        );

    final chapters = book['chapters'] as List;
    if (chapter < 1 || chapter > chapters.length) {
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