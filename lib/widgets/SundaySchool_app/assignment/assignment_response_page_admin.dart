// lib/widgets/assignment_response_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../UI/app_buttons.dart';
import '../../../UI/app_colors.dart';
import '../../../auth/login/auth_service.dart';
import '../../../backend_data/service/firestore_service.dart';
import '../../../backend_data/database/lesson_data.dart';
import '../../../utils/media_query.dart';

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

    final style = CalendarDayStyle.fromContainer(context, 50);

    // If no church, show message
    if ((!isGlobalAdmin || !isGroupAdmin) && churchId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Responses")),
        body: const Center(child: Text("Global admins only — no church selected.")),
      );
    }

    /*final membersCollection = isGlobalAdmin || isGroupAdmin
        ? null // Global admin sees all — we'll load responses directly
        : FirebaseFirestore.instance.collection('churches').doc(churchId).collection('members');*/

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown, // Scales down text if it would overflow
          child: Text(
            "${widget.isTeen ? 'Teen' : 'Adult'} Responses",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: style.monthFontSize.sp, // Matches your other screen's style
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: style.monthFontSize.sp, // Consistent sizing
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: _loading
          ? const Center(child: LinearProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
                  Card(
                    // Use surface color from theme (elevated surface in Material 3)
                    color: Theme.of(context).colorScheme.surface,

                    // Optional: add a slight surface tint or keep it clean
                    // surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,

                    child: Padding(
                      padding: EdgeInsets.all(20.sp),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Question",
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              //color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: 10.sp),
                          Text(
                            _question,
                            style: TextStyle(
                              fontSize: 15.sp,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.sp),
                  Text(
                    "Submissions",
                    style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
                  ),
                  Divider(height: 30.sp),
                  Expanded(
                    child: _buildAdminView(type, dateStr),
                  ),
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
            margin: EdgeInsets.only(bottom: 10.sp),
            child: Stack(
              children: [
                ExpansionTile(
                  // Use theme colors for icons and text
                  leading: Icon(
                    isGraded ? Icons.check_circle : Icons.pending,
                    size: 16.sp,
                    color: isGraded
                        ? Theme.of(context).colorScheme.onSurface // Brand blue when graded
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.0),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 6.sp),
                      Expanded(
                        child: Text(
                          response.userEmail ?? response.userId,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 8.sp),
                        child: Text(
                          "${scores.fold<int>(0, (a, b) => a + b)} / ${response.responses.length}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  iconColor: Theme.of(context).colorScheme.onSurface,
                  collapsedIconColor: Theme.of(context).colorScheme.onSurface,
                  // This forces the default chevron to appear and be styled nicely
                  /*trailing: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),*/
                  childrenPadding: EdgeInsets.all(16.sp),
                  children: [
                    ...response.responses.asMap().entries.map((entry) {
                      final i = entry.key;
                      final answer = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "• Answer ${i + 1}: $answer",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: 10.sp),
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
                                  margin: EdgeInsets.symmetric(horizontal: 6.sp),
                                  width: 40.sp,
                                  height: 30.sp,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: scores[i] == score
                                        ? _getColorForScore(score, context)
                                        : _getColorForScore(score, context).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(2.sp),
                                  ),
                                  child: Text(
                                    "$score",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Reset Button (destructive)
                              GradeButtons(
                                context: context,
                                onPressed: isGraded
                                    ? () async {
                                        await _service.resetGrading(
                                          userId: response.userId,
                                          date: widget.date,
                                          type: type,
                                        );
                                        setState(() {});
                                      }
                                    : null, // disabled if not graded
                                text: "Reset",
                                icon: Icons.restore,
                                topColor: Theme.of(context).colorScheme.error,
                                textColor: Theme.of(context).colorScheme.onError,
                                backDarken: 0.5, // deeper shadow for red to enhance depth
                                //borderColor: Theme.of(context).colorScheme.error.withOpacity(0.6),
                                //borderWidth: 1.5,
                              ),

                              GradeButtons(
                                context: context,
                                onPressed: isGraded
                                    ? null // disabled when already graded
                                    : () async {
                                        await _service.saveGrading(
                                          userId: response.userId,
                                          date: widget.date,
                                          type: type,
                                          scores: scores,
                                        );
                                        setState(() {});
                                      },
                                text: "Grade",
                                icon: Icons.check_circle_outline,
                                topColor: Theme.of(context).colorScheme.onSurface,
                                textColor: Theme.of(context).colorScheme.surface,
                                //backDarken: 0.35, // softer shadow for primary
                              ),
                            ],
                          ),
                          //SizedBox(height: 12.sp),
                        ],
                      );
                    }),
                  ],
                ),
                // ✅ Graded stamp overlay
                if (_userGradedStatus[response.userId] ?? false)
                  Positioned(
                    bottom: 4.sp,
                    right: 4.sp,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.sp, vertical: 3.sp),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary, // Brand blue
                        borderRadius: BorderRadius.circular(12.sp),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 12.sp),
                          SizedBox(width: 4.sp),
                          Text(
                            "Graded",
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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

  Color _getColorForScore(int score, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (score) {
      case 0: return AppColors.error;
      case 1: return AppColors.success;
      default: return colorScheme.onSurface.withOpacity(0.4);
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