// lib/screens/assignment_response_page.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../UI/buttons.dart';
import '../../../UI/linear_progress_bar.dart';
import '../../../auth/login/auth_service.dart';
import '../../../backend_data/assignment_data.dart';
import '../../../backend_data/firestore_service.dart';

class AssignmentResponsePage extends StatefulWidget {
  final DateTime date;
  final bool isTeen;
  final String? churchId;

  const AssignmentResponsePage({
    super.key,
    required this.date,
    required this.isTeen,
    this.churchId,
  });

  @override
  State<AssignmentResponsePage> createState() => _AssignmentResponsePageState();
}

class _AssignmentResponsePageState extends State<AssignmentResponsePage> {
  final List<TextEditingController> _controllers = [];
  bool _isLoading = true;
  String _assignmentText = "Loading assignment...";

  late final FirestoreService _service;

  @override
  void initState() {
    super.initState();
    final currentChurchId = context.read<AuthService>().churchId;
    _service = FirestoreService(churchId: currentChurchId);
    _loadAssignmentAndResponses();
  }

  Future<void> _loadAssignmentAndResponses() async {
    print(">>> ENTERED _loadAssignmentAndResponses");

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Load assignment
    AssignmentDay? assignmentDay;
    try {
      assignmentDay = await _service
          .loadAssignment(widget.date)
          .timeout(const Duration(seconds: 6), onTimeout: () {
        print("loadAssignment TIMEOUT");
        return null;
      });
    } catch (e, st) {
      print("Error during loadAssignment: $e\n$st");
      assignmentDay = null;
    }

    print("Assignment loaded: $assignmentDay");

    // Pick teen or adult notes
    final notes = widget.isTeen ? assignmentDay?.teenNotes : assignmentDay?.adultNotes;
    print("isTeen: ${widget.isTeen}");

    // Prepare assignment text
    if (notes != null && notes.blocks.isNotEmpty) {
      _assignmentText = notes.blocks.map((b) => b.text ?? "").join("\n\n").trim();
      if (_assignmentText.isEmpty) _assignmentText = "No assignment text";
    } else {
      _assignmentText = "You need to be logged in to view assignment!";
    }

    // Load existing user response
    List<String> responses = [];
    try {
      final AssignmentResponse? response = await _service.loadUserResponse(
        date: widget.date,
        type: widget.isTeen ? "teen" : "adult",
        userId: user.uid,
      );

      if (response != null && response.responses.isNotEmpty) {
        responses = response.responses;
      }
    } catch (e, st) {
      print("Error loading user response: $e\n$st");
      responses = [];
    }

    // Dispose any old controllers
    for (final c in _controllers) {
      try {
        c.dispose();
      } catch (_) {}
    }
    _controllers.clear();

    // Create new controllers based on existing responses or at least one empty box
    if (responses.isEmpty) {
      _controllers.add(TextEditingController());
    } else {
      for (final resp in responses) {
        _controllers.add(TextEditingController(text: resp));
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    print(">>> FINISHED _loadAssignmentAndResponses");
  }


  Future<void> _saveResponses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final churchId = context.read<AuthService>().churchId;
    if (churchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select your church first!"),
        ),
      );
      return;
    }

    final responses = _controllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (responses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter at least one response."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _service.saveUserResponse(
        date: widget.date,
        type: widget.isTeen ? "teen" : "adult",
        userId: user.uid,
        userEmail: user.email ?? "",
        churchId: churchId,
        responses: responses,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Responses saved!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, st) {
      print("Error saving responses: $e\n$st");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to save responses."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _addResponseBox() {
    setState(() => _controllers.add(TextEditingController()));
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('MMMM d, yyyy').format(widget.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Assignment"),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: LinearProgressBar())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assignment text
                  Card(
                    color: Colors.deepPurple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "This Week's Assignment",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _assignmentText,
                            style: const TextStyle(fontSize: 17, height: 1.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Due: $dateFormatted",
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "My Responses:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  ..._controllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: "Write your response #${index + 1} here...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                controller.dispose();
                                _controllers.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),

                  Center(
                    child: IconButton(
                      onPressed: _addResponseBox,
                      icon: const Icon(Icons.add_circle_outline, size: 48),
                      color: Colors.grey[600],
                      tooltip: "Add another response",
                    ),
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: AssignmentWidgetButton(
                      context: context,
                      text: "Save All Responses",
                      icon: const Icon(Icons.save_rounded),
                      topColor: Colors.deepPurple,
                      onPressed: _saveResponses,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
