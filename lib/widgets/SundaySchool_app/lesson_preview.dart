// lib/screens/lesson_preview.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../UI/app_bar.dart';
import '../../UI/app_buttons.dart';
import '../../UI/app_colors.dart';
import '../../backend_data/database/lesson_data.dart';
import '../../backend_data/service/analytics/analytics_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/device_check.dart';
import '../../utils/media_query.dart';
import '../bible_app/bible.dart';
import '../bible_app/bible_actions/highlight_manager.dart';
import '../bible_app/bible_ref_verse_popup.dart';
import '../helpers/snackbar.dart';
import 'lesson_share.dart';
import '../helpers/main_screen.dart';
import 'assignment/assignment_response_page_user.dart';
import 'lesson_bible_ref_parser.dart';
import '../../auth/login/auth_service.dart';
import '../../backend_data/service/firestore/saved_items_service.dart';

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
            child: IntrinsicWidth(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.sp,                   // small horizontal breathing room
                  //vertical: 12.sp,                    // a bit more vertical space feels natural
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.shareLesson ?? "Share Lesson",
                      style: TextStyle(
                        fontSize: 20.sp, 
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6.sp),
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: AppColors.primaryContainer),
                      title: Text(AppLocalizations.of(context)?.shareAsLessonPdf ?? "Share as PDF"),
                      onTap: () async {
                        Navigator.pop(context); // Close bottom sheet
                        await lessonShare.shareAsPdf();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.link, color: AppColors.secondary),
                      title: Text(AppLocalizations.of(context)?.shareLink ?? "Share Link"),
                      onTap: () async {
                        Navigator.pop(context);
                        await lessonShare.shareAsLink();
                      },
                    ),
                    SizedBox(height: 6.sp),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlock(BuildContext context, ContentBlock block, ColorScheme colorScheme, TextTheme textTheme) {
    final lineHeight = context.lineHeight;
    // ← exact same _buildBlock from the previous message (heading, text, memory_verse, numbered_list, bullet_list, quote, prayer)
    switch (block.type) {
      case "heading":
        return Padding(
          padding: EdgeInsets.only(top: 10.sp, bottom: 4.sp),
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
          padding: EdgeInsets.only(bottom: 4.sp),
          child: buildRichText(context, block.text!, colorScheme),
        );
      case "memory_verse":
        return Padding(
          padding: EdgeInsets.only(bottom: 10.sp),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 16.sp),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16.sp),
              border: Border(
                left: BorderSide(color: colorScheme.primaryContainer, width: 5.sp),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.memoryVerse ?? "Memory verse:",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onBackground,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 5.sp),
                Center(
                  child: Text(
                    block.text!,
                    style: textTheme.titleMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 13.sp,
                      height: lineHeight,
                      color: colorScheme.onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
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
                          height: lineHeight,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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
              height: lineHeight,
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
                AppLocalizations.of(context)?.prayer ?? "Prayer",
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.sp),
              Text(
                block.text!,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 18.sp,
                  height: lineHeight,
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  List<TextSpan> buildRichTextSpans(
    BuildContext context,
    String text,
    ColorScheme colorScheme, {
    bool applyItalicToReferences = false,
  }) {
    // Pre-process: better paragraph spacing
    final processedText = text
        .replaceAllMapped(RegExp(r'([.!?])\s*\n'), (m) => '${m.group(1)}\n\n')
        .replaceAll('\n', '\n');

    final lines = processedText.split('\n');
    final spans = <TextSpan>[];
    final lineHeight = context.lineHeight; // or set to 1.2 for tighter gaps

    bool inOutlineSection = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trimRight();

      if (line.isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      // Detect start of OUTLINE section (case-insensitive)
      if (RegExp(r'^(lesson\s+)?outline\b', caseSensitive: false).hasMatch(line)) {
        inOutlineSection = true;
        spans.add(TextSpan(
          text: '$line\n',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ));
        continue;
      }

      // Inside OUTLINE: normal rendering, no auto-numbered detection
      if (inOutlineSection) {
        // Exit outline on next major heading
        if (RegExp(r'^[A-Z][A-Z\s]+:').hasMatch(line) ||
            RegExp(r'^[A-Z][A-Z\s]+$').hasMatch(line)) {
          inOutlineSection = false;
        }
        spans.add(TextSpan(text: '$line\n'));
        continue;
      }

      // Outside OUTLINE: check for numbered item
      final numberedMatch = RegExp(r'^\s*(\d+[.)])\s*(.*)$').firstMatch(line);
      if (numberedMatch != null) {
        final numberPrefix = numberedMatch.group(1)!; // e.g. "1." or "2)"
        final itemText = numberedMatch.group(2)!;

        // Add styled number prefix
        spans.add(
          TextSpan(
            text: '$numberPrefix ',
            style: TextStyle(
              fontSize: 15.sp,
            ),
          ),
        );

        // Now apply the FULL Bible reference parsing to the item text (same as normal lines)
        final refs = findBibleReferences(itemText);
        if (refs.isEmpty) {
          spans.add(
            TextSpan(
              text: itemText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15.sp,
                height: lineHeight,
              ),
            ),
          );
        } else {
          int lastEnd = 0;
          for (final ref in refs) {
            final match = bibleRefRegex.firstMatch(itemText.substring(lastEnd));
            if (match == null) continue;

            final start = lastEnd + match.start;
            final end = lastEnd + match.end;

            if (start > lastEnd) {
              spans.add(
                TextSpan(
                  text: itemText.substring(lastEnd, start),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15.sp,
                    height: lineHeight,
                  ),
                ),
              );
            }

            spans.add(
              TextSpan(
                text: itemText.substring(start, end),
                style: TextStyle(
                  color: AppColors.scriptureHighlight,
                  fontWeight: FontWeight.w600,
                  fontStyle: applyItalicToReferences ? FontStyle.italic : FontStyle.normal,
                ),
                recognizer: TapGestureRecognizer()..onTap = () {
                  final refStr = ref.toString();
                  final manager = context.read<BibleVersionManager>();
                  final raw = manager.getVerseText(refStr) ?? AppLocalizations.of(context)?.verseTemporarilyUnavailable ?? "Verse temporarily unavailable";

                  final lines = raw
                      .split('\n')
                      .map((l) => l.trim())
                      .where((l) => l.isNotEmpty)
                      .toList();

                  final highlightMgr = context.read<HighlightManager>();

                  final String bookKey = ref.book.toString().toLowerCase().replaceAll(' ', '');

                  final List<Map<String, dynamic>> verses = [];

                  for (final line in lines) {
                    final parts = line.split(RegExp(r'\s+'));
                    final int? verseNum = int.tryParse(parts.first);

                    if (verseNum == null || verseNum == 0) continue;

                    final String verseText = parts.skip(1).join(' ');

                    final bool isHighlighted = highlightMgr.isHighlighted(
                      bookKey,
                      ref.chapter,
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

          if (lastEnd < itemText.length) {
            spans.add(
              TextSpan(
                text: itemText.substring(lastEnd),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 15.sp,
                  height: lineHeight,
                ),
              ),
            );
          }
        }

        spans.add(const TextSpan(text: ''));
        continue;
      }

      // Normal line (not numbered) — your original Bible ref parsing
      final refs = findBibleReferences(line);
      if (refs.isEmpty) {
        spans.add(TextSpan(text: '$line\n'));
        continue;
      }

      int lastEnd = 0;
      for (final ref in refs) {
        final match = bibleRefRegex.firstMatch(line.substring(lastEnd));
        if (match == null) continue;

        final start = lastEnd + match.start;
        final end = lastEnd + match.end;

        if (start > lastEnd) {
          spans.add(TextSpan(text: line.substring(lastEnd, start)));
        }

        spans.add(
          TextSpan(
            text: line.substring(start, end),
            style: TextStyle(
              color: AppColors.scriptureHighlight,
              fontWeight: FontWeight.w600,
              fontStyle: applyItalicToReferences ? FontStyle.italic : FontStyle.normal,
            ),
            recognizer: TapGestureRecognizer()..onTap = () {
              final refStr = ref.toString();
              final manager = context.read<BibleVersionManager>();
              final raw = manager.getVerseText(refStr) ?? AppLocalizations.of(context)?.verseTemporarilyUnavailable ?? "Verse temporarily unavailable";

              final lines = raw
                  .split('\n')
                  .map((l) => l.trim())
                  .where((l) => l.isNotEmpty)
                  .toList();

              final highlightMgr = context.read<HighlightManager>();

              final String bookKey = ref.book.toString().toLowerCase().replaceAll(' ', '');

              final List<Map<String, dynamic>> verses = [];

              for (final line in lines) {
                final parts = line.split(RegExp(r'\s+'));
                final int? verseNum = int.tryParse(parts.first);

                if (verseNum == null || verseNum == 0) continue;

                final String verseText = parts.skip(1).join(' ');

                final bool isHighlighted = highlightMgr.isHighlighted(
                  bookKey,
                  ref.chapter,
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

      if (lastEnd < line.length) {
        spans.add(TextSpan(text: line.substring(lastEnd)));
      }
      spans.add(const TextSpan(text: '\n'));
    }

    return spans;
  }

  Widget buildRichText(BuildContext context, String text, ColorScheme colorScheme) {
    final lineHeight = context.lineHeight;
    
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: lineHeight,
          fontSize: 15.sp,
          color: colorScheme.onBackground,
        ),
        children: buildRichTextSpans(
          context, 
          text, 
          colorScheme,
          applyItalicToReferences: false,
        ),
      ),
      textAlign: TextAlign.justify,               // ← optional, looks nicer
      softWrap: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = CalendarDayStyle.fromContainer(context, 50);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final lineHeight = context.lineHeight;

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppAppBar(
        title: title,
        showBack: true,
        actions: [
          // Smart Save Lesson Button
          _SmartSaveLessonButton(
            lessonDate: lessonDate,
            title: title,
            isTeen: isTeen,
            preview: data.blocks.isNotEmpty ? (data.blocks.first.text ?? '') : '',
          ),
        ],
        /*actions: [
          Padding(
            padding: EdgeInsets.only(right: 10.sp),
            child: Center(
              child: manager.isLoading
                ? const CircularProgressIndicator()
                : DropdownButton<String>(
                  value: manager.currentVersion,
                  dropdownColor: theme.colorScheme.onSecondaryContainer,
                  icon: Icon(
                    Icons.keyboard_arrow_down, 
                    color: theme.colorScheme.onSecondaryContainer,
                    size: style.monthFontSize.sp,
                  ),
                  //underline: const SizedBox(),
                  style: TextStyle(
                    fontSize: style.monthFontSize.sp * 0.5,
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                  items: manager.availableVersions
                    .map((v) => DropdownMenuItem(value: v['code'], child: Text(v['name']!)))
                    .toList(),
                  onChanged: (v) => v != null ? manager.changeVersion(v) : null,
                ),
            ),
          ),
        ],*/
      ),
      //backgroundColor: Theme.of(context).colorScheme.background,
      /*appBar: AppBar(
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
      ),*/

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
            AppLocalizations.of(context)?.shareLesson ?? "Share Lesson",
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
              // TOPIC TITLE
              Text(
                data.topic,
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 32.sp,
                  height: lineHeight,
                  color: colorScheme.onBackground,
                ) ?? TextStyle(fontSize: 36.sp, fontWeight: FontWeight.w300),
              ),
              //BIBLE PASSAGE
              if (data.biblePassage.isNotEmpty) ...[
                SizedBox(height: 8.sp),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: AppLocalizations.of(context)?.biblePassage ?? "BIBLE PASSAGE:  ",
                        style: textTheme.titleMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 16.sp,
                          color: colorScheme.onBackground,
                        ),
                      ),
                      ...buildRichTextSpans(
                        context, 
                        data.biblePassage, 
                        colorScheme,
                        applyItalicToReferences: true,
                      ),
                    ],
                    style: textTheme.titleMedium?.copyWith(   // ← base style for whole thing
                      fontSize: 16.sp,
                      color: colorScheme.onBackground,
                    ),
                  ),
                ),
              ],
              ...data.blocks.map((block) => _buildBlock(context, block, colorScheme, textTheme)),
              // REAL ASSIGNMENT FROM YOUR NEW COLLECTION
              SizedBox(height: 20.sp),

              Center(
                child: AssignmentWidgetButton(
                  context: context,
                  text: AppLocalizations.of(context)?.answerWeeklyAssignment ?? "Weekly Assignment",
                  /*text: user != null && !user.isAnonymous
                      ? AppLocalizations.of(context)?.answerWeeklyAssignment ?? "Weekly Assignment"
                      : AppLocalizations.of(context)?.loginForAssignment ?? "Login For Assignment",*/
                  icon: Icon(
                    user != null && !user.isAnonymous ? Icons.edit_note_rounded : Icons.login,
                  ),
                  topColor: AppColors.primaryContainer,
                  onPressed: () async {
                    await AnalyticsService.logButtonClick('assignment_attempt_from_lesson_preview');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssignmentResponsePage(
                          date: lessonDate,
                          isTeen: title.contains("Teen") || title.contains("teen"),
                        ),
                      ),
                    );
                    /*if (user != null && !user.isAnonymous) {
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
                    }*/
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

  Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser!;
    final service = SavedItemsService();
    final userId = user.uid;
    final isAnonymous = user.isAnonymous;

    final lessonId = '${widget.lessonDate.year}-${widget.lessonDate.month.toString().padLeft(2, '0')}-${widget.lessonDate.day.toString().padLeft(2, '0')}';
    final lessonType = widget.isTeen ? 'teen' : 'adult';

    try {
      if (_isSaved) {
        // ── REMOVE ────────────────────────────────────────
        // Optimistic remove from cache (both real + anonymous)
        final current = service.getCachedItems(userId, 'saved_lessons');
        final updated = current.where((item) => item['lessonId'] != lessonId).toList();
        await service.cacheItems(userId, 'saved_lessons', updated);

        // Only real users delete from Firestore
        if (!isAnonymous) {
          await service.removeSavedLesson(userId, lessonId);
        }

        setState(() => _isSaved = false);
        showTopToast(
          context,
          AppLocalizations.of(context)?.lessonRemovedFromSaved ?? 'Lesson removed from saved',
        );
      } else {
        // ── ADD ───────────────────────────────────────────
        final now = DateTime.now().toUtc();

        final newItem = <String, dynamic>{
          'lessonId': lessonId,
          'lessonType': lessonType,
          'title': widget.title,
          'preview': widget.preview,
          'savedAt': now.toIso8601String(), // Hive-safe
        };

        if (isAnonymous) {
          // Anonymous: local only + fake ID
          final fakeId = 'local_${now.millisecondsSinceEpoch}';
          newItem['id'] = fakeId;

          final current = service.getCachedItems(userId, 'saved_lessons');
          final updated = [newItem, ...current];
          await service.cacheItems(userId, 'saved_lessons', updated);
        } else {
          // Real user: Firestore + cache
          final docRef = await service.saveLesson(
            userId,
            lessonId: lessonId,
            lessonType: lessonType,
            title: widget.title,
            preview: widget.preview,
          );

          newItem['id'] = docRef;

          final current = service.getCachedItems(userId, 'saved_lessons');
          final updated = [newItem, ...current];
          await service.cacheItems(userId, 'saved_lessons', updated);
        }

        setState(() => _isSaved = true);
        showTopToast(
          context,
          AppLocalizations.of(context)?.lessonSaved ?? 'Lesson saved! 📚',
        );
      }
    } catch (e, stack) {
      debugPrint("Lesson toggle failed: $e\n$stack");
      showTopToast(
        context,
        AppLocalizations.of(context)?.operationFailed ?? 'Operation failed: $e',
      );
    }
  }

  /*Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    final auth = context.read<AuthService>();

    if (user == null || auth.churchId == null) {
      showTopToast(
        context,
        AppLocalizations.of(context)?.saveLessonPrompt ?? 'Sign in and join a church to save lessons',
      );
      return;
    }

    final service = SavedItemsService();
    final lessonId = '${widget.lessonDate.year}-${widget.lessonDate.month}-${widget.lessonDate.day}';
    final lessonType = widget.isTeen ? 'teen' : 'adult';

    try {
      if (_isSaved) {
        // REMOVE
        await service.removeSavedLessonById(user.uid, lessonId);
        setState(() => _isSaved = false);
        showTopToast(
          context,
          AppLocalizations.of(context)?.lessonRemovedFromSaved ?? 'Lesson removed from saved',
        );
      } else {
        // ADD
        await service.saveLessonFromDate(
          user.uid,
          lessonId: lessonId,
          lessonType: lessonType,
          title: widget.title,
          preview: widget.preview,
          // note: null,   ← you can add note support later if wanted
        );
        setState(() => _isSaved = true);
        showTopToast(
          context,
          AppLocalizations.of(context)?.lessonSaved ?? 'Lesson saved! 📚',
        );
      }
    } catch (e) {
      showTopToast(
        context,
        AppLocalizations.of(context)?.operationFailed ?? 'Operation failed: $e',
      );
    }
  }*/

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IconButton(
      tooltip: _isSaved ? AppLocalizations.of(context)?.removedFromSavedLessons ?? 'Remove from saved lessons' : AppLocalizations.of(context)?.saveThisLesson ?? 'Save this lesson',
      onPressed: _isChecking ? null : _toggleSave,
      icon: _isChecking
          ? SizedBox(
              width: style.monthFontSize.sp, 
              height: style.monthFontSize.sp, 
              child: CircularProgressIndicator(
                strokeWidth: 2.sp,
                color: colorScheme.onSecondaryContainer,
              ),
            )
          : Icon(
            _isSaved ? Icons.bookmark : Icons.bookmark_add,
            color: _isSaved 
                ? AppColors.success 
                : colorScheme.onSecondaryContainer,
            size: style.monthFontSize.sp,
          ),
    );
  }
}