import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// PUBLIC API – use exactly like your old `build3DButton`
/// ---------------------------------------------------------------------------
Widget BibleBooksButtons({
  required BuildContext context,
  required String text,
  required VoidCallback onPressed,
  required Color topColor,
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),  // ← NEW: default white outline
  double borderWidth = 2.0,          // ← NEW: thickness of border
  double backOffset = 4.0,
  double backDarken = 0.45,
}) {
  final screenSize = MediaQuery.of(context).size;
  final double buttonWidth = screenSize.width * 0.75;
  final double buttonHeight = screenSize.height * 0.04;
  const double pressDepth = 4.0;

  return SizedBox(
    height: buttonHeight + backOffset,
    width: buttonWidth,
    child: AnimatedPress3D(
      onTap: onPressed,
      topColor: topColor,
      borderColor: borderColor,      // ← PASS THROUGH
      borderWidth: borderWidth,      // ← PASS THROUGH
      backOffset: backOffset,
      backDarken: backDarken,
      pressDepth: pressDepth,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    ),
  );
}

Widget BibleChaptersButtons({
  required BuildContext context,
  required String text,
  required VoidCallback onPressed,
  required Color topColor,
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),  // ← NEW: default white outline
  double borderWidth = 2.0,          // ← NEW: thickness of border
  double backOffset = 4.0,
  double backDarken = 0.45,
}) {
  const double pressDepth = 4.0;

  return LayoutBuilder(
    builder: (context, constraints) {
    final double buttonWidth = constraints.maxWidth;
    final double buttonHeight = constraints.maxHeight;

    // Choose the smaller of width/height as reference
    final double baseSize = buttonHeight;

    // Scale font size as a fraction of baseSize
    final double fontSize = baseSize * 0.3; // adjust 0.4 as needed

      return SizedBox(
        height: buttonHeight + backOffset,
        width: buttonWidth,
        child: AnimatedPress3D(
          onTap: onPressed,
          topColor: topColor,
          borderColor: borderColor,      // ← PASS THROUGH
          borderWidth: borderWidth,      // ← PASS THROUGH
          backOffset: backOffset,
          backDarken: backDarken,
          pressDepth: pressDepth,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      );
    }
  );
}

Widget AssignmentWidgetButton({
  required BuildContext context,
  required String text,
  required VoidCallback? onPressed,
  required Color topColor,
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),  // ← NEW: default white outline
  double borderWidth = 2.0,          // ← NEW: thickness of border
  double backOffset = 4.0,
  double backDarken = 0.45, required Icon icon,
}) {
  final screenSize = MediaQuery.of(context).size;
  final double buttonWidth = screenSize.width * 0.8;
  final double buttonHeight = screenSize.height * 0.05;
  const double pressDepth = 4.0;

  return SizedBox(
    height: buttonHeight + backOffset,
    width: buttonWidth,
    child: AnimatedPress3D(
      onTap: onPressed,
      topColor: topColor,
      borderColor: borderColor,      // ← PASS THROUGH
      borderWidth: borderWidth,      // ← PASS THROUGH
      backOffset: backOffset,
      backDarken: backDarken,
      pressDepth: pressDepth,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    ),
  );
}

Widget HomePageButtons({
  required BuildContext context,
  required String text,
  VoidCallback? onPressed,
  required Color topColor,
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),  // ← NEW: default white outline
  double borderWidth = 2.0,          // ← NEW: thickness of border
  double backOffset = 4.0,
  double backDarken = 0.45,
}) {
  final screenSize = MediaQuery.of(context).size;
  final double buttonWidth = screenSize.width * 0.8;
  final double buttonHeight = screenSize.height * 0.05;
  const double pressDepth = 4.0;

  return SizedBox(
    height: buttonHeight + backOffset,
    width: buttonWidth,
    child: AnimatedPress3D(
      onTap: onPressed,
      topColor: topColor,
      borderColor: borderColor,      // ← PASS THROUGH
      borderWidth: borderWidth,      // ← PASS THROUGH
      backOffset: backOffset,
      backDarken: backDarken,
      pressDepth: pressDepth,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    ),
  );
}

Widget LessonCardButtons({
  required BuildContext context,
  required VoidCallback onPressed,
  required Color topColor,
  required String text,                    // still supported
  Widget? child,                           // ← NEW
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),
  double borderWidth = 2.0,
  double backOffset = 4.0,
  double backDarken = 0.45,
}) {
  final screenSize = MediaQuery.of(context).size;
  final double buttonWidth = screenSize.width * 0.8;
  final double buttonHeight = screenSize.height * 0.05;
  const double pressDepth = 4.0;

  return SizedBox(
    height: buttonHeight + backOffset,
    width: buttonWidth,
    child: AnimatedPress3D(
      onTap: onPressed,
      topColor: topColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      backOffset: backOffset,
      backDarken: backDarken,
      pressDepth: pressDepth,
      child: Center(
        child: child ??
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
      ),
    ),
  );
}

