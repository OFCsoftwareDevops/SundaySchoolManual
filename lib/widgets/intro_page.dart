// lib/widgets/intro_page.dart
import 'package:flutter/material.dart';

import '../UI/buttons.dart';

class IntroPage extends StatelessWidget {
  final VoidCallback? onFinish;
  final bool isLoading;

  const IntroPage({
    super.key, 
    required this.onFinish,
    required this.isLoading,
  });

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
                  text: isLoading ? "Preparing..." : "Get Started",
                  topColor: isLoading ? const Color.fromARGB(255, 57, 56, 58): Colors.deepPurple,
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