// lib/widgets/verse_popup.dart
import 'package:app_demo/UI/app_colors.dart';
import 'package:flutter/material.dart';
import '../bible_app/version/version_picker.dart';

class VersePopup extends StatelessWidget {
  final String reference;
  final List<Map<String, dynamic>> verses;
  final String? rawText;
  final double heightFraction; // fraction of screen height

  const VersePopup({
    super.key,
    required this.reference,
    required this.verses,
    this.rawText,
    this.heightFraction = 0.40, // default 60% of screen height
  });

  List<TextSpan> _buildVerseSpansFromList(List<Map<String, dynamic>> verses) {
    final spans = <TextSpan>[];
    for (final v in verses) {
      final verseNum = v['verse']?.toString() ?? '';
      final text = (v['text'] ?? '').toString();
      final highlighted = (v['highlighted'] ?? false) as bool;

      spans.add(TextSpan(
        text: '$verseNum ',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryContainer,
          fontSize: 14,
        ),
      ));

      spans.add(TextSpan(
        text: '$text\n\n',
        style: TextStyle(
          color: AppColors.grey900,
          fontSize: 17,
          height: 1.5,
          backgroundColor: highlighted
              ? AppColors.grey100
              : null,
        ),
      ));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * heightFraction;

    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            /*/ drag handle
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.onBackground,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 5),*/
            // version picker
            const VersionPicker(
              iconColor: Colors.black,
              textColor: Colors.black,
            ),
            const SizedBox(height: 5),
            // Reference header
            Text(
              reference,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryContainer,
              ),
            ),
            const SizedBox(height: 10),
            // Scrollable content
            Expanded(
              child: Scrollbar(
                thickness: 6,
                radius: const Radius.circular(10),
                thumbVisibility: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 5),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                      children: _buildVerseSpansFromList(verses),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

