// NEW: Main screen with bottom navigation bar
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  Widget _buildAccountScreen(AuthService auth) {
    final user = FirebaseAuth.instance.currentUser;

    // Not signed in → login
    if (user == null) {
      return const AuthScreen();
    }

    // Signed in: has church OR guest → profile
    if (auth.hasChurch || user.isAnonymous) {
      return const UserProfileScreen();
    }

    // Signed in but no church decision yet → onboarding
    return const ChurchOnboardingScreen();
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
          return Scaffold(
            body: IndexedStack(
              index: selectedIndex,
              children: [
                const Home(),
                selectedIndex == 1 
                  ? const BibleEntryPoint() 
                  : const SizedBox.shrink(),           // ← only this, nothing else
                _buildAccountScreen(auth),
                //const ChurchSelector(),
                /*Center(child: Text("Profile", style: TextStyle(fontSize: 24))),
                Center(child: Text("Settings", style: TextStyle(fontSize: 24))),*/
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