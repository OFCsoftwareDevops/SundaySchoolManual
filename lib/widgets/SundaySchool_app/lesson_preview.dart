// lib/screens/lesson_preview.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../UI/app_buttons.dart';
import '../../UI/app_colors.dart';
import '../../backend_data/database/lesson_data.dart';
import '../../backend_data/service/analytics/analytics_service.dart';
import '../../utils/media_query.dart';
import '../../utils/share_lesson.dart';
import '../bible_app/bible.dart';
import '../bible_app/bible_actions/highlight_manager.dart';
import '../helpers/main_screen.dart';
import 'assignment/assignment_response_page_user.dart';
import 'lesson_bible_ref_parser.dart';
import 'lesson_ref_verse_popup.dart';
import '../../auth/login/auth_service.dart';
import '../../backend_data/service/saved_items_service.dart';

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
  void _showShareOptions(BuildContext context) {
    final lessonShare = LessonShare(
      data: data,
      title: title,
      lessonDate: lessonDate,
      logoPath: 'assets/images/rccg_jhfan_share_image.png' // Optionally provide a logo path
      
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.sp)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.sp, horizontal: 24.sp),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Share Lesson",
                  style: TextStyle(
                    fontSize: 20.sp, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6.sp),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: AppColors.primaryContainer),
                  title: const Text("Share as PDF"),
                  onTap: () async {
                    Navigator.pop(context); // Close bottom sheet
                    await lessonShare.shareAsPdf();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link, color: AppColors.secondary),
                  title: const Text("Share Link"),
                  onTap: () async {
                    Navigator.pop(context);
                    await lessonShare.shareAsLink();
                  },
                ),
                SizedBox(height: 6.sp),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlock(BuildContext context, ContentBlock block, ColorScheme colorScheme, TextTheme textTheme) {
    // ← exact same _buildBlock from the previous message (heading, text, memory_verse, numbered_list, bullet_list, quote, prayer)
    switch (block.type) {
      case "heading":
        return Padding(
          padding: EdgeInsets.only(top: 10.sp, bottom: 10.sp),
          child: Text(
            block.text!, 
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 22.sp,
              color: colorScheme.onBackground,
            ),
          ),
        );
      case "text":
        return Padding(
          padding: EdgeInsets.only(bottom: 10.sp),
          child: buildRichText(context, block.text!, colorScheme),
        );
      case "memory_verse":
        return Padding(
          padding: EdgeInsets.only(bottom: 10.sp),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.sp),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16.sp),
              border: Border(
                left: BorderSide(color: colorScheme.primary, width: 5.sp),
              ),
            ),
            child: Text(
              block.text!,
              style: textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: 15.sp,
                height: 1.4.sp,
                color: colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      case "numbered_list":
        return Padding(
          padding: EdgeInsets.only(bottom: 10.sp),
          child: Column(
            children: block.items!.asMap().entries.map((e) {
              final i = e.key + 1;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 1.5.sp),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 25.sp, 
                      height: 25.sp,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4.sp),
                      ),
                      child: Center(
                        child: Text(
                          '$i',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.sp),
                    Expanded(
                      child: Text(
                        e.value,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      case "bullet_list":
        return Padding(
          padding: EdgeInsets.only(bottom: 10.sp),
          child: Column(
            children: block.items!.map((item) => Padding(
              padding: EdgeInsets.symmetric(vertical: 6.sp),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• ", style: textTheme.bodyMedium),
                  Expanded(
                    child: Text(
                      item,
                      style: textTheme.bodyMedium?.copyWith(height: 5.sp),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        );
      case "quote":
        return Container(
          margin: EdgeInsets.only(bottom: 10.sp),
          padding: EdgeInsets.all(10.sp),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12.sp), 
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          ),
          child: Text(
            block.text!,
            style: textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.4.sp,
            ),
          ),
        );
      case "prayer":
        return Container(
          margin: EdgeInsets.only(bottom: 10.sp),
          padding: EdgeInsets.all(10.sp),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.sp),
          ),
          child: Column(
            children: [
              Text(
                "Prayer",
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.sp),
              Text(
                block.text!,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 18.sp,
                  height: 1.4.sp),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Wherever you show lesson text (e.g. in your lesson detail screen)
  Widget buildRichText(BuildContext context, String text, ColorScheme colorScheme) {
    final refs = findBibleReferences(text);
    if (refs.isEmpty) {
      return Text(
        text, 
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.4.sp,
          fontSize: 15.sp,
        ),
      );
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
            color: AppColors.scriptureHighlight,
            fontWeight: FontWeight.w600,
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
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.4.sp,
          fontSize: 15.sp,
          color: colorScheme.onBackground,
        ),
        children: parts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = CalendarDayStyle.fromContainer(context, 50);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          iconSize: style.monthFontSize.sp, 
          color: theme.colorScheme.onPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title, 
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontSize: style.monthFontSize.sp,
            fontWeight: FontWeight.bold),
        ),
        actions: [
          // Smart Save Lesson Button
          _SmartSaveLessonButton(
            lessonDate: lessonDate,
            title: title,
            isTeen: isTeen,
            preview: data.blocks.isNotEmpty ? (data.blocks.first.text ?? '') : '',
          ),
        ],
      ),

      floatingActionButton: SizedBox(
        width: 160.sp,
        height: 50.sp,
        child: FloatingActionButton.extended(
          onPressed: () => _showShareOptions(context),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
          foregroundColor: Theme.of(context).colorScheme.surface,
          icon: Icon(
            Icons.ios_share,
            size: 20.sp,
          ),
          label: Text(
            "Share Lesson",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30.sp, vertical: 20.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.sp),
              // Topic Title — dynamic and theme-aware
              Text(
                data.topic,
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 32.sp,
                  height: 1.4.sp,
                  color: colorScheme.onBackground,
                ) ?? TextStyle(fontSize: 36.sp, fontWeight: FontWeight.w300),
              ),
              if (data.biblePassage.isNotEmpty) ...[
                SizedBox(height: 1.4.sp),
                Text(
                  data.biblePassage,
                  style: textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontSize: 16.sp,
                    color: colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
              SizedBox(height: 20.sp),
              ...data.blocks.map((block) => _buildBlock(context, block, colorScheme, textTheme)),
              // REAL ASSIGNMENT FROM YOUR NEW COLLECTION
              SizedBox(height: 20.sp),

              Center(
                child: AssignmentWidgetButton(
                  context: context,
                  text: user != null && !user.isAnonymous
                      ? "Answer Weekly Assignment"
                      : "Login For Assignment",
                  icon: Icon(
                    user != null && !user.isAnonymous ? Icons.edit_note_rounded : Icons.login,
                  ),
                  topColor: AppColors.primaryContainer,
                  onPressed: () async {
                    await AnalyticsService.logButtonClick('assignment_attempt_from_lesson_preview');
                    if (user != null && !user.isAnonymous) {
                      // Normal logged-in user → go to assignment
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignmentResponsePage(
                            date: lessonDate,
                            isTeen: title.contains("Teen") || title.contains("teen"),
                          ),
                        ),
                      );
                    } else {
                      await FirebaseAuth.instance.signOut();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => MainScreen()),
                          (route) => false,
                        );
                    }
                  },
                ),
              ),
              SizedBox(height: 100.sp),
            ],
          ),
        ),
      ),
    );
  }
}

