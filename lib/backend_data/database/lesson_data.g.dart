// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonDayAdapter extends TypeAdapter<LessonDay> {
  @override
  final int typeId = 0;

  @override
  LessonDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LessonDay(
      date: fields[0] as DateTime,
      teenNotes: fields[1] as SectionNotes?,
      adultNotes: fields[2] as SectionNotes?,
    );
  }

  @override
  void write(BinaryWriter writer, LessonDay obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.teenNotes)
      ..writeByte(2)
      ..write(obj.adultNotes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SectionNotesAdapter extends TypeAdapter<SectionNotes> {
  @override
  final int typeId = 1;

  @override
  SectionNotes read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SectionNotes(
      topic: fields[0] as String,
      biblePassage: fields[1] as String,
      blocks: (fields[2] as List).cast<ContentBlock>(),
    );
  }

  @override
  void write(BinaryWriter writer, SectionNotes obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.topic)
      ..writeByte(1)
      ..write(obj.biblePassage)
      ..writeByte(2)
      ..write(obj.blocks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionNotesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContentBlockAdapter extends TypeAdapter<ContentBlock> {
  @override
  final int typeId = 2;

  @override
  ContentBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContentBlock(
      type: fields[0] as String,
      text: fields[1] as String?,
      items: (fields[2] as List?)?.cast<String>(),
      videoUrl: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ContentBlock obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.videoUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
