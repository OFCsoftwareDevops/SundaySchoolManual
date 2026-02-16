// lib/backend_data/lesson_data.dart

import 'package:hive/hive.dart';

part 'lesson_data.g.dart';

@HiveType(typeId: 0)
class LessonDay extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final SectionNotes? teenNotes;

  @HiveField(2)
  final SectionNotes? adultNotes;

  LessonDay({
    required this.date,
    this.teenNotes,
    this.adultNotes,
  });
}

@HiveType(typeId: 1)
class SectionNotes extends HiveObject {
  @HiveField(0)
  final String topic;

  @HiveField(1)
  final String biblePassage;

  @HiveField(2)
  final List<ContentBlock> blocks;

  SectionNotes({
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

@HiveType(typeId: 2)
class ContentBlock extends HiveObject {
  @HiveField(0)
  final String type;

  @HiveField(1)
  final String? text;

  @HiveField(2)
  final List<String>? items;

  @HiveField(3)
  final String? videoUrl;

  ContentBlock({
    required this.type,
    this.text,
    this.items,
    this.videoUrl,
  });

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