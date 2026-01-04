// lib/widgets/further_reading_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../UI/app_colors.dart';
import '../../../auth/login/auth_service.dart';
import '../../../backend_data/service/analytics/analytics_service.dart';
import '../../../backend_data/service/saved_items_service.dart';
import '../../../backend_data/service/streak_service.dart';
import '../../../UI/app_linear_progress_bar.dart';
import '../../../UI/timed_button.dart';
import '../../bible_app/bible.dart';
import '../../bible_app/bible_actions/highlight_manager.dart';
import '../../helpers/main_screen.dart';
import '../lesson_ref_verse_popup.dart';


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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.sp)),
      backgroundColor: Theme.of(context).colorScheme.background,
      insetPadding: EdgeInsets.all(20.sp),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row with reference and save icon
            Padding(
              padding: EdgeInsets.fromLTRB(16.sp, 12.sp, 8.sp, 8.sp),
              child: Row(
                children: [
                  Expanded(
                    child: Text(ref, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  ),
                  // NEW: Smart Save Button
                  _SmartSaveReadingButton(ref: ref, todayReading: todayReading),
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
                heightFraction: 0.85.sp, // tall dialog
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
          child: SizedBox(
            width: double.infinity, // full width in actions
              child: TimedFeedbackButtonStateful(
              text: "Complete Reading",
              topColor: AppColors.success,
              seconds: readingSeconds, // time to wait before enabling
              onPressed: () async {
                await AnalyticsService.logButtonClick('further_reading_completed!');
                final currentUser = FirebaseAuth.instance.currentUser;

                if (currentUser != null) {
                  try {
                    await StreakService().updateReadingStreak(currentUser.uid);
                  } catch (e) {
                    // ignore streak update errors for now
                  }
                }

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => MainScreen()),
                ); // close the dialog
              },
              borderColor: AppColors.success,
              borderWidth: 2.sp,
              backOffset: 4.sp,
              backDarken: 0.45,
            ),
          ),
        ),
      ],
    ),
  );
}

// Smart Save Button — uses your existing isFurtherReadingSaved()
class _SmartSaveReadingButton extends StatefulWidget {
  final String ref;
  final String todayReading;

  const _SmartSaveReadingButton({required this.ref, required this.todayReading});

  @override
  State<_SmartSaveReadingButton> createState() => _SmartSaveReadingButtonState();
}

class _SmartSaveReadingButtonState extends State<_SmartSaveReadingButton> {
  bool _isSaved = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isChecking = false);
      return;
    }

    final auth = context.read<AuthService>();
    if (auth.churchId == null) {
      setState(() => _isChecking = false);
      return;
    }

    final saved = await SavedItemsService().isFurtherReadingSaved(user.uid, widget.ref);

    if (mounted) {
      setState(() {
        _isSaved = saved;
        _isChecking = false;
      });
    }
  }

  Future<void> _saveReading() async {
    final user = FirebaseAuth.instance.currentUser;
    final auth = context.read<AuthService>();

    if (user == null || auth.churchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in and join a church to save readings')),
      );
      return;
    }

    if (_isSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already saved! 📖')),
      );
      return;
    }

    try {
      await SavedItemsService().addFurtherReading(
        user.uid,
        title: widget.ref,
        reading: widget.todayReading,
      );

      setState(() => _isSaved = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reading saved! 📖')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      tooltip: _isSaved ? 'Already saved' : 'Save this reading',
      onPressed: _saveReading,
      icon: _isChecking
          ? SizedBox(
              width: 24.sp,
              height: 24.sp,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color.fromARGB(255, 100, 13, 74),
              ),
            )
          : Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_add,
              color: _isSaved ? AppColors.success : theme.colorScheme.onPrimary,
            ),
    );
  }
}