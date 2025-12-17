// lib/widgets/assignment_response_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../auth/login/auth_service.dart';
import '../../../backend_data/firestore_service.dart';
import '../../../backend_data/lesson_data.dart';

class AssignmentResponseDetailPage extends StatefulWidget {
  final DateTime date;
  final bool isTeen;

  const AssignmentResponseDetailPage({
    super.key,
    required this.date,
    required this.isTeen,
  });

  @override
  State<AssignmentResponseDetailPage> createState() => _AssignmentResponseDetailPageState();
}

class _AssignmentResponseDetailPageState extends State<AssignmentResponseDetailPage> {
  late final FirestoreService _service;
  String _question = "Loading question...";
  bool _loading = true;
  Map<String, List<int>> userScores = {}; // userId → list of scores
  Map<String, String> userFeedback = {}; // userId → feedback

  @override
  void initState() {
    super.initState();
    final churchId = context.read<AuthService>().churchId;
    _service = FirestoreService(churchId: churchId);
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    final assignmentDay = await _service.loadAssignment(widget.date);
    String extracted = "No question available for this day.";

    if (assignmentDay != null) {
      final SectionNotes? sectionNotes = widget.isTeen
          ? assignmentDay.teenNotes
          : assignmentDay.adultNotes;

      if (sectionNotes != null) {
        extracted = _extractSingleQuestion(sectionNotes.toMap());
      }
    }

    if (mounted) {
      setState(() {
        _question = extracted;
        _loading = false;
      });
    }
  }

