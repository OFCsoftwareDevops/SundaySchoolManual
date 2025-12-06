// lib/screens/assignment_detail.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'assignment.dart';

class AssignmentDetailPage extends StatelessWidget {
  final Assignment assignment;

  const AssignmentDetailPage({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(assignment.date);
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(date);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            backgroundColor: Colors.deepPurple,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                assignment.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.menu_book_rounded, size: 80, color: Colors.white24),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    assignment.topic,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300, height: 1.2),
                  ),
                  if (assignment.passage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        assignment.passage,
                        style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.deepPurple),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),

                  // Placeholder for real content
                  const Text(
                    "Lesson content will appear here.\n\n"
                    "This is where you'll read the full study, memory verses, discussion questions, prayer points, and more.\n\n"
                    "Coming soon — beautifully formatted with clickable Bible references!",
                    style: TextStyle(fontSize: 17, height: 1.7, color: Colors.black87),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Share coming soon
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Share feature coming soon!")),
          );
        },
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.share_rounded),
        label: const Text("Share Assignment"),
      ),
    );
  }
}