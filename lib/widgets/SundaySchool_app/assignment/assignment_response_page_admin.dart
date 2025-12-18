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
  Map<String, bool> _userGradedStatus = {}; // userId → feedback
  Map<String, List<int>> userScores = {}; // userId → list of scores
  Map<String, String> userFeedback = {};


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
                const SizedBox(height: 10),
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
                  margin: const EdgeInsets.only(bottom: 10),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      // Collapsed title: shows email + status icon
                      title: Row(
                        children: [
                          Icon(
                            hasSubmitted ? Icons.check_circle : Icons.pending,
                            color: hasSubmitted ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userEmail,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (hasSubmitted)
                            Text(
                              "${scores.reduce((a, b) => a + b)} / ${responses.length * 5}",
                              style: const TextStyle(fontSize: 16, color: Colors.deepPurple),
                            ),
                        ],
                      ),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      childrenPadding: const EdgeInsets.all(16),
                      initiallyExpanded: false, // Starts minimized
                      expandedAlignment: Alignment.topLeft,
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasSubmitted) ...[
                          ...responses.asMap().entries.map((entry) {
                            final int ansIndex = entry.key;
                            final String answer = entry.value;
                            final int currentScore = scores[ansIndex];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("• Answer ${ansIndex + 1}: $answer", style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 8),
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
                                                fontSize: 20,
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
                          const Divider(height: 10),
                          // Total score
                          Text(
                            "Total: ${scores.reduce((a, b) => a + b)} / ${responses.length * 5}",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          ),
                          const SizedBox(height: 5),
                          // Feedback
                          TextField(
                            decoration: const InputDecoration(
                              labelText: "Feedback (optional)",
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            controller: TextEditingController(text: feedback),
                            onChanged: (val) {
                              // Store locally until save
                              responseData?['feedback'] = val;
                            },
                          ),
                          const SizedBox(height: 10),
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

                                setState(() {
                                  _userGradedStatus[userId] = scores.every((score) => score != 0);
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Grading saved! ${_userGradedStatus[userId]! ? 'Fully Marked' : 'Unmarked'}"),
                                    backgroundColor: _userGradedStatus[userId]! ? Colors.green : Colors.orange,
                                  ),
                                );
                              },
                              child: const Text("Complete Grading", style: TextStyle(fontSize: 18, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Status icon + text (bottom right)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _userGradedStatus[userId]! ? Icons.verified : Icons.pending,
                                  color: _userGradedStatus[userId]! ? Colors.green : Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _userGradedStatus[userId]! ? "Graded" : "Ungraded",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _userGradedStatus[userId]! ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              "Not submitted yet",
                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
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
          // Initialize per-user grading status
        _userGradedStatus.putIfAbsent(userId, () => data['isGraded'] ?? false);
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

            // Get or initialize grading status for this user
            final isGraded = _userGradedStatus[userId]!;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Stack(
                  children: [
                    ExpansionTile(
                      title: Row(
                        children: [
                          Icon(
                            isGraded ? Icons.check_circle : Icons.pending,
                            size: 16.0,
                            color: isGraded ? Colors.green : const Color.fromARGB(255, 140, 140, 140),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              userEmail,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 5),
                          if (isGraded)
                            Text(
                              "${scores.reduce((a, b) => a + b)} / ${responses.length}",
                              style: const TextStyle(fontSize: 16, color: Colors.deepPurple),
                            ),
                        ],
                      ),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16 ,0),
                      initiallyExpanded: false, // Starts minimized
                      expandedAlignment: Alignment.topLeft,
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userEmail, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ...responses.asMap().entries.map((entry) {
                          final ansIndex = entry.key;
                          final answer = entry.value;
                          final currentScore = scores[ansIndex];
                    
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("• Answer ${ansIndex + 1}: $answer"),
                                const SizedBox(height: 10),
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
                        const Divider(height: 10),
                        Text(
                          "Total: ${scores.reduce((a, b) => a + b)} / ${responses.length * 1}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: "Feedback (optional)", 
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          controller: TextEditingController(text: feedback),
                          onChanged: (val) => userFeedback[userId] = val,
                        ),
                        const SizedBox(height: 10),
                        // SAVE BOX
                        // Buttons Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Complete Grading Button (disabled if graded)
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _userGradedStatus[userId]! ? Colors.grey : const Color.fromARGB(255, 83, 222, 162),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                ),
                                onPressed: _userGradedStatus[userId]!
                                    ? null // Disabled
                                    : () async {
                                        await doc.reference.set({
                                          'scores': scores,
                                          'totalScore': scores.reduce((a, b) => a + b),
                                          'feedback': userFeedback[userId]!.trim().isEmpty ? null : userFeedback[userId],
                                          'isGraded': true,
                                        }, SetOptions(merge: true));
                    
                                        setState(() {
                                          _userGradedStatus[userId] = true;
                                        });
                    
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Grading saved!"), backgroundColor: Colors.green),
                                        );
                                      },
                                child: const Text("Grade", style: TextStyle(fontSize: 18, color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Reset Grading Button (disabled if not graded)
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _userGradedStatus[userId]! ? const Color.fromARGB(255, 227, 127, 127) : Colors.grey,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                ),
                                onPressed: _userGradedStatus[userId]!
                                    ? () async {
                                        await doc.reference.update({
                                          'isGraded': false,
                                          'scores': null, // Optional: clear scores
                                          'totalScore': null,
                                          'feedback': null,
                                        });
                    
                                        setState(() {
                                          _userGradedStatus[userId] = false;
                                        });
                    
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Grading reset!"), backgroundColor: Color.fromARGB(255, 220, 97, 88)),
                                        );
                                      }
                                    : null, // Disabled
                                child: const Text("Reset", style: TextStyle(fontSize: 18, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 10),
                        const SizedBox(height: 30),
                      ],
                    ),
                    if (_userGradedStatus[userId]!)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.verified, color: Colors.white, size: 8),
                              SizedBox(width: 4),
                              Text(
                                "Graded",
                                style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
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

  /*
  How to Sum Up All Scores Later (Future-Proof)
You can query all the user's responses and sum the totalScore (or scores array if you prefer).
Example: Sum All Scores for a User (Future Code)
DartFuture<int> getUserTotalScore(String userId) async {
  int total = 0;

  // Query all assignment responses for this user
  final snapshot = await _service.responsesCollection
      .where('userId', isEqualTo: userId)
      .get();

  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final score = data['totalScore'] as int? ?? 0;
    total += score;
  }

  return total;
}
Or sum per assignment type/date if needed:
DartFuture<Map<String, int>> getUserScoresByDate(String userId) async {
  final Map<String, int> scoresByDate = {};

  final snapshot = await _service.responsesCollection
      .where('userId', isEqualTo: userId)
      .get();

  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final date = doc.reference.parent.parent!.id; // e.g., "2025-12-28"
    final score = data['totalScore'] as int? ?? 0;
    scoresByDate[date] = score;
  }

  return scoresByDate;
}*/
}