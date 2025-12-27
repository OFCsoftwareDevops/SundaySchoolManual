// lib/backend_data/lesson_data.dart

class LessonDay {
  final DateTime date;
  final SectionNotes? teenNotes;
  final SectionNotes? adultNotes;

  const LessonDay({
    required this.date,
    this.teenNotes,
    this.adultNotes,
  });
}

class SectionNotes {
  final String topic;
  final String biblePassage;
  final List<ContentBlock> blocks;

  const SectionNotes({
    required this.topic,
    required this.biblePassage,
    required this.blocks,
  });

  // Empty constructor for editor
  factory SectionNotes.empty() => SectionNotes(
        topic: "",
        biblePassage: "",
        blocks: [],
      );

  Map<String, dynamic> toMap() => {
        'topic': topic,
        'biblePassage': biblePassage,
        'blocks': blocks.map((b) => b.toMap()).toList(),
      };

  factory SectionNotes.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawBlocks = map['blocks'] as List<dynamic>? ?? [];

    return SectionNotes(
      topic: map['topic'] as String? ?? '',
      biblePassage: map['biblePassage'] as String? ?? '',
      blocks: rawBlocks
          .map((e) => ContentBlock.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  // Helper: check if completely empty
  bool get isEmpty => topic.trim().isEmpty && blocks.isEmpty;
}

class ContentBlock {
  final String type;
  final String? text;
  final List<String>? items;
  final String? videoUrl;

  const ContentBlock({
    required this.type,
    this.text,
    this.items,
    this.videoUrl,
  });

  // Named constructors
  factory ContentBlock.heading(String text) => ContentBlock(type: "heading", text: text);
  factory ContentBlock.text(String text) => ContentBlock(type: "text", text: text);
  factory ContentBlock.memoryVerse(String text) => ContentBlock(type: "memory_verse", text: text);
  factory ContentBlock.numberedList(List<String> items) => ContentBlock(type: "numbered_list", items: items);
  factory ContentBlock.bulletList(List<String> items) => ContentBlock(type: "bullet_list", items: items);
  factory ContentBlock.quote(String text) => ContentBlock(type: "quote", text: text);
  factory ContentBlock.prayer(String text) => ContentBlock(type: "prayer", text: text);
  factory ContentBlock.video(String url) => ContentBlock(type: "video", videoUrl: url);

  // Fixed toMap()
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'type': type};
    if (text != null) map['text'] = text!;
    if (items != null) map['items'] = items!;
    if (videoUrl != null) map['videoUrl'] = videoUrl!;
    return map;
  }

  // Fixed fromMap()
  factory ContentBlock.fromMap(Map<String, dynamic> map) {
    return ContentBlock(
      type: map['type'] as String,
      text: map['text'] as String?,
      items: map['items'] != null ? List<String>.from(map['items'] as List) : null,
      videoUrl: map['videoUrl'] as String?,
    );
  }

  // Fixed copyWith (no videoUrl promotion issue)
  ContentBlock copyWith({
    String? text,
    List<String>? items,
  }) {
    return ContentBlock(
      type: type,
      text: text ?? this.text,
      items: items ?? this.items,
      videoUrl: videoUrl,
    );
  }
}