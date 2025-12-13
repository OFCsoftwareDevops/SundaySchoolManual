// lib/screens/admin_assignment_responses_page.dart
import 'package:app_demo/auth/login/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../UI/linear_progress_bar.dart';
import '../../../backend_data/firestore_service.dart';

class AdminAssignmentResponsesPage extends StatefulWidget {
  final DateTime date;
  final bool isTeen;

  const AdminAssignmentResponsesPage({
    super.key,
    required this.date,
    required this.isTeen,
  });

  @override
  State<AdminAssignmentResponsesPage> createState() => _AdminAssignmentResponsesPageState();
}

class _AdminAssignmentResponsesPageState extends State<AdminAssignmentResponsesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _responses = [];
  late FirestoreService _service;

  @override
  void initState() {
    super.initState();
    final churchId = context.read<AuthService>().churchId;
    _service = FirestoreService(churchId: churchId);
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    setState(() => _isLoading = true);
    final churchId = context.read<AuthService>().churchId;

    try {
      final responses = await _service.loadResponsesForAdmin(
        date: widget.date,
        type: widget.isTeen ? 'teen' : 'adult',
        adminChurchId: churchId,
      );

      // Ensure all items are non-null maps
      _responses = responses
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e, st) {
      debugPrint("Error loading responses for admin: $e\n$st");
      _responses = [];
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Widget _buildResponseCard(Map<String, dynamic> data) {
    final userEmail = data['userEmail'] ?? 'Unknown';
    final dateStr = data['date'] ?? '';
    final responses = (data['responses'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final grade = data['grade']?.toString() ?? 'Not graded';
    final feedback = data['feedback']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userEmail,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text("Submitted: $dateStr"),
            const SizedBox(height: 8),
            Text(
              "Responses:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...responses.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text("- $r"),
                )),
            const SizedBox(height: 8),
            Text("Grade: $grade"),
            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text("Feedback: $feedback"),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('MMMM d, yyyy').format(widget.date);

    return Scaffold(
      appBar: AppBar(
        title: Text("Responses for $dateFormatted (${widget.isTeen ? 'Teen' : 'Adult'})"),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: LinearProgressBar())
          : _responses.isEmpty
              ? const Center(child: Text("No responses found"))
              : RefreshIndicator(
                  onRefresh: _loadResponses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _responses.length,
                    itemBuilder: (context, index) {
                      final data = _responses[index];
                      return _buildResponseCard(data);
                    },
                  ),
                ),
    );
  }
}
