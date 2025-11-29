import 'package:app_demo/l10n/fallback_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'widgets/home.dart';
import 'widgets/intro_page.dart';


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();  // Required in v15.1.3+
  print("Background: ${message.notification?.title}");
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Add this in main() after Firebase.initializeApp()
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  // FCM Setup
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // Request permission (iOS)
  await FirebaseMessaging.instance.requestPermission();
  await FirebaseMessaging.instance.subscribeToTopic("all_users");
  // Check if intro seen
  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;
  final String savedLang = prefs.getString('language_code') ?? 'en';
  // Get token (optional: save to user profile for targeting)
  final token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");
  
  runApp(MyApp(
    hasSeenIntro: hasSeenIntro,
    initialLocale: Locale(savedLang),
  ));
}

// =============== NEW: Language-aware MyApp ===============
class MyApp extends StatefulWidget {
  final bool hasSeenIntro;
  final Locale initialLocale;

  const MyApp({super.key, required this.hasSeenIntro, required this.initialLocale});

  // Allow changing language from anywhere in the app
  static void setLocale(BuildContext context, Locale newLocale) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?.changeLanguage(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
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
      locale: _locale,  // ← Keeps switching working via setState

      // THIS IS THE ONLY LIST THAT WORKS FOR en + fr + yo
      localizationsDelegates: const [
        AppLocalizations.delegate,                    // your strings

        GlobalMaterialLocalizations.delegate,         // ← supports en + fr fully
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,

        // THIS IS THE FINAL PIECE – silences the red screen forever
        FallbackMaterialLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
      ],
      supportedLocales: AppLocalizations.supportedLocales,// en, fr, yo
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.3), // APP THEME COLOR
      ),
      initialRoute: widget.hasSeenIntro ? '/home' : '/intro',
      routes: {
        '/intro': (_) => const IntroPage(),
        '/home': (_) => const Home(),
      },
    );
  }
}