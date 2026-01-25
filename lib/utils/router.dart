// lib/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../UI/app_linear_progress_bar.dart';
import '../auth/login/auth_service.dart';
import '../auth/login/login_page.dart';
import '../backend_data/database/lesson_data.dart';
import '../backend_data/service/firestore/firestore_service.dart';
import '../widgets/SundaySchool_app/lesson_preview.dart'; // ← BeautifulLessonPage
import '../widgets/church/church_selection.dart';
import '../widgets/helpers/main_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainScreen(),
    ),

    GoRoute(
      path: '/lesson/:id',
      name: 'lesson-detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;

        DateTime lessonDate;
        try {
          final parts = id.split('-');
          if (parts.length != 3) throw const FormatException('Invalid ID format');

          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);

          lessonDate = DateTime(year, month, day);
        } catch (e) {
          return Scaffold(
            body: Center(
              child: Text(
                'Invalid lesson ID: $id\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
          );
        }

        final isTeen = state.uri.queryParameters['type']?.toLowerCase() == 'teen';

        // Return the FutureBuilder directly
        return FutureBuilder<SectionNotes?>(
          future: context.read<FirestoreService>().getLessonByDate(
            context,
            lessonDate,
            isTeen: isTeen,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text(
                    'Error loading lesson:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final data = snapshot.data;
            if (data == null) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sentiment_dissatisfied_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No lesson found for ${DateFormat('MMM d, yyyy').format(lessonDate)}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Back to Home'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final title = data.topic.isNotEmpty
                ? data.topic
                : 'Sunday School • ${DateFormat('MMMM d, yyyy').format(lessonDate)}';

            return BeautifulLessonPage(
              data: data,
              title: title,
              lessonDate: lessonDate,
              isTeen: isTeen,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/loading',
      builder: (context, state) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: LinearProgressBar()),
        ),
      ),
    ),

    GoRoute(
      path: '/login',
      builder: (context, state) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const AuthScreen(),
      ),
    ),

    GoRoute(
      path: '/church-onboarding',
      builder: (context, state) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const ChurchOnboardingScreen(),
      ),
    ),
  ],

  redirect: (context, state) {
    final auth = context.read<AuthService>();

    if (state.uri.path == '/' || state.uri.path.startsWith('/lesson/')) {
      if (auth.isLoading) {
        return '/loading';
      }

      if (auth.currentUser == null) {
        return '/login?redirect=${Uri.encodeComponent(state.uri.toString())}';
      }

      final user = auth.currentUser!;
      if (!auth.hasChurch && !user.isAnonymous) {
        return '/church-onboarding?redirect=${Uri.encodeComponent(state.uri.toString())}';
      }
    }

    return null;
  },

  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page not found\n${state.uri}')),
  ),
);