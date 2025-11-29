// lib/screens/admin_editor.dart

import 'package:flutter/material.dart';
import '../backend_data/lesson_data.dart';
import '../backend_data/firestore_service.dart';
import 'lesson_form.dart';

class AdminEditorPage extends StatefulWidget {
  final DateTime date;
  final String? churchId;

  const AdminEditorPage({
    super.key,
    required this.date,
    this.churchId,
  });

  @override
  State<AdminEditorPage> createState() => _AdminEditorPageState();
}

class _AdminEditorPageState extends State<AdminEditorPage> {
  late SectionNotes teenNotes;
  late SectionNotes adultNotes;
  late final FirestoreService _service;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _service = FirestoreService(churchId: widget.churchId);
    teenNotes = SectionNotes.empty();
    adultNotes = SectionNotes.empty();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final day = await _service.loadLesson(widget.date);
      if (day != null && mounted) {
        setState(() {
          teenNotes = day.teenNotes ?? SectionNotes.empty();
          adultNotes = day.adultNotes ?? SectionNotes.empty();
        });
      }
    } catch (e) {
      debugPrint("Load error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load lesson"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await _service.saveLesson(
        date: widget.date,
        teenTopic: teenNotes.topic.isEmpty ? null : teenNotes.topic,
        teenPassage: teenNotes.biblePassage.isEmpty ? null : teenNotes.biblePassage,
        teenBlocks: teenNotes.blocks.isEmpty ? null : teenNotes.blocks,
        adultTopic: adultNotes.topic.isEmpty ? null : adultNotes.topic,
        adultPassage: adultNotes.biblePassage.isEmpty ? null : adultNotes.biblePassage,
        adultBlocks: adultNotes.blocks.isEmpty ? null : adultNotes.blocks,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Save failed"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit: ${widget.date.toLocal().toString().split(' ')[0]}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && teenNotes.blocks.isEmpty && adultNotes.blocks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text("Teen Lesson", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: LessonForm(
                      initialData: teenNotes,
                      onChanged: (updated) => setState(() => teenNotes = updated),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                const Divider(thickness: 2, color: Colors.deepPurple),

                const Text("Adult Lesson", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: LessonForm(
                      initialData: adultNotes,
                      onChanged: (updated) => setState(() => adultNotes = updated),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SAVE BOTH LESSONS", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
    );
  }
}