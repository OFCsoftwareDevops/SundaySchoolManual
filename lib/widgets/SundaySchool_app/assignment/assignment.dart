// models/assignment.dart
import 'package:flutter/material.dart';

import '../../../backend_data/lesson_data.dart';

class Assignment {
  final String date;        // "2025-12-07"
  final String title;
  final String topic;
  final String passage;

  const Assignment({
    required this.date,
    required this.title,
    required this.topic,
    this.passage = "",
  });
}

/*class AssignmentFromLesson extends StatelessWidget {
  final SectionNotes data;

  const AssignmentFromLesson({required this.data});

  @override
  Widget build(BuildContext context) {
    // Cherche le bloc "assignment"
    final assignmentBlock = data.blocks.firstWhere(
      (b) => b.type == "assignment",
      orElse: () => ContentBlock(type: "", text: null),
    );

    if (assignmentBlock.text == null || assignmentBlock.text!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 32, bottom: 16),
          child: Text(
            "This Week’s Assignment",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade50, Colors.deepPurple.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.deepPurple.shade300, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_turned_in_rounded, size: 32, color: Colors.deepPurple),
                  const SizedBox(width: 12),
                  Text(
                    assignmentBlock.text!,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Affiche le texte qui suit le bloc "assignment" (le vrai devoir)
              ...data.blocks.skipWhile((b) => b.type != "assignment").skip(1).take(3).map((b) {
                if (b.type == "text" && b.text != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      b.text!,
                      style: const TextStyle(fontSize: 17, height: 1.6),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}*/