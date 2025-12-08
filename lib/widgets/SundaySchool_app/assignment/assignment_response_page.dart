// lib/screens/assignment_response_page.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../UI/buttons.dart';
import '../../../backend_data/assignment_data.dart';
import '../../../backend_data/firestore_service.dart';
import '../../current_church.dart';

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
  List<String> _existingResponses = [];
  String _assignmentText = "Loading assignment...";

  late final FirestoreService _service;

  @override
  void initState() {
    super.initState();
    final currentChurchId = context.read<CurrentChurch>().churchId;
    _service = FirestoreService(churchId: currentChurchId);
    _loadAssignmentAndResponses();
  }

  Future<void> _loadAssignmentAndResponses() async {
    print(">>> ENTERED _loadAssignmentAndResponses");

    /*final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }*/

    // Load assignment with safe timeout + error handling
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
    final notes = widget.isTeen ? assignmentDay?.teenNotes : assignmentDay?.adultNotes;
    print("isTeen: ${widget.isTeen}");

    // Prepare assignment text
    if (notes != null && notes.blocks.isNotEmpty) {
      _assignmentText = notes.blocks.map((b) => b.text ?? "").join("\n\n").trim();
      if (_assignmentText.isEmpty) _assignmentText = "No assignment text";
    } else {
      _assignmentText = "No assignment text";
    }

    // Load existing responses with safe timeout + error handling
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);

    /////// ADD USER HERE /////////
    /*final path =
        'assignment_responses/${widget.isTeen ? "teen" : "adult"}/$dateStr/users/${user.uid}';*/
    final path =
        'assignment_responses/${widget.isTeen ? "teen" : "adult"}/$dateStr';

    try {
      final doc = await FirebaseFirestore.instance
          .doc(path)
          .get()
          .timeout(const Duration(seconds: 6), onTimeout: () {
        print("Firestore doc.get TIMEOUT for path: $path");
        // Return a dummy DocumentSnapshot-like object by throwing to be caught below
        throw TimeoutException("Firestore doc.get timed out");
      });

      if (doc.exists && doc.data() != null && doc['responses'] is List) {
        _existingResponses = List<String>.from(doc['responses']);
      } else {
        _existingResponses = [];
      }
    } catch (e, st) {
      print("Error loading responses ($path): $e\n$st");
      _existingResponses = [];
    }

    // Dispose any existing controllers to avoid duplicates/leaks
    for (final c in _controllers) {
      try {
        c.dispose();
      } catch (_) {}
    }
    _controllers.clear();

    // Create controllers
    if (_existingResponses.isEmpty) {
      _controllers.add(TextEditingController());
    } else {
      for (final resp in _existingResponses) {
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

    final responses = _controllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
    final path = 'assignment_responses/${widget.isTeen ? "teen" : "adult"}/$dateStr/users/${user.uid}';

    await FirebaseFirestore.instance.doc(path).set({
      'responses': responses,
      'userId': user.uid,
      'userEmail': user.email,
      'date': dateStr,
      'submittedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Responses saved!"), backgroundColor: Colors.green),
    );
  }

  void _addResponseBox() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('MMMM d, yyyy').format(widget.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Assignment"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assignment Text
                  Card(
                    color: Colors.deepPurple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("This Week's Assignment",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple)),
                          const SizedBox(height: 12),
                          Text(_assignmentText,
                              style: const TextStyle(fontSize: 17, height: 1.6)),
                          const SizedBox(height: 12),
                          Text("Due: $dateFormatted",
                              style: const TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text("My Responses:",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Dynamic Response Boxes
                  ..._controllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: controller,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: "Write your response #${index + 1} here...",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    );
                  }),

                  // Add Response Button
                  Center(
                    child: IconButton(
                      onPressed: _addResponseBox,
                      icon: const Icon(Icons.add_circle_outline, size: 48),
                      color: Colors.grey[600],
                      tooltip: "Add another response",
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: AssignmentWidgetButton(
                      context: context,
                      text: "Save All Responses",
                      icon: const Icon(Icons.save_rounded),
                      topColor: Colors.deepPurple,
                      borderColor: const Color.fromARGB(0, 0, 0, 0),   // optional
                      onPressed: _saveResponses,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }
}