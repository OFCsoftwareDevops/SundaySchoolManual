// Create a new file: further_reading_week.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../bible_app/bible.dart';
import '../../bible_app/highlight/highlight_manager.dart';
import '../reference_verse_popup.dart';

String extractBibleReference(String input) {
  // Handles all these cases:
  // "Esther 4:16 (KJV)" → Esther 4:16
  return input
      .replaceAll(RegExp(r'\s*\(KJV\)$'), '')   // remove trailing (KJV)
      .replaceAll(RegExp(r'\.+$'), '')          // remove trailing dots
      .trim();
}

class FurtherReadingRow extends StatelessWidget {
  final String todayReading;

  const FurtherReadingRow({
    super.key,
    required this.todayReading,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasReading = todayReading.trim().isNotEmpty;
    final String displayText = hasReading ? todayReading : "No further reading today";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: hasReading
              ? () {
                  // Clean reference
                  String ref = extractBibleReference(todayReading);
                  /*String ref = todayReading
                      .replaceAll(RegExp(r'\s*\(KJV\)\.?$'), '')
                      .replaceAll(RegExp(r'\.+$'), '')
                      .trim();*/

                  final manager = context.read<BibleVersionManager>();
                  final raw = manager.getVerseText(ref) ?? "Verse temporarily unavailable";

                  final lines = raw
                      .split('\n')
                      .map((l) => l.trim())
                      .where((l) => l.isNotEmpty)
                      .toList();

                  final highlightMgr = context.read<HighlightManager>();

                  // Extract book name for highlight check
                  final bookMatch = RegExp(r'^[\w\s]+').firstMatch(ref);
                  final bookName = bookMatch?.group(0)?.trim() ?? '';
                  final bookKey = bookName.toLowerCase().replaceAll(' ', '');

                  final chapterMatch = RegExp(r'(\d+)').firstMatch(ref);
                  final chapter = chapterMatch != null ? int.parse(chapterMatch.group(1)!) : 1;

                  // FIXED: Correct Map type
                  final List<Map<String, dynamic>> verses = [];

                  for (final line in lines) {
                    final parts = line.split(RegExp(r'\s+'));
                    final verseNum = int.tryParse(parts.first);
                    if (verseNum == null || verseNum == 0) continue;

                    final verseText = parts.skip(1).join(' ');

                    final isHighlighted = highlightMgr.isHighlighted(
                      bookKey,
                      chapter,
                      verseNum,
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
                      reference: ref,
                      verses: verses,
                      rawText: raw,
                    ),
                  );
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasReading ? Colors.deepPurple : Colors.grey.shade300,
                width: hasReading ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: hasReading ? const Color.fromARGB(0, 104, 58, 183) : Colors.transparent,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 38,
                  color: hasReading ? Colors.deepPurple.shade700 : Colors.grey[500],
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Further Reading",
                        style: TextStyle(
                          fontSize: 13.5,
                          color: hasReading ? Colors.deepPurple.shade600 : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: hasReading ? Colors.deepPurple.shade900 : Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  hasReading ? Icons.arrow_forward_ios_rounded : Icons.lock_outline,
                  color: hasReading ? Colors.deepPurple.shade600 : Colors.grey[400],
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}