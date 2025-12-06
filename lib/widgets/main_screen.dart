// NEW: Main screen with bottom navigation bar
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bible_app/bible_entry_point.dart';
import 'church_selection.dart';
import 'home.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // We'll build the Bible page lazily, only when needed
  Widget? _biblePageCache;

  void selectTab(int index) async {
    if (index == 1) { // Bible tab
    // First time tapping Bible? → decide if we should resume
      if (_biblePageCache == null) {
        // First time entering Bible → decide if we should resume
        final prefs = await SharedPreferences.getInstance();
        final String? lastScreen = prefs.getString('last_screen');
        final bool shouldResume = lastScreen == 'chapter'; // only resume if they were inside a chapter

        /*setState(() {
          _biblePageCache = BibleEntryPoint(
            resumeLastPosition: shouldResume,
          );
        });*/
      }
      setState(() => _selectedIndex = index);
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          Home(),
          BibleEntryPoint(),           // ← only this, nothing else
          ChurchSelector(),
          /*Center(child: Text("Profile", style: TextStyle(fontSize: 24))),
          Center(child: Text("Settings", style: TextStyle(fontSize: 24))),*/
        ],
        /*children: [
          const Home(),
          // This will be null on first app open → shows nothing wrong
          // But once user taps Bible once, it stays cached (perfect behavior)
          //_biblePageCache ?? const SizedBox(), // ← stays empty until Bible tab tapped
          _selectedIndex == 1
              ? const BibleEntryPoint(resumeLastPosition: true) // ← always try to resume
              : const SizedBox.shrink(),
          const ChurchSelector(),
          const Center(child: Text("Profile", style: TextStyle(fontSize: 24))),
          const Center(child: Text("Settings", style: TextStyle(fontSize: 24))),
        ],*/
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF5D8668),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Lessons"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Bible"),
          BottomNavigationBarItem(icon: Icon(Icons.church), label: "My Parish"),
          /*BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),*/
        ],
      ),
    );
  }
}