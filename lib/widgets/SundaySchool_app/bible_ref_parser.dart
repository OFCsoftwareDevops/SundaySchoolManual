// lib/utils/bible_ref_parser.dart
final RegExp bibleRefRegex = RegExp(
  r'\b([1-3]?\s?[A-Za-z]+)\s+(\d+):(\d+)(?:-(\d+))?(?:\s*\((\w+)\))?\b',
  caseSensitive: false,
);

class BibleRef {
  final String book;
  final int chapter;
  final int verseStart;
  final int? verseEnd;
  final String? version;

  BibleRef(this.book, this.chapter, this.verseStart, [this.verseEnd, this.version]);

  @override
  String toString() => '$book $chapter:$verseStart${verseEnd != null ? '-$verseEnd' : ''}';
}

List<BibleRef> findBibleReferences(String text) {
  return bibleRefRegex.allMatches(text).map((match) {
    String book = match.group(1)!
        .replaceAllMapped(RegExp(r'\s+'), (m) => ' ')
        .trim();
    int chapter = int.parse(match.group(2)!);
    int start = int.parse(match.group(3)!);
    int? end = match.group(4) != null ? int.parse(match.group(4)!) : null;
    String? version = match.group(5);

    // Normalize book names
    final normalized = {
      '1 john': '1 John', 
      '2 john': '2 John', 
      '3 john': '3 John',
      'song of solomon': 'Song of Solomon', 
      'psalm': 'Psalms',
    }[book.toLowerCase()] ?? book;

    return BibleRef(normalized, chapter, start, end, version);
  }).toList();
}