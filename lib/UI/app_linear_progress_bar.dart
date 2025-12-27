import 'package:flutter/material.dart';

class LinearProgressBar extends StatelessWidget {
  final double height;
  final Color backgroundColor;
  final Color valueColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;
  final String? message;
  
  final double value; // Optional message below the bar

  const LinearProgressBar({
    super.key,
    this.value = 0.0,
    this.height = 6.0,
    this.backgroundColor = const Color.fromARGB(255, 83, 15, 15),
    this.valueColor = const Color.fromARGB(255, 224, 8, 8), // Your app's green
    this.borderRadius,
    this.margin,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: height,
          margin: margin,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
          ),
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
            child: LinearProgressIndicator(
              value: value,
              valueColor: AlwaysStoppedAnimation<Color>(valueColor),
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/*class LinearProgressBar extends StatelessWidget {
  final double value; // Required: 0.0 to 1.0
  final double height;
  final Color backgroundColor;
  final Color valueColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;
  final String? message;
  final Duration duration; // Animation duration
  final Curve curve;       // Animation curve (e.g., easeOut)

  const LinearProgressBar({
    super.key,
    required this.value,
    this.height = 6.0,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.valueColor = const Color(0xFF5D8668),
    this.borderRadius,
    this.margin,
    this.message,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic, // Feels modern and smooth
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: height,
          margin: margin,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
          ),
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: duration,
              curve: curve,
              builder: (context, animatedValue, child) {
                return LinearProgressIndicator(
                  value: animatedValue,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(valueColor),
                );
              },
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

How to use;
LinearProgressBar(
  value: _preloadProgress / _totalPreloadSteps, // e.g., 1/3 → 0.333
  valueColor: Colors.deepPurple,
  message: "Loading resources...",
  duration: const Duration(milliseconds: 800),
  curve: Curves.easeOutCubic,
),


*/