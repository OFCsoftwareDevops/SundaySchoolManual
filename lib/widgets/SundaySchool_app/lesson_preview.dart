// lib/screens/lesson_preview.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../backend_data/lesson_data.dart';
import '../bible_app/bible.dart';
import '../bible_app/highlight/highlight_manager.dart';
import 'assignment/assignment.dart';
import 'assignment/next_assignment_preview.dart';
import 'bible_ref_parser.dart';
import 'reference_verse_popup.dart';

class BeautifulLessonPage extends StatelessWidget {
  final SectionNotes data;
  final String title;
  final DateTime lessonDate;

  const BeautifulLessonPage({
    super.key,
    required this.data,
    required this.title,
    required this.lessonDate,
  });

  // ← the rest of the file is 100% identical to the previous message
  // (share function + _buildBlock + full build method)

  void _shareLesson() {
    final buffer = StringBuffer();
    buffer.writeln("*$title*");
    buffer.writeln("${data.topic}");
    if (data.biblePassage.isNotEmpty) buffer.writeln("_${data.biblePassage}_");
    buffer.writeln();

    for (var block in data.blocks) {
      switch (block.type) {
        case "heading": 
          buffer.writeln("\n*${block.text}*"); 
          break;
        case "text":
          buffer.writeln("${block.text}\n"); 
          break;
        case "memory_verse": 
          buffer.writeln("Memory Verse\n“${block.text}”\n"); 
          break;
        case "numbered_list":
          for (var i = 0; i < block.items!.length; i++) {
            buffer.writeln("${i + 1}. ${block.items![i]}");
          }
          buffer.writeln();
          break;
        case "bullet_list":
          block.items!.forEach((item) => buffer.writeln("• $item"));
          buffer.writeln();
          break;
        case "quote": 
          buffer.writeln("> ${block.text}\n"); 
          break;
        case "prayer": 
          buffer.writeln("Prayer\n${block.text}"); 
          break;
      }
    }

    Share.share(buffer.toString(), subject: "$title: ${data.topic}");
  }

