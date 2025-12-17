// lib/screens/lesson_preview.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../UI/buttons.dart';
import '../../backend_data/lesson_data.dart';
import '../bible_app/bible.dart';
import '../bible_app/highlight/highlight_manager.dart';
import 'assignment/assignment_response_page_user.dart';
import 'bible_ref_parser.dart';
import 'reference_verse_popup.dart';

class BeautifulLessonPage extends StatelessWidget {
  final SectionNotes data;
  final String title;
  final DateTime lessonDate;
  final bool isTeen;

  const BeautifulLessonPage({
    super.key,
    required this.data,
    required this.title,
    required this.lessonDate,
    required this.isTeen,
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
                verses.add({
                  'verse': verseNum,
                  'text': verseText,
                  'highlighted': isHighlighted,
                });
              }
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.black.withOpacity(0.65),
                builder: (_) => VersePopup(
                  reference: refStr,
                  verses: verses,
                  rawText: raw,
                ),
              );
            },
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
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _shareLesson,
        backgroundColor: Color.fromARGB(255, 100, 13, 74),
          icon: const Icon(
            Icons.ios_share,
            color: Colors.white, // <-- makes the icon white
          ),
          label: const Text(
          "Share Lesson",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold, // <-- makes the text white
          ),
        ),
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
              // REAL ASSIGNMENT FROM YOUR NEW COLLECTION
              const SizedBox(height: 20),
              if (user != null && !user.isAnonymous)
                Center(
                  child: AssignmentWidgetButton(
                    context: context,
                    text: "Answer This Week's Assignment",
                    icon: const Icon(Icons.edit_note_rounded),
                    topColor: Colors.deepPurple,
                    borderColor: const Color.fromARGB(0, 0, 0, 0),   // optional
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignmentResponsePage(
                            date: lessonDate,
                            isTeen: title.contains("Teen") || title.contains("teen"),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (user == null || user.isAnonymous)
                Center(
                  child: const Text(
                    "Sign in to answer this week's assignment",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color.fromARGB(244, 107, 36, 36)),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}