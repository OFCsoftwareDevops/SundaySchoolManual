// NEW: Main screen with bottom navigation bar
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../backend_data/firestore_service.dart';
import '../backend_data/submitted_dates_provider.dart';
import '../auth/login/auth_service.dart';
import '../auth/login/login_page.dart';
import 'bible_app/bible_entry_point.dart';
import 'church_selection.dart';
import 'home.dart';
import 'user_page.dart';

class MainScreen extends StatefulWidget {
  final int initialTab;
  const MainScreen({super.key, this.initialTab = 0});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  // We'll build the Bible page lazily, only when needed
  Widget? _biblePageCache;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (selectedIndex != 0) { // If not on Home tab
          setState(() => selectedIndex = 0); // Go to Home
          return false; // Don't pop the app
        }
        return true; // Allow pop if on Home
      },
      child: Consumer<AuthService>(
        builder: (context, auth, child) {
          // Optional: show a loading spinner while auth data is syncing on cold start
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = FirebaseAuth.instance.currentUser;
          // If no user → go to login screen (same as main.dart)
          if (user == null) {
            return const AuthScreen();
          }
          // If user is signed in but no church and not anonymous → onboarding
          if (!auth.hasChurch && !user.isAnonymous) {
            return const ChurchOnboardingScreen();
          }
          
          return Scaffold(
            body: IndexedStack(
              index: selectedIndex,
              children: [
                const Home(),
                selectedIndex == 1 
                  ? const BibleEntryPoint() 
                  : const SizedBox.shrink(),           // ← only this, nothing else
                const UserProfileScreen(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF5D8668),
              unselectedItemColor: Colors.grey,
              currentIndex: selectedIndex,
              onTap: (index) => setState(() => selectedIndex = index),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Lessons"),
                BottomNavigationBarItem(icon: Icon(Icons.book), label: "Bible"),
                BottomNavigationBarItem(icon: Icon(Icons.verified_user), label: "My Account"),
                //BottomNavigationBarItem(icon: Icon(Icons.church), label: "My Parish"),
                /*BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),*/
              ],
            ),
          );
        }
      ),
    );
  }
}