Widget furtherReadingButtons({
  required BuildContext context,
  required VoidCallback onPressed,
  required Color topColor,
  required String text,                    // still supported
  Widget? child,                           // ← NEW
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),
  double borderWidth = 2.0,
  double backOffset = 4.0,
  double backDarken = 0.45,
}) {
  final screenSize = MediaQuery.of(context).size;
  final double buttonHeight = screenSize.height * 0.06;
  const double pressDepth = 4.0;

  return LayoutBuilder(
    builder: (context, constraints) {
      final double buttonWidth = constraints.maxWidth;
      return SizedBox(
        height: buttonHeight + backOffset,
        width: buttonWidth,
        child: AnimatedPress3D(
          onTap: onPressed,
          topColor: topColor,
          borderColor: borderColor,
          borderWidth: borderWidth,
          backOffset: backOffset,
          backDarken: backDarken,
          pressDepth: pressDepth,
          child: Center(
            child: child ??
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
          ),
        ),
      );
    }
  );
}

Widget PressInButtons({
  required BuildContext context,
  required VoidCallback onPressed,
  required Color topColor,
  required Widget child, // ← NEW
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),
  double borderWidth = 2.0,
  double backOffset = 3.0,
  double backDarken = 0.45,
}) {
  final screenSize = MediaQuery.of(context).size;
  final double buttonWidth = screenSize.width * 0.40;
  final double buttonHeight = screenSize.height * 0.08;
  const double pressDepth = 4.0;

  return SizedBox(
    height: buttonHeight + backOffset,
    width: buttonWidth,
    child: AnimatedPress3D(
      onTap: onPressed,
      topColor: topColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      backOffset: backOffset,
      backDarken: backDarken,
      pressDepth: pressDepth,
      child: child,
    ),
  );
}

Widget LoginButtons({
  required BuildContext context,
  required VoidCallback onPressed,
  required Color topColor,
  required String text,                    // still supported
  Widget? child,                           // ← NEW
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),
  double borderWidth = 2.0,
  double backOffset = 4.0,
  double backDarken = 0.5,
}) {
  final screenSize = MediaQuery.of(context).size;
  final double buttonWidth = screenSize.width * 0.8;
  final double buttonHeight = screenSize.height * 0.05;
  const double pressDepth = 4.0;

  return SizedBox(
    height: buttonHeight + backOffset,
    width: buttonWidth,
    child: AnimatedPress3D(
      onTap: onPressed,
      topColor: topColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      backOffset: backOffset,
      backDarken: backDarken,
      pressDepth: pressDepth,
      child: Center(
        child: child ??
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
      ),
    ),
  );
}



Widget FeedbackPageButton({
  required BuildContext context,
  required String text,
  required VoidCallback onPressed,
  required Color topColor,
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),  // ← NEW: default white outline
  double borderWidth = 2.0,          // ← NEW: thickness of border
  double backOffset = 4.0,
  double backDarken = 0.45,
}) {
  final screenSize = MediaQuery.of(context).size;
  final double buttonWidth = screenSize.width * 0.8;
  final double buttonHeight = screenSize.height * 0.04;
  const double pressDepth = 4.0;

  return SizedBox(
    height: buttonHeight + backOffset,
    width: buttonWidth,
    child: AnimatedPress3D(
      onTap: onPressed,
      topColor: topColor,
      borderColor: borderColor,      // ← PASS THROUGH
      borderWidth: borderWidth,      // ← PASS THROUGH
      backOffset: backOffset,
      backDarken: backDarken,
      pressDepth: pressDepth,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    ),
  );
}


/// ---------------------------------------------------------------------------
/// INTERNAL – animation + static back-plate
/// ---------------------------------------------------------------------------
class AnimatedPress3D extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color topColor;
  final Color borderColor;       // ← NEW
  final double borderWidth;      // ← NEW
  final double backOffset;
  final double backDarken;
  final double pressDepth;

  const AnimatedPress3D({
    required this.child,
    required this.onTap,
    required this.topColor,
    required this.borderColor,
    required this.borderWidth,
    required this.backOffset,
    required this.backDarken,
    required this.pressDepth,
    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedPress3D> createState() => _AnimatedPress3DState();
}

class _AnimatedPress3DState extends State<AnimatedPress3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _offset; // vertical press animation

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _offset = Tween<double>(begin: 0, end: widget.pressDepth).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color backColor = Color.lerp(widget.topColor, Colors.black, widget.backDarken)!;
    const double radius = 12.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _ctrl.forward(),
      //onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      //onTap: widget.onTap,
      onTapUp: (_) async {
        await _ctrl.forward();
        await _ctrl.reverse();
        widget.onTap?.call();       // ← Navigation happens AFTER animation
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // 1. DARK BACK-PLATE with optional border
              Transform.translate(
                offset: Offset(0, widget.backOffset),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: backColor,
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(                   // ← Optional: border on back
                      color: widget.borderColor.withOpacity(0.3),
                      width: widget.borderWidth,
                    ),
                  ),
                ),
              ),

              // 2. MAIN BUTTON – moves down + has clear border
              Transform.translate(
                offset: Offset(0, _offset.value),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: widget.topColor,
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(                  // ← MAIN BORDER
                      color: widget.borderColor,
                      width: widget.borderWidth,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: widget.child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}