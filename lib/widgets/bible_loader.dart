import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bible.dart';
import 'main_screen.dart';

class BibleLoader extends StatefulWidget {
  const BibleLoader({super.key});
  @override
  State<BibleLoader> createState() => _BibleLoaderState();
}

class _BibleLoaderState extends State<BibleLoader> {
  @override
  void initState() {
    super.initState();
    _loadBibleOnce();
  }

  Future<void> _loadBibleOnce() async {
    await context.read<BibleVersionManager>().loadInitialBible();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.menu_book_rounded, size: 110, color: Color(0xFF5D8668)),
            SizedBox(height: 50),
            Text(
              "Preparing the Holy Bible",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF5D8668)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Color(0xFF5D8668), strokeWidth: 5),
            SizedBox(height: 30),
            Text("One moment please...", style: TextStyle(fontSize: 18, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}