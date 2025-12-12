// models/assignment.dart
// FILE NOT USED
import 'package:flutter/material.dart';
import '../../../backend_data/firestore_service.dart';
import '../../../backend_data/lesson_data.dart';

class AssignmentFromFirestore extends StatelessWidget {
  final DateTime lessonDate;
  final bool isTeen;
  final String? churchId;

  const AssignmentFromFirestore({
    required this.lessonDate,
    required this.isTeen,
    this.churchId,
  });

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService(churchId: churchId);

    return FutureBuilder<LessonDay?>(
      future: service.loadAssignment(lessonDate),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final assignmentDay = snapshot.data!;
        final notes = isTeen ? assignmentDay.teenNotes : assignmentDay.adultNotes;

        if (notes == null || notes.blocks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 48, bottom: 20),
              child: Text(
                "This Week’s Assignment",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade50, Colors.deepPurple.shade100],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.deepPurple.shade300, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.assignment_turned_in_rounded, size: 36, color: Colors.deepPurple),
                      const SizedBox(width: 12),
                      Text(
                        notes.topic.isNotEmpty ? notes.topic : "Assignment",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (notes.biblePassage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      notes.biblePassage,
                      style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.deepPurple),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ...notes.blocks.map((block) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      block.text ?? "",
                      style: const TextStyle(fontSize: 17, height: 1.6),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }
}