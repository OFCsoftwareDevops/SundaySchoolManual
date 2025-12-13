import 'package:app_demo/l10n/fallback_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; 
import 'UI/linear_progress_bar.dart';
import 'auth/database/constants.dart';
import 'auth/login/auth_service.dart';
import 'auth/login/login_page.dart';
import 'widgets/bible_app/highlight/highlight_manager.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'widgets/bible_app/bible.dart';
import 'widgets/church_selection.dart';
import 'widgets/intro_page.dart';
import 'widgets/main_screen.dart';
import 'widgets/preload_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);  // Required in v15.1.3+
  print("Background: ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //await CurrentChurch.instance.loadFromPrefs();

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // FCM setup (only mobile)
  if (!kIsWeb) {
    await FirebaseMessaging.instance.requestPermission();
    await FirebaseMessaging.instance.subscribeToTopic("all_users");
    final token = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $token");
  }

  // 3. Now safely read SharedPreferences (already loaded above)
  final prefs = await SharedPreferences.getInstance();
  final String savedLang = prefs.getString('language_code') ?? 'en';
  // Load highlights early
  await HighlightManager().loadFromPrefs();

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null && ownerEmails.contains(currentUser.email)) {
    await FirebaseMessaging.instance.subscribeToTopic("owner_notifications");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ←←←← NEW: Initialize the AuthService sync ←←←←
  await AuthService.instance.init();

  // 4. Run the app with ALL providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BibleVersionManager()),
        ChangeNotifierProvider(create: (_) => HighlightManager()), // Already loaded!
        // AuthService now provides church + roles + loading state
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService.instance),
        // Add more providers here later (ThemeManager, UserManager, etc.)
      ],
      child: MyApp(
        initialLocale: Locale(savedLang),
      ),
    ),
  );
}

// =============== NEW: Language-aware MyApp ===============
class MyApp extends StatefulWidget {
  //final bool hasSeenIntro;
  final Locale initialLocale;

  const MyApp({super.key, /*required this.hasSeenIntro,*/ required this.initialLocale});

  // Allow changing language from anywhere in the app
  static void setLocale(BuildContext context, Locale newLocale) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?.changeLanguage(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver{
  late Locale _locale;
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    WidgetsBinding.instance.addObserver(this); // Listen for app close
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Detect full app close to reset intro
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _showIntro = true;
      print("📴 App fully closed → will show intro next time");
    }
  }

  void changeLanguage(Locale locale) async {
    if (_locale == locale) return;
    setState(() => _locale = locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: _locale,
      
        // THIS IS THE ONLY LIST THAT WORKS FOR en + fr + yo
        localizationsDelegates: const [
          AppLocalizations.delegate,     
          GlobalMaterialLocalizations.delegate, // ← supports en + fr fully
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FallbackMaterialLocalizationsDelegate(),
          FallbackCupertinoLocalizationsDelegate(),
        ],
        supportedLocales: AppLocalizations.supportedLocales, // en, fr, yo
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Color.fromARGB(255, 255, 255, 255).withOpacity(0.3), // APP THEME COLOR
          fontFamily: 'Roboto', // Set default font family
        ),
        home: Consumer<AuthService>(
          builder: (context, auth, child) {
            // Still loading auth state / church / roles
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(child: LinearProgressBar()),
              );
            }

            // Show intro only on very first app open ever
            if (_showIntro) {
              return IntroPage(
                onFinish: () {
                  setState(() => _showIntro = false);
                  // Go to preload screen instead of directly to MainScreen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const PreloadScreen()),
                  );
                },
              );
            }
            // No user signed in → go to your login / signup flow
            if (auth.currentUser == null) {
              return const AuthScreen();
            }
            // User signed in but no church selected yet
            if (!auth.hasChurch) {
              return const ChurchOnboardingScreen(); // Your join/create church page
            }
            // Everything ready → go to main app
            return const MainScreen();
          },
        ),
      );
  }
}