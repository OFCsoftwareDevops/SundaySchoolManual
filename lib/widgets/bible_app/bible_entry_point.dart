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
  State<BibleEntryPoint> createState() => BibleEntryPointState();
}

class BibleEntryPointState extends State<BibleEntryPoint> with AutomaticKeepAliveClientMixin{

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> resumeLastPosition() async {
    final last = await LastPositionManager.getLast();
    if (last == null) return;

    final screen = last['screen'] as String?;
    if (screen == null) return;

    final manager = context.read<BibleVersionManager>();
    final books = manager.books;

    switch (screen) {
      case 'bible_page':
        // Already on book grid — do nothing
        break;

      case 'book_grid':
        final bookName = last['book'] as String?;
        if (bookName == null) return;

        final book = books.firstWhereOrNull((b) => b['name'] == bookName);
        if (book == null) return;

        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BookReader(book: book)),
        );
        break;

      case 'chapter':
        final bookName = last['book'] as String?;
        final chapter = last['chapter'] as int?;
        final verse = last['verse'] as int?;

        if (bookName == null || chapter == null) return;

        final book = books.firstWhereOrNull((b) => b['name'] == bookName);
        if (book == null) return;

        final chapters = book['chapters'] as List;
        if (chapter < 1 || chapter > chapters.length) return;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChapterReader(
              chapterData: chapters[chapter - 1],
              bookName: book['name'],
              chapterNum: chapter,
              totalChapters: chapters.length,
              initialVerse: verse,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for keep alive
    return const BiblePage(); // ← always show book grid underneath
  }
}