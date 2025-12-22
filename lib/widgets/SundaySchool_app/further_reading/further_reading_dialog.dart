// lib/widgets/further_reading_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/login/auth_service.dart';
import '../../../backend_data/saved_items_service.dart';
import '../../../backend_data/streak_service.dart';
import '../../../UI/linear_progress_bar.dart';
import '../../../UI/timed_button.dart';
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
    builder: (_) => const Center(child: LinearProgressBar()),
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

  // TIMER CALCULATED BASED ON TEXT
  final wordCount = raw.split(RegExp(r'\s+')).length;
  int readingSeconds = (wordCount / 3).ceil(); // ~200 wpm
  readingSeconds = ((readingSeconds + 4) ~/ 5) * 5; // Round up to next multiple of 5
  if (readingSeconds < 10) readingSeconds = 10; // minimum 5s

  // Show the beautiful centered dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row with reference and save icon
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(ref, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    tooltip: 'Save reading',
                    icon: const Icon(Icons.bookmark_add, color: Color.fromARGB(255, 100, 13, 74)),
                    onPressed: () async {
                      final auth = context.read<AuthService>();
                      final currentUser = FirebaseAuth.instance.currentUser;
                      final churchId = auth.churchId;

                      if (currentUser == null || churchId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in and select a church to save readings')));
                        return;
                      }

                      try {
                        await SavedItemsService().addFurtherReading(
                          churchId,
                          currentUser.uid,
                          title: ref,
                          reading: todayReading,
                        
                        );
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reading saved')));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save reading: $e')));
                      }
                    },
                  ),
                ],
              ),
            ),

            // The verse popup
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: VersePopup(
                reference: ref,
                verses: verses,
                rawText: raw,
                heightFraction: 0.85, // tall dialog
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity, // full width in actions
              child: TimedFeedbackButtonStateful(
              text: "Complete Reading",
              topColor: Colors.deepPurple,
              seconds: readingSeconds, // time to wait before enabling
              onPressed: () async {
                final currentUser = FirebaseAuth.instance.currentUser;

                if (currentUser != null) {
                  try {
                    await StreakService().updateReadingStreak(currentUser.uid);
                  } catch (e) {
                    // ignore streak update errors for now
                  }
                }

                Navigator.of(context).pop(); // close the dialog
              },
              borderColor: Colors.deepPurple,
              borderWidth: 2,
              backOffset: 4,
              backDarken: 0.45,
            ),
          ),
        ),
      ],
    ),
  );
}