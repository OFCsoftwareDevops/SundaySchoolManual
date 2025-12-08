// lib/widgets/intro_page.dart
import 'package:flutter/material.dart';

import '../UI/buttons.dart';

class IntroPage extends StatelessWidget {
  final VoidCallback onFinish;
  const IntroPage({super.key, required this.onFinish});

  /*Future<void> _completeIntro(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenIntro', true);

    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.menu_book_rounded,
                size: 100,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 40),
              Text(
                "Welcome to Sunday School Curriculum",
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                "Access weekly Teen and Adult Bible study lessons anytime, anywhere — even offline!",
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: HomePageButtons(
                  context: context,
                  text: "Get Started",
                  topColor: Colors.deepPurple,
                  borderColor: const Color.fromARGB(0, 0, 0, 0),   // optional
                  onPressed: onFinish,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}