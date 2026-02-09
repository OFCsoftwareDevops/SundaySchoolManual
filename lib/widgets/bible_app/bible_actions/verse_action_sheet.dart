// widgets/verse_action_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rccg_sunday_school/UI/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import '../../../utils/device_check.dart';
import '../../../l10n/app_localizations.dart';
import '../../helpers/snackbar.dart';
import 'highlight_manager.dart';
import '../../../../auth/login/auth_service.dart';
import '../../../backend_data/service/firestore/saved_items_service.dart';
import 'package:firebase_auth/firebase_auth.dart';


class VerseActionSheet extends StatefulWidget {
  final String bookName;
  final int chapter;
  final List<int> verses;           // ← Now accepts multiple verses
  final Map<int, String> versesText;
  final VoidCallback? onActionComplete;

  const VerseActionSheet({
    super.key,
    required this.bookName,
    required this.chapter,
    required this.verses,
    required this.versesText,
    this.onActionComplete,
  });

  @override
  State<VerseActionSheet> createState() => _VerseActionSheetState();
}

class _VerseActionSheetState extends State<VerseActionSheet> {
  //bool _showColorPicker = false;
  bool _isBookmarked = false;
  bool _isCheckingBookmark = true;

  final List<Color> colors = [
    const Color.fromARGB(255, 228, 214, 87),
    const Color.fromARGB(255, 233, 94, 140),
    const Color.fromARGB(255, 111, 208, 220),
    const Color.fromARGB(255, 120, 218, 123),
    const Color.fromARGB(255, 234, 178, 96),
    const Color.fromARGB(255, 209, 108, 227),
  ];

  @override
  void initState() {
    super.initState();
    _checkIfBookmarked();
  }

