/*import 'package:flutter/material.dart';
import '../backend_data/lesson_data.dart';

class TeenPage extends StatelessWidget {
  final SectionNotes data;

  const TeenPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teen Lesson")),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _section("Topic", data.topic),
        _section("Memory Verse", data.memoryVerse),
        _section("Introduction", data.introduction),
        _section("Outline", data.outline as String),
      ],
    );
  }

  Widget _section(String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
*/