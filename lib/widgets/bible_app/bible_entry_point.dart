// lib/widgets/bible_app/bible_entry_point.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bible.dart';
import 'bible_last_position_manager.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Use a post-frame callback so the context is fully ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryResumeLastPosition();
    });
  }

  Future<void> _tryResumeLastPosition() async {
    _hasEnteredBible = true;

    if (!mounted) return;

    final last = await LastPositionManager.getLast();

    // If nothing saved ever, or user was only on home/book_grid → do nothing
    if (last == null || last['screen'] != 'chapter') {
      return;
    }

    final String bookName = last['book'];
    final int chapter = last['chapter'];

    final book = context.read<BibleVersionManager>().books.firstWhereOrNull(
          (b) => b['name'] == bookName,
        );

    if (book == null) return;

    final chapters = book['chapters'] as List;
    if (chapter < 1 || chapter > chapters.length) return;

    if (!mounted) return;

    // Remove any existing Bible routes to avoid duplicates
    Navigator.of(context).popUntil((route) => route.isFirst);

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