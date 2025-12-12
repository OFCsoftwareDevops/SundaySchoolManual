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
import 'auth/database/constants.dart';
import 'widgets/bible_app/highlight/highlight_manager.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'widgets/bible_app/bible.dart';
import 'auth/database/current_church.dart';
import 'widgets/intro_page.dart';
import 'widgets/main_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);  // Required in v15.1.3+
  print("Background: ${message.notification?.title}");
}

/*void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load highlights early
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 2. Run ALL async initializations in parallel (super fast!)
  await Future.wait([
    // Load user preferences (language, church, etc.)
    SharedPreferences.getInstance().then((prefs) async {
      // You can pre-read values here if needed
    }),

    // Load highlights from SharedPreferences
    HighlightManager().loadFromPrefs(),

    // FCM setup (only on mobile)
    if (!kIsWeb)
      FirebaseMessaging.instance.requestPermission().then((_) async {
        await FirebaseMessaging.instance.subscribeToTopic("all_users");
        final token = await FirebaseMessaging.instance.getToken();
        print("FCM Token: $token");
      }),
  ]);*/
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    if (ownerEmails.contains(currentUser.email)) {
      await FirebaseMessaging.instance.subscribeToTopic("owner_notifications");
    }
  }
  // 4. Run the app with ALL providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BibleVersionManager()),
        ChangeNotifierProvider(create: (_) => HighlightManager()), // Already loaded!
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
      print("📴 App fully closed → will show intro next time");
      _showIntro = true;
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
    return ChangeNotifierProvider(
      create: (_) => CurrentChurch()..loadFromPrefs(),
      /*create: (_) {
        final church = CurrentChurch();
        // Load saved church efficiently
        SharedPreferences.getInstance().then((prefs) {
          final churchId = prefs.getString('church_id');
          final churchName = prefs.getString('church_name');
          if (churchId != null && churchName != null) {
            church.setChurch(churchId, churchName);
          }
        });
        return church;
      },*/
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: _locale,
      
        // THIS IS THE ONLY LIST THAT WORKS FOR en + fr + yo
        localizationsDelegates: const [
          AppLocalizations.delegate,
      
          GlobalMaterialLocalizations.delegate, // ← supports en + fr fully
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
      
          // THIS IS THE FINAL PIECE – silences the red screen forever
          FallbackMaterialLocalizationsDelegate(),
          FallbackCupertinoLocalizationsDelegate(),
        ],
        supportedLocales: AppLocalizations.supportedLocales, // en, fr, yo
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Color.fromARGB(255, 255, 255, 255).withOpacity(0.3), // APP THEME COLOR
          fontFamily: 'Roboto', // Set default font family
        ),
        home: _showIntro
          ? IntroPage(
            onFinish: () {
              setState(() => _showIntro = false);
              /*Future.microtask(() {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                  );
                }
              });*/
            },
          )
        : const MainScreen(),
      ),
    );
  }
}