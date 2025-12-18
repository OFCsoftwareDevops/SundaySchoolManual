import 'dart:io';

import 'package:app_demo/l10n/fallback_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; 
import 'UI/linear_progress_bar.dart';
import 'auth/database/constants.dart';
import 'auth/login/auth_service.dart';
import 'auth/login/login_page.dart';
import 'backend_data/assignment_dates_provider.dart';
import 'backend_data/firestore_service.dart';
import 'widgets/bible_app/highlight/highlight_manager.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'widgets/bible_app/bible.dart';
import 'widgets/church_selection.dart';
import 'widgets/intro_page.dart';
import 'widgets/main_screen.dart';

//final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

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

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ✅ Fit the entire screen
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // FCM setup (only mobile)
  if (!kIsWeb /*&& (Platform.isAndroid || Platform.isIOS)*/) {
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
        // Load Firestore
        Provider<FirestoreService>(create: (_) => FirestoreService(churchId: null)),
        // Add more providers here later (ThemeManager, UserManager, etc.)
        // NEW: Assignment Dates for Admin
        ChangeNotifierProvider<AssignmentDatesProvider>(
          create: (context) {
            final service = Provider.of<FirestoreService>(context, listen: false);
            final provider = AssignmentDatesProvider();
            provider.load(service); // Load instantly from preload
            return provider;
          },
        ),
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
    final state = context.findAncestorStateOfType<MyAppState>();
    state?.changeLanguage(newLocale);
  }

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver{
  late Locale _locale;
  bool _showIntro = true;
  bool _isPreloading = false;
  bool preloadDone = false;
  int preloadProgress = 0; // 0 to 3
  static const int totalPreloadSteps = 3;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    _startPreload();
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

  Future<void> _startPreload() async {
    setState(() {
      _isPreloading = true;
      preloadProgress = 0; // reset just in case
    });

    // Step 1
    await HighlightManager().loadFromPrefs();
    setState(() => preloadProgress = 1);

    // Step 2
    await context.read<FirestoreService>().preload();
    setState(() => preloadProgress = 2);

    // Step 3
    await context.read<BibleVersionManager>().loadInitialBible();
    setState(() => preloadProgress = 3);

    if (!mounted) return;
    setState(() {
      _isPreloading = false;
      preloadDone = true;
    });
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
        /*routes: {
          '/': (context) => MainScreen(),
        },*/
        home: Consumer<AuthService>(
          builder: (context, auth, child) {  
            // Show intro only on very first app open ever
            if (_showIntro) {
              return IntroPage(
                preloadDone: preloadDone,
                isLoading: !preloadDone,
                preloadProgress: preloadProgress,
                onFinish: preloadDone
                    ? () => setState(() => _showIntro = false)
                    : null, 
              );
            }

            // Still loading auth state / church / roles
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(child: LinearProgressBar()),
              );
            }
            
            // No user signed in → go to your login / signup flow
            if (auth.currentUser == null) {
              return const AuthScreen();
            }
            // User signed in but no church selected yet
            // Skip church selection if user is anonymous (guest mode)
            final user = auth.currentUser!;
            if (!auth.hasChurch && !user.isAnonymous) {
              return const ChurchOnboardingScreen();
            }
            // Everything ready → go to main app
            return MainScreen();
          },
        ),
      );
  }
}