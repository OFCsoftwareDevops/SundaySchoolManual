import 'package:app_demo/utils/device_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../UI/app_buttons.dart';
import '../../UI/app_colors.dart';
import '../../UI/app_linear_progress_bar.dart';
import '../../utils/media_query.dart';
import 'bible_actions/highlight_manager.dart';
import 'bible.dart';
import 'bible_last_position_manager.dart';
import 'bible_actions/verse_action_sheet.dart';


extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');
  }
}

class BiblePage extends StatelessWidget {
  const BiblePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final style = CalendarDayStyle.fromContainer(context, 50);

    return Consumer<BibleVersionManager>(
      builder: (context, manager, child) {
        final books = manager.books;

        if (manager.isLoading || books.isEmpty) {
          return Scaffold(
            backgroundColor: colorScheme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_rounded, 
                    size: 100, color: 
                    colorScheme.primaryContainer,
                  ),
                  SizedBox(height: 40),
                  Text(
                    "Loading the Holy Bible...", 
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primaryContainer,
                    ),
                  ),
                  SizedBox(height: 30),
                  LinearProgressBar(),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              "Holy Bible",
              style: theme.appBarTheme.titleTextStyle?.copyWith(
                fontSize: style.monthFontSize.sp,
                fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 10.sp),
                child: Center(
                  child: manager.isLoading
                    ? const LinearProgressBar()
                    : DropdownButton<String>(
                      value: manager.currentVersion,
                      dropdownColor: theme.colorScheme.onSecondaryContainer,
                      icon: Icon(
                        Icons.keyboard_arrow_down, 
                        color: theme.colorScheme.onPrimary,
                        size: style.monthFontSize.sp,
                      ),
                      //underline: const SizedBox(),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary, 
                        fontSize: style.monthFontSize.sp * 0.5,
                        fontWeight: FontWeight.bold,
                      ),
                      items: manager.availableVersions
                        .map((v) => DropdownMenuItem(value: v['code'], child: Text(v['name']!)))
                        .toList(),
                      onChanged: (v) => v != null ? manager.changeVersion(v) : null,
                    ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _buildTestament(context, "Old Testament", books, 0, 39),
              const SizedBox(height: 32),
              _buildTestament(context, "New Testament", books, 39, books.length),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTestament(BuildContext context, String title, List books, int start, int end) {
    final theme = Theme.of(context);
    final items = books.sublist(start, end.clamp(start, books.length));
    if (items.isEmpty) return const SizedBox.shrink();

    // Base height from your existing logic (perfect for phones)
    final double baseButtonHeight = getBibleButtonSize(context);
    // Apply 0.7 reduction ONLY on tablets
    final double buttonHeight = context.isTablet ? baseButtonHeight * 0.7 : baseButtonHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.sp, 24.sp, 16.sp, 8.sp),
          child: Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        ...items.map((book) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: SizedBox(
            height: buttonHeight,
            width: double.infinity, 
            child: BibleBooksButtons(
              context: context,
              text: book['name'],
              textColor: theme.colorScheme.surface,
              topColor: theme.colorScheme.onSurface,  // same color you used in ElevatedButton
              onPressed: () {
                LastPositionManager.save(
                  bookName: book['name'],
                  chapter: 1,
                  screen: 'book_grid',
                );

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BookReader(book: book),
                  ),
                );
              },
            ),
          ),
        )),
      ],
    );
  }
}

// Keep your BookReader and ChapterReader exactly as before — they already work perfectly

// NEW SCREEN: Chapter Grid → Verse List
class BookReader extends StatelessWidget {
  final Map<String, dynamic> book;
  final int initialChapter;

  const BookReader({
    super.key, 
    required this.book,
    this.initialChapter = 1, 
  });