  Future<void> _checkIfBookmarked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isCheckingBookmark = false);
      return;
    }

    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.churchId == null) {
      setState(() => _isCheckingBookmark = false);
      return;
    }

    final service = SavedItemsService();

    // Create the same refId we use when saving
    final sorted = widget.verses..sort();
    final refId = '${widget.bookName.toLowerCase().replaceAll(' ', '_')}_${widget.chapter}_${sorted.join('-')}';

    final exists = await service.isBookmarked(user.uid, refId);

    if (mounted) {
      setState(() {
        _isBookmarked = exists;
        _isCheckingBookmark = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final user = FirebaseAuth.instance.currentUser!;
    final service = SavedItemsService();
    final userId = user.uid;
    final isAnonymous = user.isAnonymous;

    // Same refId logic as before
    final sorted = List<int>.from(widget.verses)..sort();
    final refId = '${widget.bookName.toLowerCase().replaceAll(' ', '_')}_${widget.chapter}_${sorted.join('-')}';
    final reference = sorted.length == 1
        ? "${widget.bookName} ${widget.chapter}:${sorted.first}"
        : "${widget.bookName} ${widget.chapter}:${sorted.first}–${sorted.last}";

    final fullText = sorted.map((v) => "$v ${widget.versesText[v]}").join("\n");

    try {
      if (_isBookmarked) {
        // ── REMOVE ────────────────────────────────────────
        // Optimistic remove from cache
        final current = service.getCachedItems(userId, 'bookmarks');
        final updated = current.where((b) => b['refId'] != refId).toList();
        await service.cacheItems(userId, 'bookmarks', updated);

        // Only real users delete from Firestore
        if (!isAnonymous) {
          await service.removeBookmark(userId, refId);
        }

        setState(() => _isBookmarked = false);
        showTopToast(
          context,
          AppLocalizations.of(context)?.bookmarkRemoved ?? "Bookmark removed",
        );
      } else {
        // ── ADD ───────────────────────────────────────────
        final now = DateTime.now().toUtc();

        final newItem = <String, dynamic>{
          'type': 'scripture',
          'refId': refId,
          'title': reference,
          'text': fullText,
          'createdAt': now.toIso8601String(), // Hive-safe
        };

        if (isAnonymous) {
          // Anonymous: local only + fake ID
          final fakeId = 'local_${now.millisecondsSinceEpoch}';
          newItem['id'] = fakeId;

          final current = service.getCachedItems(userId, 'bookmarks');
          final updated = [newItem, ...current];
          await service.cacheItems(userId, 'bookmarks', updated);
        } else {
          // Real user: Firestore + cache
          final docId = await service.addBookmark(
            userId,
            refId: refId,
            title: reference,
            text: fullText,
          );

          newItem['id'] = docId;

          final current = service.getCachedItems(userId, 'bookmarks');
          final updated = [newItem, ...current];
          await service.cacheItems(userId, 'bookmarks', updated);
        }

        setState(() => _isBookmarked = true);
        showTopToast(
          context,
          "${AppLocalizations.of(context)?.bookmarked ?? "Bookmarked"} ⭐",
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e, stack) {
      debugPrint("Bookmark toggle failed: $e\n$stack");
      showTopToast(
        context,
        AppLocalizations.of(context)?.operationFailed ?? "Operation failed",
        backgroundColor: AppColors.error,
        textColor: AppColors.onError,
        duration: const Duration(seconds: 5),
      );
    }
  }

  /*Future<void> _toggleBookmark() async {
    final user = FirebaseAuth.instance.currentUser;
    final auth = Provider.of<AuthService>(context, listen: false);

    if (user == null || auth.churchId == null) {
      showTopToast(
        context,
        AppLocalizations.of(context)?.signInAndJoinToBookmarks ?? "Sign in and join a church to save bookmarks",
      );
      return;
    }

    final service = SavedItemsService();
    // Same refId logic
    final sorted = List<int>.from(widget.verses)..sort();
    final refId = '${widget.bookName.toLowerCase().replaceAll(' ', '_')}_${widget.chapter}_${sorted.join('-')}';
    final reference = sorted.length == 1
        ? "${widget.bookName} ${widget.chapter}:${sorted.first}"
        : "${widget.bookName} ${widget.chapter}:${sorted.first}–${sorted.last}";

    final fullText = sorted.map((v) => "$v ${widget.versesText[v]}").join("\n");

    try {
      if (_isBookmarked) {
        // REMOVE
        await service.removeBookmarkByRefId(user.uid, refId);
        setState(() => _isBookmarked = false);
        showTopToast(
          context,
          AppLocalizations.of(context)?.bookmarkRemoved ?? "Bookmark removed",
        );
      } else {
        // ADD
        await service.addBookmark(
          user.uid,
          refId: refId,
          title: reference,
          text: fullText,
          // note: null,   ← you can also let user add note later
        );
        setState(() => _isBookmarked = true);
        showTopToast(
          context,
          "${AppLocalizations.of(context)?.bookmarked ?? "Bookmarked"} ⭐",
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      showTopToast(
        context,
        AppLocalizations.of(context)?.operationFailed ?? "Operation failed",
        backgroundColor: AppColors.error,
        textColor: AppColors.onError,
        duration: const Duration(seconds: 5),
      );
    }
  }*/

  Future<void> _applyHighlight(Color color) async {
    final manager = Provider.of<HighlightManager>(context, listen: false);
    final sorted = List<int>.from(widget.verses)..sort();

    for (final v in sorted) {
      manager.addOrUpdateHighlight(   // Changed to addOrUpdate for consistency
        book: widget.bookName,
        chapter: widget.chapter,
        verse: v,
        color: color,
      );
    }
    HapticFeedback.selectionClick();
    widget.onActionComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final highlightColorContainer = context.highlightColorContainer;
    final mySizedBoxHeight = context.mySizedBoxHeight;

    final manager = Provider.of<HighlightManager>(context, listen: false);

    // Smart reference
    final sorted = widget.verses..sort();
    final reference = sorted.length == 1
      ? "${widget.bookName} ${widget.chapter}:${sorted.first}"
      : "${widget.bookName} ${widget.chapter}:${sorted.first}–${sorted.last}";

    // Full text with verse numbers
    final fullText = sorted.map((v) => "$v ${widget.versesText[v]}").join("\n");

    // Check if ALL selected verses have the same highlight color
    final colorsInUse = sorted.map((v) => manager.getHighlightColor(widget.bookName, widget.chapter, v)).toSet();
    final hasMixedColors = colorsInUse.length > 1;
    final currentColor = colorsInUse.length == 1 ? colorsInUse.first : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(2.sp)),
      ),
      padding: EdgeInsets.only(
        left: 20.sp,
        right: 20.sp,
        top: 10.sp,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10.sp,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 30.sp, 
            height: 5.sp, 
            decoration: BoxDecoration(
              color: colorScheme.onBackground.withOpacity(0.5), 
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: 10.sp),

          // ← NEW: Selected count header
          Text(
            "${widget.verses.length} ${widget.verses.length == 1 ? (AppLocalizations.of(context)?.verseSelected ?? "verse selected") : (AppLocalizations.of(context)?.versesSelected ?? "verses selected")}",
            style: TextStyle(
              fontSize: 10.sp,
              color: colorScheme.onBackground,
            ),
          ),
          // Verse preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Action(
                icon: Icons.content_copy, 
                label: AppLocalizations.of(context)?.copy ?? "Copy",
                onTap: () {
                  Clipboard.setData(ClipboardData(text: "$reference\n\n$fullText"));
                  showTopToast(
                    context,
                    AppLocalizations.of(context)?.copied ?? "Copied!",
                    backgroundColor: AppColors.error,
                    textColor: AppColors.onError,
                    duration: const Duration(seconds: 5),
                  );
                  widget.onActionComplete?.call();
                },
              ),
              _Action(
                icon: Icons.share, 
                label: AppLocalizations.of(context)?.share ?? "Share", 
                onTap: () {
                  Share.share("$reference\n\n$fullText");
                  widget.onActionComplete?.call();           
                },
              ),
              _Action(
                icon: _isCheckingBookmark
                    ? Icons.hourglass_empty
                    : (_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                label: _isBookmarked ? (AppLocalizations.of(context)?.bookmarked ?? "Bookmarked") : (AppLocalizations.of(context)?.bookmark ?? "Bookmark"),
                color: _isBookmarked ? const Color(0xFF5D8668) : null, // green when saved
                onTap: () async {
                  await _toggleBookmark();
                  widget.onActionComplete?.call();           // ← CLOSE + DESELECT after toggle
                },
              ),
            ],
          ),
          Divider(
            color: colorScheme.onBackground.withOpacity(0.2),
            thickness: 1.sp,
          ),
          SizedBox(height: mySizedBoxHeight),
          Wrap(
            spacing: 16.sp,
            runSpacing: 16.sp,
            alignment: WrapAlignment.center,
            children: colors.map((color) {
              final isSelected = currentColor == color && !hasMixedColors;
              return GestureDetector(
                onTap: () => _applyHighlight(color),
                child: Container(
                  width: highlightColorContainer,
                  height: highlightColorContainer,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.transparent,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6.sp,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: mySizedBoxHeight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  for (final v in sorted) {
                    manager.removeHighlight(widget.bookName, widget.chapter, v);
                  }
                  widget.onActionComplete?.call();
                },
                child: Text(
                  AppLocalizations.of(context)?.removeHighlight ?? "Remove highlight", 
                  style: TextStyle(
                    color: colorScheme.onBackground,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              TextButton(
                onPressed: widget.onActionComplete,
                child: Text(
                  AppLocalizations.of(context)?.cancel ?? "Cancel",
                  style: TextStyle(
                    color: colorScheme.error, 
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// MAKE THIS DYNAMIC FOR TABLET/MOBILE LATER

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _Action({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16.sp),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16.sp, 10.sp, 16.sp, 10.sp),
            decoration: BoxDecoration(
              color: colorScheme.background,
              borderRadius: BorderRadius.circular(10.sp),
            ),
            child: Icon(
              icon, 
              size: 20.sp, 
              color: AppColors.primaryContainer,
            ),
          ),
          Text(label, style: TextStyle(
            fontSize: 13.sp, 
            fontWeight: FontWeight.w400,
          )),
        ],
      ),
    );
  }
}