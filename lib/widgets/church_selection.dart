// lib/screens/church_selector.dart
import 'package:app_demo/auth/database/current_church.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main_screen.dart';

class ChurchSelector extends StatefulWidget {
  const ChurchSelector({super.key});

  @override 
  State<ChurchSelector> createState() => _ChurchSelectorState();
}

class _ChurchSelectorState extends State<ChurchSelector> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _continue() {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    // Use input as both ID and display name (clean & simple)
    final churchId = input.toLowerCase().replaceAll(' ', '_'); // e.g. "Grace Lagos" → "grace_lagos"
    final churchName = input;

    context.read<CurrentChurch>().setChurch(churchId, churchName);

    // Close the ChurchSelector and return to the Lessons tab (tab 0)
    Navigator.pop(context);

    // Force switch back to the first tab (Lessons)
    final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
    mainScreenState?.selectTab(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5D8668), Color(0xFFEEFFEE)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const SizedBox(height: 80),
                // YOUR BEAUTIFUL LOGO REPLACES THE OLD ICON
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.25),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/rccg_logo.png',   // your logo file
                        height: 120,
                        width: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback if logo not found → show the church icon
                          return const Icon(Icons.church, size: 80, color: Colors.white);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Welcome",
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Enter your Church ID or Parish Name",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.white70),
                ),
                const SizedBox(height: 60),

                // Church Input Field
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _continue(),
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "e.g. Grace Lagos, Jesus House DC, throne_room",
                    prefixIcon: const Icon(Icons.search, color: Color.fromARGB(203, 93, 134, 104)),
                    suffixIcon: _hasText
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _hasText = false);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  ),
                ),

                const SizedBox(height: 12),

                // Helper text
                const Text(
                  "Parish name provided by your administrator. ",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color.fromARGB(192, 255, 255, 255), fontSize: 15),
                ),

                const Spacer(),

                // === BEAUTIFUL "USE GENERAL MODE" BUTTON ===
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      // 1. Force General mode (clear any saved parish)
                      context.read<CurrentChurch>().clear();

                      // 2. Close the ChurchSelector and go back to the Lessons tab
                      Navigator.pop(context);

                      // 3. Make sure we're on the Lessons tab (tab 0)
                      final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
                      mainScreenState?.selectTab(0);
                    },
                    child: const Text(
                      "Use General Mode",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Main Continue button (already there)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _hasText ? _continue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 10,
                    ),
                    child: const Text(
                      "LOG IN",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}