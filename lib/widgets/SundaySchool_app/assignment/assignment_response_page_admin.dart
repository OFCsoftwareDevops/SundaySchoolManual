// lib/widgets/assignment_response_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../auth/login/auth_service.dart';
import '../../../backend_data/service/firestore_service.dart';
import '../../../backend_data/database/lesson_data.dart';

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
    if ((!isGlobalAdmin || !isGroupAdmin) && churchId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Responses")),
        body: const Center(child: Text("Global admins only — no church selected.")),
      );
    }

    final membersCollection = isGlobalAdmin || isGroupAdmin
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
                    child: _buildAdminView(type, dateStr),
                  ),

                  /*Expanded(
                    child: isGlobalAdmin
                        //? _buildGroupYesAdminView(membersCollection!, type, dateStr)
                        ? _buildGlobalAdminView(type, dateStr)
                        : _buildChurchAdminView(membersCollection!, type, dateStr),
                  ),*/
                ],
              ),
            ),
    );
  }

  Widget _buildAdminView(String type, String dateStr) {
    return FutureBuilder<List<AssignmentResponse>>(
      future: _service.loadAllResponsesForDate(
        date: widget.date,
        type: type,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final responses = snapshot.data!;
        if (responses.isEmpty) {
          return const Center(child: Text("No submissions yet."));
        }

        return ListView.builder(
          itemCount: responses.length,
          itemBuilder: (context, index) {
            final response = responses[index];

          // ✅ Use persistent state for scores
          if (!userScores.containsKey(response.userId)) {
            userScores[response.userId] =
                response.scores ?? List.filled(response.responses.length, 0);
          }
          final scores = userScores[response.userId]!;

          final isGraded = response.isGraded ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Stack(
                children: [
                  ExpansionTile(
                    title: Row(
                      children: [
                        Icon(
                          isGraded ? Icons.check_circle : Icons.pending,
                          size: 16,
                          color: isGraded ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            response.userEmail ?? response.userId,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          "${scores.fold<int>(0, (a, b) => a + b)} / ${response.responses.length}",
                          style: const TextStyle(color: Colors.deepPurple),
                        ),
                      ],
                    ),
                    childrenPadding: const EdgeInsets.all(16),
                    children: [
                      ...response.responses.asMap().entries.map((entry) {
                        final i = entry.key;
                        final answer = entry.value;
                  
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("• Answer ${i + 1}: $answer"),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(2, (score) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      scores[i] = score;
                                    });
                                  },
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(horizontal: 6),
                                    width: 40,
                                    height: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: scores[i] == score
                                          ? _getColorForScore(score)
                                          : _getColorForScore(score)
                                              .withOpacity(0.3),
                                    ),
                                    child: Text(
                                      "$score",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }),
                      const Divider(),
                      ElevatedButton(
                        onPressed: isGraded
                            ? null
                            : () async {
                                await _service.saveGrading(
                                  userId: response.userId,
                                  date: widget.date,
                                  type: type,
                                  scores: scores,
                                );
                  
                                setState(() {});
                              },
                        child: const Text("Grade"),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: isGraded
                            ? () async {
                                await _service.resetGrading(
                                  userId: response.userId,
                                  date: widget.date,
                                  type: type,
                                );
                                setState(() {});
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text("Reset"),
                      ),
                    ],
                  ),
                  // ✅ Graded stamp
                  if (_userGradedStatus[response.userId] ?? false)
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
                            Icon(Icons.verified, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              "Graded",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
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

/*/ lib/widgets/assignment_response_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../auth/login/auth_service.dart';
import '../../../backend_data/service/firestore_service.dart';
import '../../../backend_data/database/lesson_data.dart';

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
  Map<String, bool> _userGradedStatus = {}; // userId → graded
  Map<String, List<int>> _userScores = {}; // userId → list of scores
  Map<String, String> _userFeedback = {};

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

    for (final block in blocks) {
      final map = block as Map<String, dynamic>;
      if ((map['type'] == 'heading' || map['type'] == 'text') && map['text'] != null) {
        return (map['text'] as String).trim();
      }
    }

    return "No question available.";
  }

  Color _getColorForScore(int score) {
    switch (score) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.lightGreen;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final churchId = auth.churchId;
    final isGlobalAdmin = auth.isGlobalAdmin;
    final isGroupAdmin = auth.isGroupAdmin;

    final String type = widget.isTeen ? "teen" : "adult";
    final String dateStr = "${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}";

    if ((!isGlobalAdmin && !isGroupAdmin) && churchId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Responses")),
        body: const Center(child: Text("Global admins only — no church selected.")),
      );
    }

    final membersCollection = FirebaseFirestore.instance
        .collection('churches')
        .doc(churchId)
        .collection('members');

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
                  const Text(
                    "Submissions",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 32),
                  
                  // Inside the Expanded widget in build()
                  
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _service.responsesCollection
                          .doc(type)
                          .collectionGroup(dateStr) // This is the magic!
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text("Error loading submissions: ${snapshot.error}"),
                          );
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text("No submissions yet for this date."),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        // Initialize state maps from incoming docs
                        for (var doc in docs) {
                          final userId = doc.reference.parent.parent!.id; // extracts userId
                          final data = doc.data() as Map<String, dynamic>;

                          final responses = List<String>.from(data['responses'] ?? []);

                          // Initialize scores
                          _userScores.putIfAbsent(userId, () {
                            final rawScores = data['scores'] as List<dynamic>?;
                            if (rawScores == null || rawScores.isEmpty) {
                              return List.filled(responses.length, 0);
                            }
                            return rawScores.map<int>((e) => e is int ? e : 0).toList();
                          });

                          // Ensure score length matches responses
                          final currentScores = _userScores[userId]!;
                          if (currentScores.length < responses.length) {
                            _userScores[userId] = currentScores
                              ..addAll(List.filled(responses.length - currentScores.length, 0));
                          } else if (currentScores.length > responses.length) {
                            _userScores[userId] = currentScores.sublist(0, responses.length);
                          }

                          _userFeedback.putIfAbsent(userId, () => data['feedback'] as String? ?? "");
                          _userGradedStatus.putIfAbsent(userId, () => data['isGraded'] as bool? ?? false);
                        }

                        // Sort by email or submission time if desired
                        final sortedDocs = docs.toList()
                          ..sort((a, b) {
                            final emailA = (a.data() as Map)['userEmail'] ?? '';
                            final emailB = (b.data() as Map)['userEmail'] ?? '';
                            return emailA.toLowerCase().compareTo(emailB.toLowerCase());
                          });

                        return ListView.builder(
                          itemCount: sortedDocs.length,
                          itemBuilder: (context, index) {
                            final doc = sortedDocs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final userId = doc.reference.parent.parent!.id;

                            final userEmail = data['userEmail'] as String? ?? "Unknown User";
                            final responses = List<String>.from(data['responses'] ?? []);
                            final hasSubmitted = responses.isNotEmpty;
                            final scores = _userScores[userId]!;
                            final feedback = _userFeedback[userId]!;
                            final isGraded = _userGradedStatus[userId]!;
                            final totalScore = scores.fold<int>(0, (a, b) => a + b);

                            final responseRef = doc.reference;

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
                                          hasSubmitted
                                              ? (isGraded ? Icons.verified : Icons.check_circle)
                                              : Icons.pending,
                                          size: 16.0,
                                          color: hasSubmitted
                                              ? (isGraded ? Colors.green : Colors.green)
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            userEmail,
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        if (hasSubmitted)
                                          Text(
                                            "$totalScore / ${responses.length}",
                                            style: const TextStyle(fontSize: 16, color: Colors.deepPurple),
                                          ),
                                      ],
                                    ),
                                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    children: hasSubmitted
                                        ? [
                                            // Answers with scoring buttons
                                            ...responses.asMap().entries.map((entry) {
                                              final ansIndex = entry.key;
                                              final answer = entry.value;
                                              final score = scores[ansIndex];

                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 16),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text("• Answer ${ansIndex + 1}: $answer"),
                                                    const SizedBox(height: 10),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: List.generate(2, (i) {
                                                        final isSelected = score == i;
                                                        return GestureDetector(
                                                          onTap: () {
                                                            setState(() {
                                                              scores[ansIndex] = i;
                                                            });
                                                          },
                                                          child: Container(
                                                            margin: const EdgeInsets.symmetric(horizontal: 8),
                                                            width: 40,
                                                            height: 30,
                                                            decoration: BoxDecoration(
                                                              color: isSelected
                                                                  ? _getColorForScore(i)
                                                                  : _getColorForScore(i).withOpacity(0.3),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                "$i",
                                                                style: TextStyle(
                                                                  fontSize: 20,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: isSelected ? Colors.white : Colors.black87,
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

                                            const Divider(),

                                            Text(
                                              "Total: $totalScore / ${responses.length}",
                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                            ),

                                            const SizedBox(height: 10),

                                            TextField(
                                              decoration: const InputDecoration(
                                                labelText: "Feedback (optional)",
                                                border: OutlineInputBorder(),
                                              ),
                                              maxLines: 3,
                                              controller: TextEditingController(text: feedback)
                                                ..addListener((dynamic controller) {
                                                  _userFeedback[userId] = controller.text;
                                                } as VoidCallback),
                                            ),

                                            const SizedBox(height: 16),

                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: isGraded ? Colors.grey : Colors.green,
                                                    ),
                                                    onPressed: isGraded
                                                        ? null
                                                        : () async {
                                                            await responseRef.set({
                                                              'scores': scores,
                                                              'totalScore': totalScore,
                                                              'feedback': _userFeedback[userId]?.trim().isEmpty ?? true
                                                                  ? null
                                                                  : _userFeedback[userId],
                                                              'isGraded': true,
                                                            }, SetOptions(merge: true));

                                                            setState(() {
                                                              _userGradedStatus[userId] = true;
                                                            });

                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(content: Text("Grading saved!")),
                                                            );
                                                          },
                                                    child: const Text("Grade"),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: isGraded ? Colors.red : Colors.grey,
                                                    ),
                                                    onPressed: isGraded
                                                        ? () async {
                                                            await responseRef.update({
                                                              'isGraded': false,
                                                              'scores': null,
                                                              'totalScore': null,
                                                              'feedback': null,
                                                            });

                                                            setState(() {
                                                              _userGradedStatus[userId] = false;
                                                              _userScores[userId] = List.filled(responses.length, 0);
                                                            });

                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(content: Text("Grading reset!")),
                                                            );
                                                          }
                                                        : null,
                                                    child: const Text("Reset"),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 20),
                                          ]
                                        : [
                                            const Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Text("No response submitted", style: TextStyle(color: Colors.grey)),
                                            )
                                          ],
                                  ),

                                  // Graded badge
                                  if (isGraded)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          "GRADED",
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  /*Expanded(
                    child: FutureBuilder<QuerySnapshot>(
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

                        return ListView.builder(
                          itemCount: memberSnapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final memberDoc = memberSnapshot.data!.docs[index];
                            final userId = memberDoc.id;
                            final memberData = memberDoc.data() as Map<String, dynamic>;
                            final userEmail = memberData['email'] ?? "No email";

                            final responseRef = _service.responsesCollection
                                .doc(type)
                                .collection(userId)
                                .doc(dateStr);

                            return StreamBuilder<DocumentSnapshot>(
                              stream: responseRef.snapshots(),
                              builder: (context, responseSnapshot) {
                                if (responseSnapshot.hasError) {
                                  return Center(child: Text("Error: ${responseSnapshot.error}"));
                                }

                                final doc = responseSnapshot.data;
                                if (doc == null || !doc.exists) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      leading: const Icon(Icons.pending, color: Colors.grey),
                                      title: Text(userEmail),
                                      subtitle: const Text("Not submitted yet"),
                                    ),
                                  );
                                }

                                final data = doc.data() as Map<String, dynamic>;
                                final responses = List<String>.from(data['responses'] ?? []);
                                final hasSubmitted = responses.isNotEmpty;

                                List<int> scores = _userScores.putIfAbsent(userId, () {
                                  final raw = data['scores'] as List<dynamic>?;
                                  if (raw == null || raw.isEmpty) {
                                    return List.filled(responses.length, 0);
                                  }
                                  final list = raw.map((e) => e is int ? e : 0).toList();
                                  if (list.length < responses.length) {
                                    return list..addAll(List.filled(responses.length - list.length, 0));
                                  }
                                  return list.length > responses.length ? list.sublist(0, responses.length) : list;
                                });

                                final feedback = _userFeedback.putIfAbsent(userId, () => data['feedback'] as String? ?? "");
                                final isGraded = _userGradedStatus.putIfAbsent(userId, () => data['isGraded'] as bool? ?? false);

                                final totalScore = scores.isEmpty ? 0 : scores.reduce((a, b) => a + b);

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
                                              hasSubmitted
                                                  ? (isGraded ? Icons.verified : Icons.check_circle)
                                                  : Icons.pending,
                                              size: 16.0,
                                              color: hasSubmitted
                                                  ? (isGraded ? Colors.green : Colors.green)
                                                  : const Color.fromARGB(255, 140, 140, 140),
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                userEmail,
                                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            if (hasSubmitted)
                                              Text(
                                                "$totalScore / ${responses.length}",
                                                style: const TextStyle(fontSize: 16, color: Colors.deepPurple),
                                              ),
                                          ],
                                        ),
                                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                                        initiallyExpanded: false,
                                        expandedAlignment: Alignment.topLeft,
                                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                                        children: hasSubmitted
                                            ? [
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
                                                  "Total: $totalScore / ${responses.length}",
                                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                                ),
                                                const SizedBox(height: 5),
                                                TextField(
                                                  decoration: const InputDecoration(
                                                    labelText: "Feedback (optional)",
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  maxLines: 2,
                                                  controller: () {
                                                    final ctrl = TextEditingController(text: feedback);
                                                    ctrl.addListener(() => _userFeedback[userId] = ctrl.text);
                                                    return ctrl;
                                                  }(),
                                                ),
                                                const SizedBox(height: 10),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: [
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: isGraded ? Colors.grey : const Color.fromARGB(255, 83, 222, 162),
                                                          padding: const EdgeInsets.symmetric(vertical: 15),
                                                        ),
                                                        onPressed: isGraded
                                                            ? null
                                                            : () async {
                                                                await responseRef.set({
                                                                  'scores': scores,
                                                                  'totalScore': totalScore,
                                                                  'feedback': _userFeedback[userId]!.trim().isEmpty ? null : _userFeedback[userId],
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
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: isGraded ? const Color.fromARGB(255, 227, 127, 127) : Colors.grey,
                                                          padding: const EdgeInsets.symmetric(vertical: 15),
                                                        ),
                                                        onPressed: isGraded
                                                            ? () async {
                                                                await responseRef.update({
                                                                  'isGraded': false,
                                                                  'scores': null,
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
                                                            : null,
                                                        child: const Text("Reset", style: TextStyle(fontSize: 18, color: Colors.white)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(height: 10),
                                                const SizedBox(height: 30),
                                              ]
                                            : [
                                                const Padding(
                                                  padding: EdgeInsets.all(16),
                                                  child: Text(
                                                    "Not submitted yet",
                                                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                                  ),
                                                ),
                                              ],
                                      ),
                                      if (isGraded)
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
                      },
                    ),
                  ),*/
                ],
              ),
            ),
    );
  }
}

extension on DocumentReference<Object?> {
  collectionGroup(String dateStr) {}
}*/