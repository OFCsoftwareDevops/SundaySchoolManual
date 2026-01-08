import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_buttons.dart';
import 'app_colors.dart';

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
          width: buttonWidth.sp,
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 10.sp),
        LinearProgressIndicator(
          value: _progress,
          minHeight: 5.sp,
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
  bool? preloadDone,
  int? progress,        // 0 to 3
  int? totalSteps,     // 3
  required Color activeColor,  // e.g., Colors.deepPurple
  VoidCallback? onPressed,
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),
  double borderWidth = 0.0,
  double backOffset = 4.0,
  double backDarken = 0.45,
}) {
  // Safely determine states
  final bool hasProgressInfo = progress != null && totalSteps != null && totalSteps > 0;
  final bool isLoading = hasProgressInfo ? progress! < totalSteps! : preloadDone == false;
  final bool isReady = preloadDone == true;
  final bool isEnabled = isReady && onPressed != null;

  // Safe progress value (0.0 to 1.0)
  final double progressValue = hasProgressInfo
      ? (progress! / totalSteps!)
      : (preloadDone == true ? 1.0 : 0.0);

  // Display text
  final String displayText = isReady
      ? text
      : hasProgressInfo
          ? "Preparing... ($progress/$totalSteps)"
          : "Preparing...";

  final screenSize = MediaQuery.of(context).size;
  final double buttonWidth = screenSize.width * 0.8;
  final double buttonHeight = screenSize.height * 0.05;
  const double pressDepth = 4.0;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: buttonHeight + backOffset,
        width: buttonWidth.sp,
        child: AnimatedPress3D(
          onTap: isEnabled ? onPressed : null,
          topColor: isReady ? activeColor : AppColors.grey600,
          borderColor: borderColor,
          borderWidth: borderWidth,
          backOffset: backOffset,
          backDarken: backDarken,
          pressDepth: pressDepth,
          child: Center(
            child: Text(
              displayText,
              style: TextStyle(
                color: isReady
                    ? Theme.of(context).colorScheme.surface
                    : AppColors.onPrimary.withOpacity(0.7),
                fontSize: 18.sp * 0.8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2.sp,
              ),
            ),
          ),
        ),
      ),
      SizedBox(height: 10.sp),
      if (isLoading) // Only show progress bar while loading
        LinearProgressIndicator(
          value: hasProgressInfo ? progressValue : null,
          minHeight: 5.sp,
          backgroundColor: Colors.grey.shade300,
          color: AppColors.success,
        ),
    ],
  );
}
