// widgets/verse_action_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'highlight/highlight_manager.dart';


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

  final List<Color> colors = [
    const Color.fromARGB(255, 228, 214, 87),
    const Color.fromARGB(255, 233, 94, 140),
    const Color.fromARGB(255, 111, 208, 220),
    const Color.fromARGB(255, 120, 218, 123),
    const Color.fromARGB(255, 234, 178, 96),
    const Color.fromARGB(255, 209, 108, 227),
  ];

  @override
  Widget build(BuildContext context) {
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 16),
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
              _Action(icon: Icons.bookmark_border, label: "Bookmark", onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bookmark coming soon")));
              }),
            ],
          ),

          // Color Picker — same beautiful animation
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showColorPicker
              ? Column(
                children: [
                  const SizedBox(height: 16),
                  const Text("Highlight color", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
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
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black87 : Colors.white,
                              width: isSelected ? 4 : 2,
                            ),
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.black87, size: 28) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
              )
            : const SizedBox.shrink(),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF5D8668).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: const Color(0xFF5D8668)),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}