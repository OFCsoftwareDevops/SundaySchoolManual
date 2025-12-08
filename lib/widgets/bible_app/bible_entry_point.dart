// lib/widgets/bible_app/bible_entry_point.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bible.dart';
import 'bible_page.dart';

extension IterableX<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final e in this) if (test(e)) return e;
    return null;
  }
}

class BibleEntryPoint extends StatefulWidget {

  const BibleEntryPoint({
    super.key, 
  });

  @override
  State<BibleEntryPoint> createState() => _BibleEntryPointState();
}

class _BibleEntryPointState extends State<BibleEntryPoint> with AutomaticKeepAliveClientMixin{
  bool _hasEnteredBible = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasEnteredBible) _tryResume();
    });
  }

  Future<void> _tryResume() async {
    _hasEnteredBible = true;

    // Load Bible first
    await context.read<BibleVersionManager>().loadInitialBible();
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final String? screen = prefs.getString('last_screen');
    final String? bookName = prefs.getString('last_book');
    final int? chapter = prefs.getInt('last_chapter');

    if (screen != 'chapter' || bookName == null || chapter == null) return;

    final book = context.read<BibleVersionManager>().books.firstWhere(
          (b) => b['name'] == bookName,
          orElse: () => context.read<BibleVersionManager>().books[0],
        );

    final chapters = book['chapters'] as List;
    if (chapter < 1 || chapter > chapters.length) return;

    if (!mounted) return;

    // JUST PUSH — never pushReplacement
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
    super.build(context); // required for keep alive
    return const BiblePage(); // ← always show book grid underneath
  }
}