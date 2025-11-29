// lib/screens/lesson_preview.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../backend_data/lesson_data.dart';

class BeautifulLessonPage extends StatelessWidget {
  final SectionNotes data;
  final String title;

  const BeautifulLessonPage({
    super.key,
    required this.data,
    required this.title,
  });

  // ← the rest of the file is 100% identical to the previous message
  // (share function + _buildBlock + full build method)

  void _shareLesson() {
    final buffer = StringBuffer();
    buffer.writeln("*$title*");
    buffer.writeln("${data.topic}");
    if (data.biblePassage.isNotEmpty) buffer.writeln("_${data.biblePassage}_");
    buffer.writeln();

    for (var block in data.blocks) {
      switch (block.type) {
        case "heading": buffer.writeln("\n*${block.text}*"); break;
        case "text": buffer.writeln("${block.text}\n"); break;
        case "memory_verse": buffer.writeln("Memory Verse\n“${block.text}”\n"); break;
        case "numbered_list":
          for (var i = 0; i < block.items!.length; i++) {
            buffer.writeln("${i + 1}. ${block.items![i]}");
          }
          buffer.writeln();
          break;
        case "bullet_list":
          block.items!.forEach((item) => buffer.writeln("• $item"));
          buffer.writeln();
          break;
        case "quote": buffer.writeln("> ${block.text}\n"); break;
        case "prayer": buffer.writeln("Prayer\n${block.text}"); break;
      }
    }

    Share.share(buffer.toString(), subject: "$title: ${data.topic}");
  }

  Widget _buildBlock(ContentBlock block) {
    // ← exact same _buildBlock from the previous message (heading, text, memory_verse, numbered_list, bullet_list, quote, prayer)
    switch (block.type) {
      case "heading":
        return Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 12),
          child: Text(block.text!, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
        );
      case "text":
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(block.text!, style: const TextStyle(fontSize: 17, height: 1.6)),
        );
      case "memory_verse":
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
              border: const Border(left: BorderSide(color: Colors.deepPurple, width: 5)),
            ),
            child: Text(block.text!, style: const TextStyle(fontSize: 18, height: 1.7, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
          ),
        );
      case "numbered_list":
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            children: block.items!.asMap().entries.map((e) {
              final i = e.key + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                      child: Center(child: Text('$i', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text(e.value, style: const TextStyle(fontSize: 17, height: 1.5))),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      case "bullet_list":
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: block.items!.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(fontSize: 17)),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 17, height: 1.5))),
                ],
              ),
            )).toList(),
          ),
        );
      case "quote":
        return Container(
          margin: const EdgeInsets.only(bottom: 32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
          child: Text(block.text!, style: const TextStyle(fontSize: 17, fontStyle: FontStyle.italic, height: 1.6)),
        );
      case "prayer":
        return Container(
          margin: const EdgeInsets.only(bottom: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              const Text("Prayer", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(block.text!, style: const TextStyle(fontSize: 17, height: 1.6)),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _shareLesson,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.share_rounded),
        label: const Text("Share Lesson"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20), onPressed: () => Navigator.pop(context)),
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 20),
              Text(data.topic, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w300, height: 1.2)),
              if (data.biblePassage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(data.biblePassage, style: const TextStyle(fontSize: 18, color: Colors.black54, fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 50),
              ...data.blocks.map(_buildBlock),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}