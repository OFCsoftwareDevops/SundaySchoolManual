// lib/widgets/further_reading_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bible_app/bible.dart';
import '../../bible_app/highlight/highlight_manager.dart';
import '../reference_verse_popup.dart';


/// Opens the Further Reading as a centered dialog (not bottom sheet)
void showFurtherReadingDialog({
  required BuildContext context,
  required String todayReading, // e.g. "Esther 4:16 (KJV)" or "Luke 4:5."
}) {
  final bool hasReading = todayReading.trim().isNotEmpty;
  if (!hasReading) return;

  // Show loading first
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  // Clean the reference
  final String ref = todayReading
      .replaceAll(RegExp(r'\s*\(KJV\)\.?$'), '')
      .replaceAll(RegExp(r'\.+$'), '')
      .trim();

  // Fetch the verse exactly like your other working places
  final manager = context.read<BibleVersionManager>();
  final raw = manager.getVerseText(ref) ?? "Verse temporarily unavailable";

  final lines = raw
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  final highlightMgr = context.read<HighlightManager>();
  final bookKey = ref.split(' ').first.toLowerCase().replaceAll(' ', '');
  final chapter = int.tryParse(RegExp(r'\d+').firstMatch(ref)?.group(0) ?? '1') ?? 1;

  final List<Map<String, dynamic>> verses = [];

  for (final line in lines) {
    final parts = line.split(RegExp(r'\s+'));
    final verseNum = int.tryParse(parts.first);
    if (verseNum == null || verseNum == 0) continue;

    final verseText = parts.skip(1).join(' ');
    final highlighted = highlightMgr.isHighlighted(bookKey, chapter, verseNum);

    verses.add({
      'verse': verseNum,
      'text': verseText,
      'highlighted': highlighted,
    });
  }

  // Close loading
  if (Navigator.canPop(context)) Navigator.pop(context);

  // Show the beautiful centered dialog
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: double.maxFinite,
        child: VersePopup(
          reference: ref,
          verses: verses,
          rawText: raw,
          heightFraction: 0.85, // tall dialog
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close", style: TextStyle(color: Colors.deepPurple)),
        ),
      ],
    ),
  );
}