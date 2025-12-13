import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_demo/widgets/main_screen.dart'; // your MainScreen
import '../UI/linear_progress_bar.dart';
import 'bible_app/bible.dart';
import 'bible_app/highlight/highlight_manager.dart'; // BibleVersionManager

class PreloadScreen extends StatefulWidget {
  const PreloadScreen({super.key});

  @override
  State<PreloadScreen> createState() => _PreloadScreenState();
}

class _PreloadScreenState extends State<PreloadScreen> {
  @override
  void initState() {
  super.initState();
    _preloadEverything();
  }

  Future<void> _preloadEverything() async {
    // Pre-load Bible data in background
    await context.read<BibleVersionManager>().loadInitialBible();

    // Optional: pre-load other heavy things here
    await HighlightManager().loadFromPrefs();

    if (!mounted) return;

    // All done → go to main app
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressBar(),
            SizedBox(height: 24),
            Text(
              "Preparing to serve...",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}