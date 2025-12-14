import 'dart:async';
import 'package:flutter/material.dart';
import 'buttons.dart';

Widget TimedFeedbackButton({
  required BuildContext context,
  required String text,
  required VoidCallback onPressed,
  required Color topColor,
  int seconds = 10, // time to wait before enabling
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),
  double borderWidth = 2.0,
  double backOffset = 4.0,
  double backDarken = 0.45,
}) {
  return TimedFeedbackButtonStateful(
    text: text,
    topColor: topColor,
    onPressed: onPressed,
    seconds: seconds,
    borderColor: borderColor,
    borderWidth: borderWidth,
    backOffset: backOffset,
    backDarken: backDarken,
  );
}

class TimedFeedbackButtonStateful extends StatefulWidget {
  final String text;
  final Color topColor;
  final VoidCallback onPressed;
  final int seconds;
  final Color borderColor;
  final double borderWidth;
  final double backOffset;
  final double backDarken;

  const TimedFeedbackButtonStateful({
    required this.text,
    required this.topColor,
    required this.onPressed,
    required this.seconds,
    required this.borderColor,
    required this.borderWidth,
    required this.backOffset,
    required this.backDarken,
  });

  @override
  State<TimedFeedbackButtonStateful> createState() =>
      _TimedFeedbackButtonStatefulState();
}

class _TimedFeedbackButtonStatefulState extends State<TimedFeedbackButtonStateful> {
  late int _remainingSeconds;
  late Timer _timer;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();

    _remainingSeconds = widget.seconds;
    _enabled = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _enabled = true;
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  double get _progress => 1 - (_remainingSeconds / widget.seconds);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double buttonWidth = screenSize.width * 0.8;
    final double buttonHeight = screenSize.height * 0.04;
    const double pressDepth = 4.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: buttonHeight + widget.backOffset,
          width: buttonWidth,
          child: AnimatedPress3D(
            onTap: _enabled ? widget.onPressed : () {},
            topColor: _enabled ? widget.topColor : Colors.grey, // grey if disabled
            borderColor: _enabled ? widget.borderColor : Colors.grey,
            borderWidth: widget.borderWidth,
            backOffset: widget.backOffset,
            backDarken: _enabled ? widget.backDarken : 0.4,
            pressDepth: pressDepth,
            child: Center(
              child: Text(
                _enabled
                    ? widget.text
                    : "${widget.text} ($_remainingSeconds s)", // optional countdown text
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: _progress,
          minHeight: 5,
          backgroundColor: Colors.grey.shade300,
          color: widget.topColor,
        ),
      ],
    );
  }
}



Widget PreloadProgressButton({
  required BuildContext context,
  required String text,
  required bool preloadDone,
  required int progress,        // 0 to 3
  required int totalSteps,     // 3
  required Color activeColor,  // e.g., Colors.deepPurple
  required VoidCallback? onPressed,
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),
  double borderWidth = 2.0,
  double backOffset = 4.0,
  double backDarken = 0.45,
}) {
  final bool isLoading = progress < totalSteps;
  final double progressValue = totalSteps == 0 ? 1.0 : progress / totalSteps;

  final screenSize = MediaQuery.of(context).size;
  final double buttonWidth = screenSize.width * 0.8;
  final double buttonHeight = screenSize.height * 0.05;
  const double pressDepth = 4.0;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: buttonHeight + backOffset,
        width: buttonWidth,
        child: AnimatedPress3D(
          onTap: preloadDone ? onPressed : null,
          topColor: preloadDone
              ? activeColor
              : const Color.fromARGB(255, 57, 56, 58), // your inactive grey
          borderColor: borderColor,
          borderWidth: borderWidth,
          backOffset: backOffset,
          backDarken: backDarken,
          pressDepth: pressDepth,
          child: Center(
            child: Text(
              preloadDone
                  ? text
                  : "Preparing... ($progress/$totalSteps)",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 6),
      if (isLoading) // Only show progress bar while loading
        LinearProgressIndicator(
          value: progressValue,
          minHeight: 5,
          backgroundColor: Colors.grey.shade300,
          color: activeColor,
        ),
    ],
  );
}
