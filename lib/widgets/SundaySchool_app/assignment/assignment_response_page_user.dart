// lib/screens/assignment_response_page.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../UI/app_buttons.dart';
import '../../../UI/app_linear_progress_bar.dart';
import '../../../auth/login/auth_service.dart';
import '../../../backend_data/database/assignment_data.dart';
import '../../../backend_data/service/analytics/analytics_service.dart';
import '../../../backend_data/service/firestore_service.dart';
import '../../../backend_data/service/submitted_dates_provider.dart';
import '../../../backend_data/database/lesson_data.dart';

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
  bool _isSubmitted = false;
  bool _isEditing = false;
  bool _isGradedByAdmin = false;
  String _currentQuestion = "Loading assignment...";
  // Stored response data loaded from Firestore so the UI can access them
  List<String> _savedResponses = [];
  List<int> _scores = [];
  String? _feedback;
  AssignmentResponse? _loadedResponse;

  late final FirestoreService _service;

  @override
  void initState() {
    super.initState();
    final currentChurchId = context.read<AuthService>().churchId;
    _service = FirestoreService(churchId: currentChurchId);
    _loadAssignmentAndResponses();
  }

  String extractSingleQuestionFromSection(Map<String, dynamic>? sectionMap) {
    if (sectionMap == null) return "No question available.";

    final List<dynamic>? blocks = sectionMap['blocks'] as List<dynamic>?;
    if (blocks == null || blocks.isEmpty) return "No question available.";

    for (final block in blocks) {
      final map = block as Map<String, dynamic>;
      final String? text = map['text'] as String?;

      if (text != null) {
        final trimmed = text.trim();
        if (trimmed.isNotEmpty) {
          // Look for common question patterns
          if (trimmed.endsWith('?') ||
              trimmed.contains(RegExp(r'\(\d+\s*marks?\)', caseSensitive: false)) ||
              trimmed.contains('List') ||
              trimmed.contains('Explain') ||
              trimmed.contains('Discuss') ||
              trimmed.contains('Question')) {
            return trimmed;
          }
        }
      }

      // Check numbered list — first item is often the question
      if (map['type'] == 'numbered_list') {
        final List<dynamic>? items = map['items'] as List<dynamic>?;
        if (items != null && items.isNotEmpty) {
          final first = items.first as String;
          final trimmed = first.trim();
          if (trimmed.endsWith('?') || trimmed.contains(RegExp(r'\(\d+\s*marks?\)')))
            return trimmed;
        }
      }
    }

    // Fallback: first heading or text block
    for (final block in blocks) {
      final map = block as Map<String, dynamic>;
      if ((map['type'] == 'heading' || map['type'] == 'text') && map['text'] != null) {
        return (map['text'] as String).trim();
      }
    }

    return "No question available.";
  }

  Future<void> _loadAssignmentAndResponses() async {
    print(">>> ENTERED _loadAssignmentAndResponses");

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // ── Load the assignment (contains the question) ──
    AssignmentDay? assignmentDay;
    try {
      assignmentDay = await _service.loadAssignment(widget.date).timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          print("loadAssignment TIMEOUT");
          return null;
        },
      );
    } catch (e, st) {
      print("Error during loadAssignment: $e\n$st");
      assignmentDay = null;
    }

    print("Assignment loaded: $assignmentDay");

    // ── Extract the single question from teen or adult section ──
    String currentQuestion = "No question available for this day.";

    if (assignmentDay != null) {
      final SectionNotes? sectionNotes = widget.isTeen
          ? assignmentDay.teenNotes
          : assignmentDay.adultNotes;

      if (sectionNotes != null) {
        currentQuestion = extractSingleQuestionFromSection(sectionNotes.toMap());
      }
    }

    // ── Load existing user responses (multiple answers to the one question) ──
    try {
      final AssignmentResponse? response = await _service.loadUserResponse(
        date: widget.date,
        type: widget.isTeen ? "teen" : "adult",
        userId: user.uid,
      );

      if (response != null && response.responses.isNotEmpty) {
        // Save into state fields so `build` can access them
        final loadedResponses = response.responses.map((s) => s.trim()).toList();

        // Parse scores from the loaded response (admin stores `scores` as List<int>)
        List<int> parsedScores = [];
        if (response.scores != null && response.scores!.isNotEmpty) {
          parsedScores = List<int>.from(response.scores!);
        }

        // If no scores present, default to zeros matching responses length
        if (parsedScores.isEmpty) parsedScores = List.filled(loadedResponses.length, 0);

        // Ensure scores list matches responses length (pad or trim)
        if (parsedScores.length < loadedResponses.length) {
          parsedScores.addAll(List.filled(loadedResponses.length - parsedScores.length, 0));
        } else if (parsedScores.length > loadedResponses.length) {
          parsedScores = parsedScores.sublist(0, loadedResponses.length);
        }

        setState(() {
          _savedResponses = loadedResponses;
          _feedback = response.feedback;
          _scores = parsedScores;
          _loadedResponse = response;
          _isSubmitted = _savedResponses.isNotEmpty;
          _isEditing = false;
          _isGradedByAdmin = response.isGraded ?? false;
        });
      }
    } catch (e, st) {
      print("Error loading user response: $e\n$st");
    }

    // ── Dispose old controllers ──
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();

    // ── Create controllers: one per saved answer, or at least one empty ──
    if (_savedResponses.isEmpty) {
      _controllers.add(TextEditingController());
    } else {
      for (final answer in _savedResponses) {
        _controllers.add(TextEditingController(text: answer.trim()));
      }
    }

    // ── Update state with the question ──
    if (mounted) {
      setState(() {
        _currentQuestion = currentQuestion;
        _isLoading = false;
      });
    }

    print(">>> FINISHED _loadAssignmentAndResponses");
    print(">>> Question: $_currentQuestion");
    print(">>> Number of answer boxes: ${_controllers.length}");
  }

  Future<void> _saveResponses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final churchId = context.read<AuthService>().churchId;
    if (churchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select your church first!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Collect all non-empty answers
    final List<String> responses = _controllers
        .map((controller) => controller.text.trim())
        .where((answer) => answer.isNotEmpty)
        .toList();

    if (responses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter at least one answer to the question."),
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
        userEmail: user.email ?? "anonymous@user.com",
        churchId: churchId,
        responses: responses,
      );

      // SUCCESS → mark as submitted
      setState(() {
        _isSubmitted = true;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your answers have been submitted successfully!"),
          backgroundColor: Color.fromARGB(255, 84, 155, 86),
        ),
      );

      // Refresh the submitted-dates provider so the calendar shows the update immediately
      try {
        final submittedProvider = Provider.of<SubmittedDatesProvider>(context, listen: false);
        await submittedProvider.refresh(_service, user.uid);
      } catch (e) {
        // Swallow any errors here - not critical for user save flow
        debugPrint('Error refreshing submitted dates: $e');
      }
      
    } catch (e, st) {
      print("Error saving responses: $e\n$st");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to save your answers. Please try again."),
          backgroundColor: Color.fromARGB(255, 176, 91, 84),
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
                            _currentQuestion,
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

                  const SizedBox(height: 20),
                  /*const Text(
                    "My Responses:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),*/
                  // After the assignment question card

                  if (_isGradedByAdmin)
                    Card(
                      color: Colors.green.shade50,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.verified, color: Colors.green.shade700),
                                const SizedBox(width: 10),
                                Text(
                                  "Graded by Teacher",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Total Score — now uses saved totalScore if available, falls back to calculated
                            Text(
                              "Your Score: ${_loadedResponse?.totalScore ?? _scores.fold(0, (a, b) => a! + b)} / ${_savedResponses.length}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Teacher Feedback
                            if (_feedback != null && _feedback!.trim().isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Teacher's Feedback:",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.shade300, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.shade100,
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _feedback!,
                                      style: const TextStyle(fontSize: 16, height: 1.6),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                "No feedback provided.",
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                      ),
                    ),
                  Text(
                    _isGradedByAdmin 
                        ? "This assignment has been graded" 
                        : (_isSubmitted && !_isEditing ? "Your submitted responses" : "My Responses:"),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _isGradedByAdmin ? Colors.grey : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ..._controllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;

                    final bool isFieldLocked = _isSubmitted && !_isEditing || _isGradedByAdmin;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              maxLines: null,
                              readOnly: isFieldLocked,
                              decoration: InputDecoration(
                                hintText: isFieldLocked
                                  ? (_isGradedByAdmin ? "Graded — cannot edit" : "Submitted — tap Edit to change")
                                  : "Write your response #${index + 1} here...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isFieldLocked 
                                  ? Colors.grey.shade200 
                                  : Colors.grey[50],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isFieldLocked)
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

                  // Hide "Add response" when locked
                  if (!_isSubmitted || _isEditing)
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
                      text: _isGradedByAdmin 
                        ? "Graded by Teacher" 
                        : (_isSubmitted && !_isEditing ? "Edit Responses" : "Submit"),
                      icon: Icon(_isGradedByAdmin 
                        ? Icons.verified 
                        : (_isSubmitted && !_isEditing ? Icons.edit : Icons.save_rounded),
                      ),
                      topColor: _isGradedByAdmin 
                        ? const Color.fromARGB(255, 76, 112, 175) 
                        : (_isSubmitted && !_isEditing ? const Color.fromARGB(255, 62, 134, 71) : Colors.deepPurple),
                      onPressed: _isGradedByAdmin
                        ? null // Fully disabled
                        : () async {
                            if (_isSubmitted && !_isEditing) {
                              await AnalyticsService.logButtonClick('unlock_for_editing');
                              // Unlock for editing
                              setState(() {
                                _isEditing = true;
                              });
                            } else {
                              // Submit (new or update)
                              await AnalyticsService.logButtonClick('save_responses');
                              // Submit (new or update)
                              _saveResponses();
                            }
                          },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
