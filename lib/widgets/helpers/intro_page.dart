// lib/widgets/intro_page.dart
import 'package:flutter/material.dart';
import '../../UI/app_colors.dart';
import '../../UI/timed_button.dart';

class IntroPage extends StatelessWidget {
  final VoidCallback? onFinish;
  final bool preloadDone;
  final bool isLoading;
  final int preloadProgress;
  final int totalPreloadSteps;

  const IntroPage({
    super.key, 
    required this.onFinish,
    required this.isLoading, 
    required this.preloadDone, 
    required this.preloadProgress,
    required this.totalPreloadSteps,
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
              Center(
                child: Container(
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/rccg_logo.png',
                      height: 150,
                      width: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.church, size: 70, color: Colors.white),
                    ),
                  ),
                ),
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
                child: PreloadProgressButton(
                  context: context,
                  text: "Get Started",
                  preloadDone: preloadDone,
                  progress: preloadProgress,
                  totalSteps: totalPreloadSteps,
                  activeColor: AppColors.primary,
                  onPressed: onFinish, // your original function
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