  Widget _buildBlock(BuildContext context, ContentBlock block) {
    // ← exact same _buildBlock from the previous message (heading, text, memory_verse, numbered_list, bullet_list, quote, prayer)
    switch (block.type) {
      case "heading":
        return Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Text(
            block.text!, 
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
          ),
        );
      case "text":
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: buildRichText(context, block.text!),
        );
          /*child: Text(
            block.text!, 
            style: const TextStyle(fontSize: 17, height: 1.6),
          ),
        );*/
      case "memory_verse":
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
              border: const Border(left: BorderSide(color: Colors.deepPurple, width: 5)),
            ),
            child: Text(
              block.text!, 
              style: const TextStyle(fontSize: 18, height: 1.7, fontStyle: FontStyle.italic), 
              textAlign: TextAlign.center,
            ),
          ),
        );
      case "numbered_list":
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            children: block.items!.asMap().entries.map((e) {
              final i = e.key + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 25, 
                      height: 25,
                      decoration: const BoxDecoration(color: Color.fromARGB(255, 100, 13, 74), shape: BoxShape.rectangle),
                      child: Center(
                        child: Text('$i', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text(e.value, style: const TextStyle(fontSize: 17, height: 1.5))),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      case "bullet_list":
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: block.items!.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(fontSize: 17)),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 17, height: 1.5))),
                ],
              ),
            )).toList(),
          ),
        );
      case "quote":
        return Container(
          margin: const EdgeInsets.only(bottom: 32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50, 
            borderRadius: BorderRadius.circular(12), 
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(block.text!, style: const TextStyle(fontSize: 17, fontStyle: FontStyle.italic, height: 1.6)),
        );
      case "prayer":
        return Container(
          margin: const EdgeInsets.only(bottom: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              const Text("Prayer", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(block.text!, style: const TextStyle(fontSize: 17, height: 1.6)),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Wherever you show lesson text (e.g. in your lesson detail screen)
  Widget buildRichText(BuildContext context, String text) {
    final refs = findBibleReferences(text);
    if (refs.isEmpty) {
      return Text(text, style: const TextStyle(fontSize: 17, height: 1.6));
    }

    final parts = <TextSpan>[];
    int lastEnd = 0;

    for (final ref in refs) {
      final match = bibleRefRegex.firstMatch(text.substring(lastEnd));
      if (match == null) continue;

      final start = lastEnd + match.start;
      final end = lastEnd + match.end;

      // Add normal text before reference
      if (start > lastEnd) {
        parts.add(TextSpan(text: text.substring(lastEnd, start)));
      }

      // Add clickable reference
      parts.add(
        TextSpan(
          text: text.substring(start, end),
          style: const TextStyle(
            color: Color.fromARGB(255, 100, 13, 74),
            fontWeight: FontWeight.w600,
            //decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              final refStr = ref.toString();
              final manager = context.read<BibleVersionManager>();
              final raw = manager.getVerseText(refStr) ?? "Verse temporarily unavailable";
              
              final lines = raw
                  .split('\n')
                  .map((l) => l.trim())
                  .where((l) => l.isNotEmpty)
                  .toList();

              final highlightMgr = context.read<HighlightManager>();

              // Normalize book name exactly like your HighlightManager expects
              final String bookKey = ref.book.toString().toLowerCase().replaceAll(' ', '');
              // → "genesis", "exodus", "psalms", "1corinthians", etc.

              final List<Map<String, dynamic>> verses = [];

              for (final line in lines) {
                final parts = line.split(RegExp(r'\s+'));
                final int? verseNum = int.tryParse(parts.first);

                if (verseNum == null || verseNum == 0) continue;

                final String verseText = parts.skip(1).join(' ');

                // This is the correct call — per-verse highlight check
                final bool isHighlighted = highlightMgr.isHighlighted(
                  bookKey,           // String book
                  ref.chapter,       // int chapter
                  verseNum,          // int verse ← now used!
                );
              /*final raw = manager.getVerseText(refStr) ?? "Verse temporarily unavailable";
              final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();

              // parse lines into structures [{verse:1, text:"...", highlighted:bool}, ...]
              final highlightMgr = context.read<HighlightManager>(); // adjust class name if different
              final parsed = <Map<String, dynamic>>[];
              final books = manager.books;
              for (final line in lines) {
                final parts = line.trim().split(RegExp(r'\s+'));
                final verseNum = int.tryParse(parts.first) ?? 0;
                final text = parts.skip(1).join(' ');

                // normalize book key used by your filename/book name logic
                final rawBook = ref.book.toString();
                final bookKey = rawBook.toLowerCase().replaceAll(' ', '');

                // find book index (0-based) and convert to the integer your HighlightManager expects
                final bookIndex = books.indexWhere((b) =>
                  (b['name'] as String).toLowerCase().replaceAll(' ', '') == bookKey
                );

                final int bookParameter = bookIndex >= 0 ? (bookIndex + 1) : 0; // adjust +1 if your API is 1-based

                final isHighlighted = highlightMgr.isHighlighted(
                  manager.currentVersion,
                  bookParameter,         // now an int, not String
                  ref.chapter,
                  verseNum,
                );*/

                verses.add({
                  'verse': verseNum,
                  'text': verseText,
                  'highlighted': isHighlighted,
                });
              }

              showDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.65), // dark semi-transparent backdrop
                builder: (context) => VersePopup(
                  reference: refStr,
                  verses: verses,
                  rawText: raw,
                ),
              );
            },
            /*..onTap = () {
              ref.toString();
              print('DEBUG: Looking for verse: $ref');
              final verseText = context.read<BibleVersionManager>().getVerseText(ref.toString())
              ?? "Verse temporarily unavailable";
              showDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8),
                builder: (_) => VersePopup(
                  reference: ref.toString(),
                  verseText: verseText,
                ),
              );
            },*/
        ),
      );

      lastEnd = end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      parts.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 17, height: 1.6, color: Colors.black87),
        children: parts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _shareLesson,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.share_rounded),
        label: const Text("Share Lesson"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20), 
                    onPressed: () => Navigator.pop(context)),
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Text(data.topic, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w300, height: 1.2)),
              if (data.biblePassage.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(data.biblePassage, style: const TextStyle(fontSize: 18, color: Colors.black54, fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 20),
              ...data.blocks.map((block) => _buildBlock(context, block)),
              //AssignmentFromLesson(data: data),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

/*class AssignmentFromLesson extends StatelessWidget {
  final SectionNotes data;

  const AssignmentFromLesson({required this.data});

  @override
  Widget build(BuildContext context) {
    // Cherche le bloc "assignment"
    final assignmentBlock = data.blocks.firstWhere(
      (b) => b.type == "assignment",
      orElse: () => ContentBlock(type: "", text: null),
    );

    if (assignmentBlock.text == null || assignmentBlock.text!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 32, bottom: 16),
          child: Text(
            "This Week’s Assignment",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade50, Colors.deepPurple.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.deepPurple.shade300, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_turned_in_rounded, size: 32, color: Colors.deepPurple),
                  const SizedBox(width: 12),
                  Text(
                    assignmentBlock.text!,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Affiche le texte qui suit le bloc "assignment" (le vrai devoir)
              ...data.blocks.skipWhile((b) => b.type != "assignment").skip(1).take(3).map((b) {
                if (b.type == "text" && b.text != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      b.text!,
                      style: const TextStyle(fontSize: 17, height: 1.6),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}*/