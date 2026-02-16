
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../UI/app_colors.dart';
import '../../UI/app_sound.dart';
import '../../backend_data/service/analytics/analytics_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/device_check.dart';
import '../SundaySchool_app/further_reading/further_reading_dialog.dart';
import '../helpers/snackbar.dart';
import 'bible.dart';
import 'bible_page.dart';

class VersePopup extends StatefulWidget {
  final String reference;
  final String? bookName;
  final int? chapterNum;
  final List<Map<String, dynamic>> verses;
  final String? rawText;
  final double heightFraction;
  final bool showCloseButton;

  const VersePopup({
    super.key,
    required this.reference,
    this.bookName,
    this.chapterNum,
    required this.verses,
    this.rawText,
    this.heightFraction = 0.40,
    this.showCloseButton = false,
  });

  @override
  State<VersePopup> createState() => _VersePopupState();
}

class _VersePopupState extends State<VersePopup> {
  final Set<int> _selectedVerses = {};

  String _extractBookNameFromReference(String reference) {
    final cleaned = reference.trim()
        .replaceAll(RegExp(r'\([^)]*\)'), '')     // remove parentheses
        .replaceAll(RegExp(r'[;,.–—-]+$'), '')    // trailing separators
        .trim();

    // Try to match book name before chapter number
    final match = RegExp(
      r'^([A-Za-z0-9\s]+?)\s*(?:\d+(?::|\s|$))',
      caseSensitive: false,
    ).firstMatch(cleaned);

    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim();
    }

    // Fallback: everything before first digit
    final fallback = RegExp(r'^([^\d]+)').firstMatch(cleaned);
    return fallback?.group(1)?.trim() ?? 'Unknown';
  }

  int _extractChapterFromReference(String reference) {
    try {
      final match = RegExp(r'(\d+)(?=:|–|-|\s*$)').firstMatch(reference);
      return int.tryParse(match?.group(1) ?? '0') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  void _openFullChapter() {
    final String book = (widget.bookName ?? _extractBookNameFromReference(widget.reference)).trim();
    final int chapter = widget.chapterNum ?? _extractChapterFromReference(widget.reference);

    if (book == 'Unknown' || chapter == 0) {
      showTopToast(
        context,
        AppLocalizations.of(context)?.couldNotDetermineBook ?? "Could not determine book or chapter",
      );
      return;
    }

    final manager = Provider.of<BibleVersionManager>(context, listen: false);
    final books = manager.books;

    final bookData = books.firstWhere(
      (b) => (b['name'] as String).toLowerCase() == book.toLowerCase(),
      orElse: () => <String, dynamic>{},  // ← empty map instead of null
    );

    if (bookData.isEmpty) {
      showTopToast(
        context,
        AppLocalizations.of(context)?.bookNotFoundInBibleVersion ?? "Book not found in current Bible version",
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookReader(
          book: bookData,
          initialChapter: chapter,
          skipChapterGrid: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final popupHeight = screenHeight * widget.heightFraction;
    final theme = Theme.of(context);
    final lineHeight = context.lineHeight;

    return Container(
      height: popupHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.sp)),
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.sp),
            child: Column(
              children: [
                SizedBox(height: 20.sp),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top row with reference and save icon
                    Row(
                      children: [
                        Text(
                          widget.reference, 
                          style: TextStyle(
                            fontSize: 15.sp, 
                            fontWeight: FontWeight.bold,
                            color: AppColors.scriptureHighlight,
                          ),
                        ),
                        // NEW: Smart Save Button
                        SmartSaveReadingButton(
                          ref: widget.reference, 
                          todayReading: widget.reference,
                        ),
                      ],
                    ),
                    // ← The new link/button
                    Flexible(
                      flex: 1,
                      fit: FlexFit.loose,
                      child: GestureDetector(
                        onTap: _openFullChapter,
                        child: Padding(
                          padding: EdgeInsets.only(top: 0.sp),
                          child: Text(
                            AppLocalizations.of(context)?.openFullChapter ?? "Open full chapter →",
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: theme.colorScheme.onBackground,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),                                
                    // Close button (far right)
                    if (widget.showCloseButton)
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20.sp,
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () async {                      
                          await AnalyticsService.logButtonClick('further_reading_canceled!');

                          Navigator.of(context).pop();

                          Future.delayed(const Duration(milliseconds: 80), () {
                            while (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();   // force-remove any leftover barrier
                            }
                          });
                        },
                        enableFeedback: AppSounds.soundEnabled,
                        tooltip: AppLocalizations.of(context)?.close ?? "Close",
                      ),
                  ],
                ),

                SizedBox(height: 8.sp),

                // Verse list
                Expanded(
                  child: Scrollbar(
                    thickness: 4.sp,
                    radius: Radius.circular(10.sp),
                    thumbVisibility: true,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(right: 10.sp, bottom: 100.sp), // ← extra bottom padding for sheet
                      itemCount: widget.verses.length,
                      itemBuilder: (context, index) {
                        final verse = widget.verses[index];
                        final verseNum = int.tryParse(verse['verse']?.toString() ?? '0') ?? 0;
                        final text = (verse['text'] ?? '').toString().trim();

                        final isSelected = _selectedVerses.contains(verseNum);

                        return InkWell(
                          onLongPress: () {
                            setState(() {
                              _selectedVerses.add(verseNum);
                            });
                          },
                          onTap: _selectedVerses.isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedVerses.remove(verseNum);
                                    } else {
                                      _selectedVerses.add(verseNum);
                                    }
                                  });
                                },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 6.sp, horizontal: 8.sp),
                            color: isSelected
                                ? theme.colorScheme.primary.withOpacity(0.18)
                                : null,
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$verseNum ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.scriptureHighlight,
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                  TextSpan(
                                    text: text,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      height: lineHeight,
                                      color: theme.colorScheme.onBackground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}