  // Reused exactly from your AssignmentResponsePage — no duplication!
  String _extractSingleQuestion(Map<String, dynamic>? sectionMap) {
    if (sectionMap == null) return "No question available.";
    final List<dynamic>? blocks = sectionMap['blocks'] as List<dynamic>?;
    if (blocks == null || blocks.isEmpty) return "No question available.";

    for (final block in blocks) {
      final map = block as Map<String, dynamic>;
      final String? text = map['text'] as String?;

      if (text != null) {
        final trimmed = text.trim();
        if (trimmed.isNotEmpty) {
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

    // Fallback: first text or heading block
    for (final block in blocks) {
      final map = block as Map<String, dynamic>;
      if ((map['type'] == 'heading' || map['type'] == 'text') && map['text'] != null) {
        return (map['text'] as String).trim();
      }
    }

    return "No question available.";
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final churchId = auth.churchId;
    final isGlobalAdmin = auth.isGlobalAdmin;
    final isGroupAdmin = auth.isGroupAdmin;

    final String type = widget.isTeen ? "teen" : "adult";
    final String dateStr = "${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}";

    // If no church, show message
    if (!isGlobalAdmin && churchId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Responses")),
        body: const Center(child: Text("Global admins only — no church selected.")),
      );
    }

    final membersCollection = isGlobalAdmin
        ? null // Global admin sees all — we'll load responses directly
        : FirebaseFirestore.instance.collection('churches').doc(churchId).collection('members');


    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.isTeen ? 'Teen' : 'Adult'} Responses — $dateStr"),
        backgroundColor: Colors.deepPurple,
      ),
      body: _loading
          ? const Center(child: LinearProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
                  Card(
                    color: Colors.deepPurple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Question",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _question,
                            style: const TextStyle(fontSize: 17, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // DEBUG
                  /*ElevatedButton.icon(
                    onPressed: () {
                      final auth = context.read<AuthService>();
                      final churchId = auth.churchId;
                      final isGlobal = churchId == null;

                      print("🔍 === ADMIN GRADING DEBUG ===");
                      print("Date: ${widget.date} → $dateStr");
                      print("Type: $type (${widget.isTeen ? 'Teen' : 'Adult'})");
                      print("Church ID: ${churchId ?? 'Global (no church)'}");
                      print("Query Path: ${_service.responsesCollection.path}/$type/$dateStr");
                      print("Is Global Admin? ${auth.isGlobalAdmin}");
                      print("=====================================");
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text("Debug Query Path"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),*/
                  const Text(
                    "Submissions",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 32),

                  Expanded(
                    child: isGlobalAdmin
                        //? _buildGroupYesAdminView(membersCollection!, type, dateStr)
                        ? _buildGlobalAdminView(type, dateStr)
                        : _buildChurchAdminView(membersCollection!, type, dateStr),
                  ),
                ],
              ),
            ),
    );
  }

  /*Widget _buildChurchAdminView(CollectionReference membersCollection, String type, String dateStr) {
    return FutureBuilder<QuerySnapshot>(
      future: membersCollection.get(),
      builder: (context, memberSnapshot) {
        // ← ADD ERROR HANDLING
        if (memberSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text("Error loading members: ${memberSnapshot.error}"),
                ElevatedButton(
                  onPressed: () => setState(() {}), // retry
                  child: const Text("Retry"),
                ),
              ],
            ),
          );
        }
        if (!memberSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        final memberDocs = memberSnapshot.data!.docs;
        if (memberDocs.isEmpty) return const Center(child: Text("No members in church."));

        return StreamBuilder<QuerySnapshot>(
        stream: _service.responsesCollection
            .doc(type)
            .collection(dateStr)
            .snapshots(),
          builder: (context, responseSnapshot) {
            final responseMap = <String, Map<String, dynamic>>{};
            if (responseSnapshot.hasData) {
              for (var doc in responseSnapshot.data!.docs) {
                responseMap[doc.id] = doc.data() as Map<String, dynamic>;
              }
            }

            return ListView.builder(
              itemCount: memberDocs.length,
              itemBuilder: (context, index) {
                final memberDoc = memberDocs[index];
                final userId = memberDoc.id;
                final memberData = memberDoc.data() as Map<String, dynamic>;
                final userEmail = memberData['email'] ?? "No email";

                final responseData = responseMap[userId];
                final responses = responseData != null
                    ? List<String>.from(responseData['responses'] ?? [])
                    : <String>[];
                final grade = responseData?['grade'] as String?;
                final feedback = responseData?['feedback'] as String?;

                final hasSubmitted = responses.isNotEmpty;

                return Card(
                  color: hasSubmitted ? Colors.white : Colors.grey.shade100,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasSubmitted ? Icons.check_circle : Icons.pending,
                              color: hasSubmitted ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              userEmail,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (hasSubmitted) ...[
                          ...responses.asMap().entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text("• Answer ${e.key + 1}: ${e.value}"),
                              )),
                          const Divider(height: 32),
                          TextField(
                            decoration: InputDecoration(labelText: "Grade", hintText: grade ?? "e.g. 8/10"),
                            controller: TextEditingController(text: grade),
                            onSubmitted: (val) {
                              final trimmed = val.trim();
                              _service.responsesCollection  // or responsesCollection if public
                                  .doc(type)
                                  .collection(dateStr)
                                  .doc(userId)
                                  .set({'grade': trimmed.isEmpty ? null : trimmed}, SetOptions(merge: true));
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: const InputDecoration(labelText: "Feedback"),
                            maxLines: 3,
                            controller: TextEditingController(text: feedback),
                            onSubmitted: (val) {
                              final trimmed = val.trim();
                              _service.responsesCollection  // or responsesCollection if public
                                  .doc(type)
                                  .collection(dateStr)
                                  .doc(userId)
                                  .set({'grade': trimmed.isEmpty ? null : trimmed}, SetOptions(merge: true));
                            },
                          ),
                        ] else
                          const Text("Not submitted yet", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGlobalAdminView(String type, String dateStr) {
    return StreamBuilder<QuerySnapshot>(
    stream: _service.responsesCollection
        .doc(type)
        .collection(dateStr)
        .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No submissions yet."));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final userEmail = data['userEmail'] ?? "Unknown";
            final responses = List<String>.from(data['responses'] ?? []);
            final grade = data['grade'] as String?;
            final feedback = data['feedback'] as String?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userEmail, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...responses.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text("• Answer ${e.key + 1}: ${e.value}"),
                        )),
                    const Divider(height: 32),
                    TextField(
                      decoration: InputDecoration(labelText: "Grade", hintText: grade ?? "e.g. 8/10"),
                      controller: TextEditingController(text: grade),
                      onSubmitted: (val) => doc.reference.update({'grade': val.trim().isEmpty ? null : val}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(labelText: "Feedback"),
                      maxLines: 3,
                      controller: TextEditingController(text: feedback),
                      onSubmitted: (val) => doc.reference.update({'feedback': val.trim().isEmpty ? null : val}),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }*/

  Widget _buildChurchAdminView(CollectionReference membersCollection, String type, String dateStr) {
    return FutureBuilder<QuerySnapshot>(
      future: membersCollection.get(),
      builder: (context, memberSnapshot) {
        if (memberSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text("Error loading members: ${memberSnapshot.error}"),
                ElevatedButton(onPressed: () => setState(() {}), child: const Text("Retry")),
              ],
            ),
          );
        }
        if (!memberSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (memberSnapshot.data!.docs.isEmpty) return const Center(child: Text("No members in church."));

        return StreamBuilder<QuerySnapshot>(
          stream: _service.responsesCollection.doc(type).collection(dateStr).snapshots(),
          builder: (context, responseSnapshot) {
            final responseMap = <String, Map<String, dynamic>>{};
            if (responseSnapshot.hasData) {
              for (var doc in responseSnapshot.data!.docs) {
                responseMap[doc.id] = doc.data() as Map<String, dynamic>;
              }
            }

            return ListView.builder(
              itemCount: memberSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final memberDoc = memberSnapshot.data!.docs[index];
                final userId = memberDoc.id;
                final memberData = memberDoc.data() as Map<String, dynamic>;
                final userEmail = memberData['email'] ?? "No email";

                final responseData = responseMap[userId];
                final responses = responseData != null
                    ? List<String>.from(responseData['responses'] ?? [])
                    : <String>[];

                // Load existing scores (array of int, same length as responses)
                List<int> scores = [];
                if (responseData != null && responseData['scores'] is List) {
                  scores = List<int>.from(responseData['scores']);
                  // Pad or trim to match responses length
                  if (scores.length < responses.length) {
                    scores.addAll(List.filled(responses.length - scores.length, 0));
                  } else if (scores.length > responses.length) {
                    scores = scores.sublist(0, responses.length);
                  }
                } else {
                  scores = List.filled(responses.length, 0);
                }

                final feedback = responseData?['feedback'] as String?;

                final hasSubmitted = responses.isNotEmpty;

                return Card(
                  color: hasSubmitted ? Colors.white : Colors.grey.shade100,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasSubmitted ? Icons.check_circle : Icons.pending,
                              color: hasSubmitted ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              userEmail,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (hasSubmitted) ...[
                          ...responses.asMap().entries.map((entry) {
                            final int ansIndex = entry.key;
                            final String answer = entry.value;
                            final int currentScore = scores[ansIndex];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("• Answer ${ansIndex + 1}: $answer", style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 12),
                                  // 5-star rating scale
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(2, (starIndex) {
                                      final score = starIndex + 1;
                                      final isSelected = currentScore == score;

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            scores[ansIndex] = score;
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 8),
                                          width: 40,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.rectangle,
                                            color: isSelected
                                                ? _getColorForScore(score)
                                                : _getColorForScore(score).withOpacity(0.3),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "$score",
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? Colors.white : _getColorForScore(score),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(height: 40),
                          // Total score
                          Text(
                            "Total: ${scores.reduce((a, b) => a + b)} / ${responses.length * 5}",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          ),
                          const SizedBox(height: 16),
                          // Feedback
                          TextField(
                            decoration: const InputDecoration(
                              labelText: "Feedback (optional)",
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            controller: TextEditingController(text: feedback),
                            onChanged: (val) {
                              // Store locally until save
                              responseData?['feedback'] = val;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Save button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                await _service.responsesCollection
                                    .doc(type)
                                    .collection(dateStr)
                                    .doc(userId)
                                    .set({
                                  'scores': scores,
                                  'totalScore': scores.reduce((a, b) => a + b),
                                  'feedback': feedback?.trim().isEmpty ?? true ? null : feedback,
                                }, SetOptions(merge: true));

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Grading saved!"), backgroundColor: Colors.green),
                                );
                              },
                              child: const Text("Save Grading", style: TextStyle(fontSize: 18, color: Colors.white)),
                            ),
                          ),
                        ] else
                          const Text("Not submitted yet", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGlobalAdminView(String type, String dateStr) {
    return StreamBuilder<QuerySnapshot>(
      stream: _service.responsesCollection.doc(type).collection(dateStr).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No submissions yet."));

        // Initialize maps if not already
        for (var doc in snapshot.data!.docs) {
          final userId = doc.id;
          final data = doc.data() as Map<String, dynamic>;

          if (!userScores.containsKey(userId)) {
            final responses = List<String>.from(data['responses'] ?? []);
            final existingScores = data['scores'] is List ? List<int>.from(data['scores']) : List.filled(responses.length, 0);
            if (existingScores.length < responses.length) {
              existingScores.addAll(List.filled(responses.length - existingScores.length, 0));
            }
            userScores[userId] = existingScores;
          }

          if (!userFeedback.containsKey(userId)) {
            userFeedback[userId] = data['feedback'] as String? ?? "";
          }
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final userId = doc.id;
            final data = doc.data() as Map<String, dynamic>;

            final userEmail = data['userEmail'] ?? "Unknown";
            final responses = List<String>.from(data['responses'] ?? []);
            final scores = userScores[userId]!;
            final feedback = userFeedback[userId]!;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userEmail, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...responses.asMap().entries.map((entry) {
                      final ansIndex = entry.key;
                      final answer = entry.value;
                      final currentScore = scores[ansIndex];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("• Answer ${ansIndex + 1}: $answer"),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(2, (starIndex) {
                                final score = starIndex;
                                final isSelected = currentScore == score;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      scores[ansIndex] = score;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    width: 40,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.rectangle,
                                      color: isSelected ? _getColorForScore(score) : _getColorForScore(score).withOpacity(0.3),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "$score",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : _getColorForScore(score).withOpacity(0.8),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 40),
                    Text(
                      "Total: ${scores.reduce((a, b) => a + b)} / ${responses.length * 1}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(labelText: "Feedback (optional)", border: OutlineInputBorder()),
                      maxLines: 3,
                      controller: TextEditingController(text: feedback),
                      onChanged: (val) => userFeedback[userId] = val,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () async {
                          await doc.reference.set({
                            'scores': scores,
                            'totalScore': scores.reduce((a, b) => a + b),
                            'feedback': userFeedback[userId]!.trim().isEmpty ? null : userFeedback[userId],
                          }, SetOptions(merge: true));

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Grading saved!"), backgroundColor: Colors.green),
                          );
                        },
                        child: const Text("Save Grading", style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getColorForScore(int score) {
    switch (score) {
      case 0: return Colors.orange;
      case 1: return Colors.lightGreen;

      /*case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.yellow.shade700;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green.shade800;*/
      default: return Colors.grey;
    }
  }
}