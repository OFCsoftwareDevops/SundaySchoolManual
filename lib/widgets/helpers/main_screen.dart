// NEW: Main screen with bottom navigation bar
import 'package:app_demo/UI/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/login/auth_service.dart';
import '../../auth/login/login_page.dart';
import '../../backend_data/service/ads/banner_ads.dart';
import '../../backend_data/service/analytics/analytics_service.dart';
import '../../utils/device_check.dart';
import '../bible_app/bible_entry_point.dart';
import 'church_selection.dart';
import '../home.dart';
import '../profile/user_page.dart';

class MainScreen extends StatefulWidget {
  final int initialTab;
  const MainScreen({super.key, this.initialTab = 0});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late int selectedIndex;

  // One navigator key per tab
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(3, (_) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Let current tab handle back first
        final currentNavigator = _navigatorKeys[selectedIndex].currentState;
        if (currentNavigator?.canPop() ?? false) {
          currentNavigator!.pop();
          return false;
        }

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
                // Tab 0: Lessons/Home
                Navigator(
                  key: _navigatorKeys[0],
                  onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const Home()),
                ),
                // Tab 1: Bible
                Navigator(
                  key: _navigatorKeys[1],
                  onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const BibleEntryPoint()),
                ),
                // Tab 2: Profile
                Navigator(
                  key: _navigatorKeys[2],
                  onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Consumer<AuthService>(
                builder: (context, _, __) {
                  final scale = context.tabletScaleFactor;
                  final screenHeight = MediaQuery.of(context).size.height;

                  // Same formula as your lesson buttons
                  final double buttonHeight = screenHeight * 0.06 * scale;

                  // Total height = banner (50dp fixed by Google) + scaled nav bar
                  final double navBarHeight = buttonHeight;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ←←←← THE BANNER AD GOES HERE
                      const BannerAdWidget(), // Our reusable widget
                  
                      SizedBox(
                        height: navBarHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface, // ← Key: adapts perfectly!
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 0.5,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: BottomNavigationBar(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            type: BottomNavigationBarType.fixed,
                            selectedItemColor: Theme.of(context).colorScheme.primaryContainer, // Wine red
                            unselectedItemColor: Theme.of(context).colorScheme.onSurface,
                            selectedFontSize: navBarHeight * 0.22,   // ~10-12dp text
                            unselectedFontSize: navBarHeight * 0.20,
                            iconSize: navBarHeight * 0.45,
                            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
                            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
                            currentIndex: selectedIndex,
                            onTap: (index) async {
                              // Log which tab was clicked
                              switch (index) {
                                case 0:
                                  await AnalyticsService.logButtonClick('home_tab');
                                  break;
                                case 1:
                                  await AnalyticsService.logButtonClick('bible_tab');
                                  break;
                                case 2:
                                  await AnalyticsService.logButtonClick('profile_tab');
                                  break;
                              }
                        
                              if (index == selectedIndex) {
                                // Same tab tapped → pop to root (fresh start)
                                _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
                              } else {
                                // Different tab → switch and reset to root (except Bible)
                                setState(() => selectedIndex = index);
                                
                                if (index != 1) { // Not Bible tab
                                  _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
                                }
                                // Bible tab keeps its stack — resume works
                              }
                          
                              // ----------------- TO ALWAYS RESET ONLY PROFILE TAB TO ROOT, UNCOMMENT BELOW AND REMOVE THE ABOVE BLOCK
                              /*setState(() => selectedIndex = index);
                          
                              // Always reset Profile tab to root
                              if (index == 2) {
                                _navigatorKeys[2].currentState?.popUntil((route) => route.isFirst);
                              }*/
                          
                              // ----------------- TO RESUME ALL TABS (NOT ONLY BIBLE), UNCOMMENT BELOW AND REMOVE THE ABOVE BLOCK
                              /*if (index == selectedIndex) {
                                // If same tab tapped, pop to root of that tab
                                _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
                              } else {
                                setState(() => selectedIndex = index);
                              }*/
                          
                              // Resume Bible only when tapping Bible tab
                              if (index == 1) {
                                final bibleState = _navigatorKeys[1].currentState?.context.findAncestorStateOfType<BibleEntryPointState>();
                                await bibleState?.resumeLastPosition();
                              }
                            },
                            /*onTap: (index) async {
                              setState(() => selectedIndex = index);
                              if (index == 1) {
                                final bibleState = context.findAncestorStateOfType<BibleEntryPointState>();
                                await bibleState?.resumeLastPosition(); // ← Resume ONLY when tapped
                              }
                            },*/
                            
                            items: const [
                              BottomNavigationBarItem(
                                icon: Icon(Icons.home), 
                                label: "Home",
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(Icons.book),
                                label: "Bible",
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(Icons.verified_user), 
                                label: "Account",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
              ),
            ),
          );
        }
      ),
    );
  }
}