  // Helper: Detect tablet (add this extension elsewhere if not already present)
  bool _isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  // Modified: Apply 0.7 scale only on tablets
  double _getScaledButtonSize(BuildContext context) {
    final double baseSize = getBibleButtonSize(context);
    return _isTablet(context) ? baseSize * 0.7 : baseSize;
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final double buttonSize = _getScaledButtonSize(context);  // ← Use scaled size
    final screenWidth = MediaQuery.of(context).size.width;
    final totalHorizontalPadding = 40.0;
    final availableWidth = screenWidth - totalHorizontalPadding;
    final gap = 8.0;

    // More columns will naturally fit on tablets due to smaller buttons
    return ((availableWidth + gap) / (buttonSize + gap)).floor().clamp(7, 10); // ← Increased upper limit for tablets
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chapters = book['chapters'] as List<dynamic>;
    final columns = _calculateCrossAxisCount(context);

    final sizeInfo = calendarDayCellSize(context);
    final totalHorizontalPadding = sizeInfo['horizontalPadding']!;
    final style = CalendarDayStyle.fromContainer(context, 50);
    const double gap = 8.0; // ~8px

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,  // Or fitWidth to fill width
          child: Text(
            book['name'],
            style: TextStyle(fontSize: style.monthFontSize.sp)  // Your desired base size
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: style.monthFontSize.sp,
          onPressed: () {
            // Save position BEFORE popping
            LastPositionManager.save(
              screen: 'bible_page', // back to main Bible grid
            );
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.sp),
            child: Center(
              child: Consumer<BibleVersionManager>(
                builder: (context, manager, child) {
                  return manager.isLoading
                      ? const LinearProgressBar()
                      : DropdownButton<String>(
                          value: manager.currentVersion,
                          dropdownColor: theme.colorScheme.onSecondaryContainer,
                          icon: Icon(
                            Icons.keyboard_arrow_down, 
                            color: theme.colorScheme.onPrimary,
                            size: style.monthFontSize.sp,
                          ),
                          //underline: const SizedBox(),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary, 
                            fontWeight: FontWeight.bold,
                            fontSize: style.monthFontSize.sp  * 0.5,
                          ),
                          items: manager.availableVersions
                              .map((v) => DropdownMenuItem(
                                    value: v['code'],
                                    child: Text(v['name']!),
                                  ))
                              .toList(),
                          onChanged: (v) => v != null ? manager.changeVersion(v) : null,
                        );
                },
              ),
            ),
          ),
        ],
      ),

      body: GridView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: totalHorizontalPadding / 2, // 20 on each side
          vertical: 20,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,             
          childAspectRatio: 1.0,              // Square buttons
          crossAxisSpacing: gap,                // Identical horizontal gap
          mainAxisSpacing: gap,                 // Identical vertical gap
        ),
        itemCount: chapters.length,
        itemBuilder: (context, i) {
          return BibleChaptersButtons(
            context: context,
            text: "${i + 1}",
            textColor: theme.colorScheme.surface,
            topColor: theme.colorScheme.onSurface,
            borderColor: Colors.transparent,
            onPressed: () {
              LastPositionManager.save(
                screen: 'chapter',
                bookName: book['name'],
                chapter: i + 1,
                verse: 1,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChapterReader(
                    chapterData: chapters[i],
                    bookName: book['name'],
                    chapterNum: i + 1,
                    totalChapters: chapters.length,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// chapter_reader.dart
class ChapterReader extends StatefulWidget {
  final dynamic chapterData;
  final String bookName;
  final int chapterNum;
  final int totalChapters;
  final int? initialVerse;

  const ChapterReader({
    super.key,
    required this.chapterData,
    required this.bookName,
    required this.chapterNum,
    required this.totalChapters, 
    this.initialVerse,
  });

  @override
  State<ChapterReader> createState() => _ChapterReaderState();
}

class _ChapterReaderState extends State<ChapterReader> {
  final Set<int> _selectedVerses = {};
  final GlobalKey _listViewKey = GlobalKey();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_saveScrollPosition);
  }

  void _saveScrollPosition() {
    final offset = _scrollController.offset;
    // Simple: find the first visible verse
    // Or use a more accurate way with visible render objects
    // For now, save the current chapter
    LastPositionManager.save(
      screen: 'chapter',
      bookName: widget.bookName,
      chapter: widget.chapterNum,
      verse: 1, // improve later
    );
  }

  // One GlobalKey per verse so we can scroll to any of them
  final Map<int, GlobalKey> _verseKeys = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final fontstyle = CalendarDayStyle.fromContainer(context, 50);

    return Consumer<BibleVersionManager>(
      builder: (context, manager, child) {
        final currentData = manager.getCurrentChapterData(widget.bookName, widget.chapterNum) ?? widget.chapterData;

        final List<dynamic> rawVerses = currentData is List
            ? currentData
            : currentData is Map && (currentData as Map).containsKey('verses')
                ? (currentData['verses'] as List)
                : <dynamic>[];

        // Build safe verse list
        final List<Map<String, dynamic>> verses = rawVerses.map((v) {
          if (v is Map<String, dynamic>) {
            final int verseNum = v['verse'] is int
                ? v['verse'] as int
                : int.tryParse(v['verse'].toString()) ?? 999;
            final String text = (v['text'] as String?)?.trim() ?? '';
            return {'verse': verseNum, 'text': text};
          }
          if (v is String) {
            return {'verse': rawVerses.indexOf(v) + 1, 'text': v.trim()};
          }
          return {'verse': 999, 'text': ''};
        }).toList()
          ..sort((a, b) => (a['verse'] as int).compareTo(b['verse'] as int));

        final highlightManager = Provider.of<HighlightManager>(context);

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            centerTitle: true,
            title: FittedBox(
              fit: BoxFit.scaleDown,  // Or fitWidth to fill width
              child: Text(
                "${widget.bookName} ${widget.chapterNum}",
                style: TextStyle(
                  fontSize: fontstyle.monthFontSize.sp)  // Your desired base size
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              iconSize: fontstyle.monthFontSize.sp,
              onPressed: () {
                // Save position BEFORE popping
                LastPositionManager.save(
                  screen: 'book_grid',
                  bookName: widget.bookName,
                  chapter: widget.chapterNum,
                );
                Navigator.pop(context);
              },
            ),
            actions: [
              if (_selectedVerses.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close),
                  iconSize: fontstyle.monthFontSize.sp,
                  onPressed: () => setState(() => _selectedVerses.clear()),
                ),
              // ← VERSION SWITCHER (this was missing)
              Padding(
                padding: EdgeInsets.only(right: 12.sp),
                child: Center(
                  child: Consumer<BibleVersionManager>(
                    builder: (context, manager, child) {
                      return manager.isLoading
                          ? SizedBox(
                              width: 24.sp,
                              height: 24.sp,
                              child: LinearProgressBar(),
                            )
                          : DropdownButton<String>(
                              value: manager.currentVersion,
                              dropdownColor: colorScheme.onSecondaryContainer,
                              icon: Icon(
                                Icons.keyboard_arrow_down, 
                                color: colorScheme.onPrimary,
                                size: fontstyle.monthFontSize.sp,
                              ),
                              //underline: const SizedBox(),
                              style: TextStyle(
                                color: colorScheme.onPrimary, 
                                fontWeight: FontWeight.bold,
                                fontSize: fontstyle.monthFontSize.sp * 0.5,
                              ),
                              items: manager.availableVersions
                                  .map((v) => DropdownMenuItem(
                                        value: v['code'],
                                        child: Text(v['name']!),
                                      ))
                                  .toList(),
                              onChanged: (newVersion) {
                                if (newVersion != null) {
                                  manager.changeVersion(newVersion);
                                }
                              },
                            );
                    },
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              ListView.builder(
                key: _listViewKey,
                padding: const EdgeInsets.all(20),
                itemCount: verses.length,
                itemBuilder: (context, i) {
                  final Map<String, dynamic> v = verses[i];
                  final int verseNum = v['verse'] as int;          // ← now safe
                  final String text = v['text'] as String;          // ← now safe

                  // Create a key for this verse (so we can scroll to it later)
                  final GlobalKey verseKey = GlobalKey();
                  _verseKeys[verseNum] = verseKey;

                  final bool isSelected = _selectedVerses.contains(verseNum);
                  final Color? highlightColor = highlightManager.getHighlightColor(
                    widget.bookName,
                    widget.chapterNum,
                    verseNum,
                  );

                  return InkWell(
                    key: verseKey,
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _selectedVerses.add(verseNum));
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
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.primary.withOpacity(0.2) : highlightColor?.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        decoration: BoxDecoration(
                          color: highlightColor?.withOpacity(isSelected ? 0.4 : 0.3),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: textTheme.bodyLarge?.copyWith(
                            //style: TextStyle(
                              //fontSize: 17,
                              fontSize: fontstyle.monthFontSize.sp * 0.9,
                              height: 1.5,
                              color: isSelected ? colorScheme.primary : colorScheme.onBackground,
                              //fontWeight: isSelected ? colorScheme.primary : colorScheme.onBackground,
                            ),
                            children: [
                              TextSpan(
                                text: "$verseNum. ",
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primaryContainer,
                                  fontSize: fontstyle.monthFontSize.sp * 0.8,
                                ),
                                /*style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryContainer,
                                  fontSize: 12,
                                ),*/
                              ),
                              TextSpan(text: text),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Beautiful VerseActionSheet with multi-select support
              if (_selectedVerses.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: VerseActionSheet(
                    bookName: widget.bookName,
                    chapter: widget.chapterNum,
                    verses: _selectedVerses.toList()..sort(),
                    versesText: {
                      for (var v in verses) v['verse'] as int: v['text'] as String,
                    },
                  ),
                ),

              // Navigation arrows (your existing one)
              ChapterNavigationButtons(
                bookName: widget.bookName,
                currentChapter: widget.chapterNum,
                totalChapters: widget.totalChapters,
              ),
            ],
          ),
        );
      },
    );
  }
}

// Add this class — you can put it at the bottom of bible_page.dart or in a new file
class ChapterNavigationButtons extends StatelessWidget {
  final String bookName;
  final int currentChapter;
  final int totalChapters;

  const ChapterNavigationButtons({
    super.key,
    required this.bookName,
    required this.currentChapter,
    required this.totalChapters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final style = CalendarDayStyle.fromContainer(context, 50);

    final manager = Provider.of<BibleVersionManager>(context, listen: false);
    final books = manager.books;
    // Find current book index
    final int bookIndex = books.indexWhere((b) => b['name'] == bookName);
    if (bookIndex == -1) return const SizedBox.shrink();

    // Helper to navigate to a specific book/chapter
    void goToChapter(int targetBookIndex, int targetChapter) {
      if (targetBookIndex < 0 || targetBookIndex >= books.length) return;
      final targetBook = books[targetBookIndex] as Map<String, dynamic>;
      final chaptersList = targetBook['chapters'] as List<dynamic>;
      if (targetChapter < 1 || targetChapter > chaptersList.length) return;

      // Save AFTER checks, BEFORE navigation
      LastPositionManager.save(
        bookName: targetBook['name'].toString(),
        chapter: targetChapter,
        screen: 'chapter',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChapterReader(
            chapterData: chaptersList[targetChapter - 1],  // Now safe!
            bookName: targetBook['name'] as String,
            chapterNum: targetChapter,
            totalChapters: chaptersList.length,  // Pass it forward!
          ),
        ),
      );
    }

    // Previous chapter logic
    void goPrevious() {
      if (currentChapter > 1) {
        goToChapter(bookIndex, currentChapter - 1);
      } else if (bookIndex > 0) {
        // Go to last chapter of previous book
        final prevBook = books[bookIndex - 1];
        final prevChapters = prevBook['chapters'] as List;
        goToChapter(bookIndex - 1, prevChapters.length);
      }
    }

    // Next chapter logic
    void goNext() {
      if (currentChapter < totalChapters) {
        goToChapter(bookIndex, currentChapter + 1);
      } else if (bookIndex < books.length - 1) {
        // Go to first chapter of next book
        goToChapter(bookIndex + 1, 1);
      }
    }

    final bool hasPrevious = currentChapter > 1 || bookIndex > 0;
    final bool hasNext = currentChapter < totalChapters || bookIndex < books.length - 1;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: 120.sp),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Arrow - Previous
            Opacity(
              opacity: hasPrevious ? 0.85 : 0.25,
              child: Container(
                margin: EdgeInsets.only(left: 24.sp),
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  shape: BoxShape.circle,
                  /*boxShadow: [
                    BoxShadow(
                      color: AppColors.darkBackground, 
                      blurRadius: style.monthFontSize.sp, 
                      offset: Offset(0, 2),
                    ),
                  ],*/
                ),
                child: IconButton(
                  iconSize: style.monthFontSize.sp,
                  onPressed: hasPrevious ? goPrevious : null,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: colorScheme.onSecondary,
                ),
              ),
            ),
            // Right Arrow - Next
            Opacity(
              opacity: hasNext ? 0.85 : 0.25,
              child: Container(
                margin: EdgeInsets.only(right: 24.sp),
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  shape: BoxShape.circle,
                  /*boxShadow: [
                    BoxShadow(
                      color: AppColors.darkBackground, 
                      blurRadius: style.monthFontSize.sp, 
                      offset: Offset(0, 1),
                    ),
                  ],*/
                ),
                child: IconButton(
                  iconSize: style.monthFontSize.sp,
                  onPressed: hasNext ? goNext : null,
                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                  color: colorScheme.onSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}