// lib/screens/assignments_home.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'assignment.dart';
import 'assignment_detail.dart';

class AssignmentsHomePage extends StatelessWidget {
  const AssignmentsHomePage({super.key});

  // Fake data for now (replace later with Firestore)
  final List<Assignment> assignments = const [
    Assignment(
      date: "2025-12-07",
      title: "The Power of Prayer",
      passage: "James 5:16-18",
      topic: "Effective & Fervent Prayer",
    ),
    Assignment(
      date: "2025-12-14",
      title: "Walking in the Spirit",
      passage: "Galatians 5:16-25",
      topic: "Fruit vs. Works",
    ),
    Assignment(
      date: "2025-12-21",
      title: "The Birth of the King",
      passage: "Luke 2:1-20",
      topic: "Christmas Special",
    ),
    Assignment(
      date: "2025-12-28",
      title: "New Year, New Heart",
      passage: "Ezekiel 36:26-27",
      topic: "Renewal & Restoration",
    ),
    Assignment(
      date: "2025-11-30",
      title: "Gratitude That Transforms",
      passage: "Colossians 3:15-17",
      topic: "A Thankful Heart",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Sort: future first, then past
    final sorted = assignments
      ..sort((a, b) {
        final da = DateTime.parse(a.date);
        final db = DateTime.parse(b.date);
        final now = DateTime.now();
        final aFuture = da.isAfter(now);
        final bFuture = db.isAfter(now);
        if (aFuture && !bFuture) return -1;
        if (!aFuture && bFuture) return 1;
        return da.compareTo(db);
      });

    final upcoming = sorted.where((a) => DateTime.parse(a.date).isAfter(DateTime.now())).toList();
    final past = sorted.where((a) => !DateTime.parse(a.date).isAfter(DateTime.now())).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Assignments",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (upcoming.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 12),
              child: Text("Upcoming", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            ...upcoming.map((assignment) => AssignmentCard(assignment: assignment, isUpcoming: true)),
            const SizedBox(height: 32),
          ],

          if (past.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 12),
              child: Text("Completed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54)),
            ),
            ...past.map((assignment) => AssignmentCard(assignment: assignment, isUpcoming: false)),
          ],

          if (upcoming.isEmpty && past.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  "No assignments yet.\nCheck back soon!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final bool isUpcoming;

  const AssignmentCard({super.key, required this.assignment, required this.isUpcoming});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(assignment.date);
    final dayName = DateFormat('EEEE').format(date);
    final monthDay = DateFormat('MMM d').format(date);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssignmentDetailPage(assignment: assignment),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isUpcoming ? const Color(0xFFF8F5FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUpcoming ? Colors.deepPurple.shade300 : Colors.grey.shade200,
            width: isUpcoming ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isUpcoming ? Colors.deepPurple : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    monthDay.split(' ')[0],
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    monthDay.split(' ')[1],
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isUpcoming ? Colors.deepPurple.shade900 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    assignment.topic,
                    style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.7)),
                  ),
                  if (assignment.passage.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      assignment.passage,
                      style: const TextStyle(fontSize: 14, color: Colors.deepPurple, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isUpcoming ? Icons.arrow_forward_ios_rounded : Icons.check_circle_rounded,
              color: isUpcoming ? Colors.deepPurple : Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}