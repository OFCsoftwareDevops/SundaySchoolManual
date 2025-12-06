// lib/widgets/next_assignments_preview.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'assignments_home.dart';

class NextAssignmentsPreview extends StatelessWidget {
  final DateTime currentLessonDate;

  const NextAssignmentsPreview({
    super.key,
    required this.currentLessonDate,
  });

  @override
  Widget build(BuildContext context) {
    final String dateStr = DateFormat('yyyy-MM-dd').format(currentLessonDate);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('assignments')
          .doc(dateStr)
          .snapshots(),
      builder: (context, snapshot) {
        // No assignment on this date → show nothing
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

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

            _AssignmentHighlightCard(
              title: data['title'] ?? 'Assignment',
              topic: data['topic'] ?? '',
              passage: data['passage'] ?? '',
              date: currentLessonDate,
            ),

            const SizedBox(height: 20),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AssignmentsHomePage()),
                ),
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text("View Full Schedule"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  side: const BorderSide(color: Colors.deepPurple, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }
}

class _AssignmentHighlightCard extends StatelessWidget {
  final String title;
  final String topic;
  final String passage;
  final DateTime date;

  const _AssignmentHighlightCard({
    required this.title,
    required this.topic,
    required this.passage,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('EEEE').format(date);
    final monthDay = DateFormat('MMM d').format(date);

    return Container(
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
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(monthDay.split(' ')[0], style: const TextStyle(color: Colors.white, fontSize: 12)),
                Text(monthDay.split(' ')[1], style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                Text(dayName.substring(0, 3).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Assignment", style: TextStyle(fontSize: 14, color: Colors.deepPurple, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(topic, style: const TextStyle(fontSize: 17)),
                if (passage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(passage, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.deepPurple)),
                  ),
              ],
            ),
          ),
          const Icon(Icons.auto_stories_rounded, size: 40, color: Colors.deepPurple),
        ],
      ),
    );
  }
}