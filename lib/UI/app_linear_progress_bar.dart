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