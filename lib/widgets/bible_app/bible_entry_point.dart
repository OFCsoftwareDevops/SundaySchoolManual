// lib/widgets/bible_app/bible_entry_point.dart
import 'package:flutter/material.dart';
import 'bible_loader.dart';
import 'bible_page.dart';

class BibleEntryPoint extends StatefulWidget {
  const BibleEntryPoint({super.key});

  @override
  State<BibleEntryPoint> createState() => _BibleEntryPointState();
}

class _BibleEntryPointState extends State<BibleEntryPoint> {
  bool _hasEnteredBible = false;

  @override
  Widget build(BuildContext context) {
    return _hasEnteredBible
        ? const BiblePage()                    // After first entry → always show book list
        : BibleLoader(
            onLoaded: () => setState(() => _hasEnteredBible = true),
          );
  }
}