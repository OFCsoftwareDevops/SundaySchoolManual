// lib/widgets/verse_popup.dart
import 'package:flutter/material.dart';

class VersePopup extends StatelessWidget {
  final String reference;
  final List<Map<String, dynamic>> verses;
  final String? rawText;

  const VersePopup({
    super.key, 
    required this.reference,
    required this.verses,
    this.rawText,
  });

  /*List<TextSpan> _buildVerseSpans(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'^(\d+)\s+(.*)$', multiLine: true);
    
    final lines = text.split('\n');
    for (final line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        spans.add(TextSpan(
          text: match.group(1), // verse number
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 94, 17, 17),
            fontSize: 12,
          ),
        ));
        spans.add(TextSpan(text: ' ${match.group(2)}\n'));
      } else {
        spans.add(TextSpan(text: '$line\n'));
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340, maxHeight: 620),
        child: Material(
          color: Colors.white,
          elevation: 12,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reference header
                Text(
                  reference,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 94, 17, 17),
                  ),
                ),
                const SizedBox(height: 16),

                // Exact same text style as your Bible
                Flexible(
                  child: Scrollbar(
                    thickness: 6,
                    radius: const Radius.circular(10),
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(right: 12),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                          children: _buildVerseSpans(verseText),
                          /*children: [
                            TextSpan(
                              text: verseText.split(' ').first, // verse number
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 94, 17, 17),
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(
                              text: verseText.substring(verseText.indexOf(' ')),
                            ),
                          ],*/
                        ),
                      ),
                    ),
                  ),
                ),
                      /*child: Text(
                        verseText,
                        style: const TextStyle(fontSize: 18, height: 1.75),
                      ),
                    ),
                  ),
                ),*/

                const SizedBox(height: 24),

                // Close button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Return",
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 94, 17, 17),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}*/

  // REPLACED: build spans from the passed list of verse maps
  List<TextSpan> _buildVerseSpansFromList(List<Map<String, dynamic>> verses) {
    final spans = <TextSpan>[];

    for (final v in verses) {
      final verseNum = v['verse']?.toString() ?? '';
      final text = (v['text'] ?? '').toString();
      final highlighted = (v['highlighted'] ?? false) as bool;

      // verse number
      spans.add(TextSpan(
        text: '$verseNum ',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 94, 17, 17),
          fontSize: 14,
        ),
      ));

      // verse text (apply subtle background if highlighted)
      spans.add(TextSpan(
        text: '$text\n',
        style: TextStyle(
          color: const Color.fromARGB(255, 0, 0, 0),
          fontSize: 17,
          height: 1.5,
          backgroundColor: highlighted ? const Color.fromARGB(80, 255, 229, 180) : null,
        ),
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340, maxHeight: 620),
        child: Material(
          color: Colors.white.withOpacity(01),
          elevation: 12,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reference header
                Text(
                  reference,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 94, 17, 17),
                  ),
                ),
                const SizedBox(height: 16),

                // Use the new builder that accepts the list
                Flexible(
                  child: Scrollbar(
                    thickness: 6,
                    radius: const Radius.circular(10),
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(right: 12),
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

                const SizedBox(height: 24),

                // Close button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Return",
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 94, 17, 17),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}