// Smart Save Lesson Button — uses your existing isLessonSaved()
class _SmartSaveLessonButton extends StatefulWidget {
  final DateTime lessonDate;
  final String title;
  final bool isTeen;
  final String preview;

  const _SmartSaveLessonButton({
    required this.lessonDate,
    required this.title,
    required this.isTeen,
    required this.preview,
  });

  @override
  State<_SmartSaveLessonButton> createState() => _SmartSaveLessonButtonState();
}

class _SmartSaveLessonButtonState extends State<_SmartSaveLessonButton> {
  bool _isSaved = false;
  bool _isChecking = true;

  CalendarDayStyle get style => CalendarDayStyle.fromContainer(context, 50);

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

    final lessonId = '${widget.lessonDate.year}-${widget.lessonDate.month}-${widget.lessonDate.day}';

    final saved = await SavedItemsService().isLessonSaved(user.uid, lessonId);

    if (mounted) {
      setState(() {
        _isSaved = saved;
        _isChecking = false;
      });
    }
  }

  Future<void> _saveLesson() async {
    final user = FirebaseAuth.instance.currentUser;
    final auth = context.read<AuthService>();

    if (user == null || auth.churchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in and join a church to save lessons')),
      );
      return;
    }

    if (_isSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson already saved! 📚')),
      );
      return;
    }

    final lessonId = '${widget.lessonDate.year}-${widget.lessonDate.month}-${widget.lessonDate.day}';
    final lessonType = widget.isTeen ? 'teen' : 'adult';

    try {
      await SavedItemsService().saveLessonFromDate(
        user.uid,
        lessonId: lessonId,
        lessonType: lessonType,
        title: widget.title,
        preview: widget.preview,
      );

      setState(() => _isSaved = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson saved! 📚')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _isSaved ? 'Already saved' : 'Save this lesson',
      onPressed: _saveLesson,
      icon: _isChecking
          ? SizedBox(
              width: style.monthFontSize.sp, 
              height: style.monthFontSize.sp, 
              child: CircularProgressIndicator(
                strokeWidth: 2.sp,
                color: AppColors.onPrimary,
              ),
            )
          : Icon(
            _isSaved ? Icons.bookmark : Icons.bookmark_add,
            color: _isSaved 
                ? AppColors.success 
                : AppColors.onPrimary,
            size: style.monthFontSize.sp,
          ),
    );
  }
}