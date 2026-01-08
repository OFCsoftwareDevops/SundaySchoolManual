// widgets/verse_action_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rccg_sunday_school/UI/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'highlight_manager.dart';
import '../../../../auth/login/auth_service.dart';
import '../../../backend_data/service/saved_items_service.dart';
import 'package:firebase_auth/firebase_auth.dart';


class VerseActionSheet extends StatefulWidget {
  final String bookName;
  final int chapter;
  final List<int> verses;           // ← Now accepts multiple verses
  final Map<int, String> versesText;

  const VerseActionSheet({
    super.key,
    required this.bookName,
    required this.chapter,
    required this.verses,
    required this.versesText,
  });

  @override
  State<VerseActionSheet> createState() => _VerseActionSheetState();
}

class _VerseActionSheetState extends State<VerseActionSheet> {
  bool _showColorPicker = false;
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
    final user = FirebaseAuth.instance.currentUser;
    final auth = Provider.of<AuthService>(context, listen: false);

    if (user == null || auth.churchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign in and join a church to save bookmarks")),
      );
      return;
    }

    if (_isBookmarked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Already bookmarked! ⭐")),
      );
      return;
    }

    final service = SavedItemsService();

    final sorted = widget.verses..sort();
    final reference = sorted.length == 1
        ? "${widget.bookName} ${widget.chapter}:${sorted.first}"
        : "${widget.bookName} ${widget.chapter}:${sorted.first}–${sorted.last}";

    final fullText = sorted.map((v) => "$v ${widget.versesText[v]}").join("\n");

    final refId = '${widget.bookName.toLowerCase().replaceAll(' ', '_')}_${widget.chapter}_${sorted.join('-')}';

    try {
      await service.addBookmark(
        user.uid,
        refId: refId,
        title: reference,
        text: fullText,
      );

      setState(() => _isBookmarked = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bookmarked! ⭐")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to bookmark: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.sp,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40.sp, height: 5.sp, decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(10))),
          SizedBox(height: 10.sp),
          // Verse preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Action(icon: Icons.content_copy, label: "Copy", onTap: () {
                Clipboard.setData(ClipboardData(text: "$reference\n\n$fullText"));
                //Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!")));
              }),
              _Action(icon: Icons.share, label: "Share", onTap: () => Share.share("$reference\n\n$fullText")),
              _Action(
                icon: currentColor != null ? Icons.highlight : Icons.highlight_outlined,
                label: currentColor != null ? "Highlighted" : "Highlight",
                onTap: () => setState(() => _showColorPicker = !_showColorPicker),
              ),
              _Action(
                icon: _isCheckingBookmark
                    ? Icons.hourglass_empty
                    : (_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                label: _isBookmarked ? "Bookmarked" : "Bookmark",
                color: _isBookmarked ? const Color(0xFF5D8668) : null, // green when saved
                onTap: _toggleBookmark,),
            ],
          ),

          // Color Picker — same beautiful animation
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showColorPicker
              ? Column(
                children: [
                  SizedBox(height: 10.sp),
                  Text("Highlight color", 
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    )),
                  SizedBox(height: 10.sp),
                  Wrap(
                    spacing: 16.sp,
                    runSpacing: 16.sp,
                    alignment: WrapAlignment.center,
                    children: colors.map((color) {
                      final isSelected = currentColor == color;
                      return GestureDetector(
                        onTap: () {
                          // Apply SAME color to ALL selected verses
                          for (final v in sorted) {
                            manager.toggleHighlight(
                              book: widget.bookName,
                              chapter: widget.chapter,
                              verse: v,
                              color: color,
                            );
                          }
                          // Hide color picker instantly, but keep the whole sheet open
                          setState(() => _showColorPicker = false);
                          HapticFeedback.selectionClick();
                        },
                        child: Container(
                          width: 40.sp,
                          height: 40.sp,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.darkSurface : const Color.fromARGB(0, 52, 72, 98),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: isSelected ? Icon(Icons.check, color: AppColors.darkSurface , size: 28.sp) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10.sp),
                ],
              )
            : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

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
            padding: EdgeInsets.all(16.sp),
            decoration: BoxDecoration(
              color: colorScheme.background,
              borderRadius: BorderRadius.circular(10.sp),
            ),
            child: Icon(icon, size: 28.sp, color: AppColors.primaryContainer),
          ),
          SizedBox(height: 6.sp),
          Text(label, style: TextStyle(
            fontSize: 14.sp, 
            fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }
}