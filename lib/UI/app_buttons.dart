
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rccg_sunday_school/utils/device_check.dart';
import 'app_colors.dart';

/// ---------------------------------------------------------------------------
/// PUBLIC API – use exactly like your old `build3DButton`
/// ---------------------------------------------------------------------------

Widget BibleBooksButtons({
  required BuildContext context,
  required String text,
  required VoidCallback onPressed,
  required Color topColor,
  required Color textColor,
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),  // ← NEW: default white outline
  double borderWidth = 0.0,          // ← NEW: thickness of border
  double backOffset = 4.0,
  double backDarken = 0.45,
}) {
  const double pressDepth = 4.0;

  return LayoutBuilder(
    builder: (context, constraints) {

      return AnimatedPress3D(
        onTap: onPressed,
        topColor: topColor,
        borderColor: borderColor,
        borderWidth: borderWidth,
        backOffset: backOffset,
        backDarken: backDarken,
        pressDepth: pressDepth,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis, // for long names like "Song of Solomon"
            maxLines: 2, // allow wrap if needed on very small screens
          ),
        ),
      );
    },
  );
}

Widget BibleChaptersButtons({
  required BuildContext context,
  required String text,
  required VoidCallback onPressed,
  required Color topColor,
  required Color textColor,
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),
  double borderWidth = 0.0,
  double backOffset = 4.0,
  double backDarken = 0.45,
}) {
  const double pressDepth = 4.0;

  return LayoutBuilder(
    builder: (context, constraints) {

      return AnimatedPress3D(
        onTap: onPressed,
        topColor: topColor,
        borderColor: borderColor,
        borderWidth: borderWidth,
        backOffset: backOffset,
        backDarken: backDarken,
        pressDepth: pressDepth,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    },
  );
}

Widget AssignmentWidgetButton({
  required BuildContext context,
  required String text,
  required VoidCallback? onPressed,
  required Color topColor,
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),  // ← NEW: default white outline
  double borderWidth = 0.0,          // ← NEW: thickness of border
  double backOffset = 4.0,
  double backDarken = 0.45, required Icon icon,
}) {
  final scale = context.tabletScaleFactor;
  final screenSize = MediaQuery.of(context).size;

  final double buttonWidth = screenSize.width.sp * 0.8;
  final double buttonHeight = screenSize.height.sp * 0.05 * scale;
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
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp * 0.9,
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
  required String label,
  required bool available,
  IconData? leadingIcon,     // optional leading icon
  IconData? trailingIcon,    // optional trailing (arrow/lock)
  Color topColor = Colors.transparent,
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),
  double borderWidth = 0.0,
  double backOffset = 4.0,
  double backDarken = 0.45,
}) {
  final scale = context.tabletScaleFactor;
  final screenSize = MediaQuery.of(context).size;

  final double buttonHeight = screenSize.height * 0.05 * scale;
  const double pressDepth = 4.0;

  final Color effectiveTopColor = available ? AppColors.primaryContainer : AppColors.grey800;
  final Color textColor = available ? AppColors.onPrimary : AppColors.onSecondary;
  final Color iconColor = textColor;

  return LayoutBuilder(
    builder: (context, constraints) {
      final double totalHeight = buttonHeight + backOffset;

      return SizedBox(
        height: totalHeight,
        width: constraints.maxWidth,
        child: AnimatedPress3D(
          onTap: onPressed,
          topColor: effectiveTopColor,
          borderColor: borderColor,
          borderWidth: borderWidth,
          backOffset: backOffset,
          backDarken: backDarken,
          pressDepth: pressDepth,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(                                           // ← this gives bounded width to everything inside
                  child: Row(
                    mainAxisSize: MainAxisSize.min,                 // ← important: don't take all space
                    children: [
                      if (leadingIcon != null)
                        Padding(
                          padding: EdgeInsets.only(right: 12.sp),
                          child: Icon(
                            leadingIcon,
                            size: totalHeight * 0.5,
                            color: iconColor,
                          ),
                        ),

                      Flexible(                                     // ← second Flexible for the Text itself
                        child: Text(
                          label,
                          softWrap: true,
                          overflow: TextOverflow.visible,           // or .ellipsis if you prefer
                          maxLines: 3,                              // ← increase if you want more lines allowed
                          style: TextStyle(
                            color: textColor,
                            fontSize: totalHeight * 0.25,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            height: 1.2.sp,                           // ← makes multi-line look better
                            fontStyle: available ? FontStyle.normal : FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  trailingIcon ?? (available ? Icons.arrow_forward_ios_rounded : Icons.lock_outline),
                  size: totalHeight * 0.4,
                  color: iconColor,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget furtherReadingButtons({
  required BuildContext context,
  required VoidCallback onPressed,
  required String label,
  required bool available,
  IconData? leadingIcon,     // optional leading icon
  IconData? trailingIcon,    // optional trailing (arrow/lock)
  Color topColor = Colors.transparent,
  Color borderColor = const Color.fromARGB(0, 118, 118, 118),
  double borderWidth = 0.0,
  double backOffset = 4.0,
  double backDarken = 0.45,
}) {
  final scale = context.tabletScaleFactor;
  final screenSize = MediaQuery.of(context).size;

  final double buttonHeight = screenSize.height * 0.05 * scale;
  const double pressDepth = 4.0;

  final Color effectiveTopColor = available ? AppColors.primaryContainer : AppColors.grey800;
  final Color textColor = available ? AppColors.onPrimary : AppColors.onSecondary;
  final Color iconColor = textColor;

  return LayoutBuilder(
    builder: (context, constraints) {
      final double totalHeight = buttonHeight + backOffset;

      return SizedBox(
        height: totalHeight,
        width: constraints.maxWidth,
        child: AnimatedPress3D(
          onTap: onPressed,
          topColor: effectiveTopColor,
          borderColor: borderColor,
          borderWidth: borderWidth,
          backOffset: backOffset,
          backDarken: backDarken,
          pressDepth: pressDepth,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (leadingIcon != null)
                      Icon(
                        leadingIcon,
                        size: totalHeight * 0.5,
                        color: iconColor,
                      ),
                    if (leadingIcon != null) SizedBox(width: 12.sp),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          available? "Today's Reading" : "No Reading",
                          style: TextStyle(     // ~32% of button height
                            fontWeight: FontWeight.w700,
                            fontSize: totalHeight * 0.25,
                            color: available ? AppColors.onPrimary : AppColors.onSecondary,
                          ),
                        ),
                        Text(
                          label,
                          style: TextStyle(
                            color: textColor,
                            fontSize: totalHeight * 0.2,
                            fontStyle: available ? FontStyle.normal : FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(
                  trailingIcon ?? (available ? Icons.arrow_forward_ios_rounded : Icons.lock_outline),
                  size: totalHeight * 0.4,
                  color: iconColor,
                ),
              ],
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
  required String text,
  required IconData icon,
  required Color topColor,
  required Color textColor,
  //required Widget child, // ← NEW
  Color borderColor = Colors.transparent,
  double borderWidth = 0.0,
  double backOffset = 3.0,
  double backDarken = 0.45,
}) {
  final scale = context.tabletScaleFactor;
  final screenSize = MediaQuery.of(context).size;

  final double buttonWidth = screenSize.width * 0.35;
  final double buttonHeight = screenSize.height * 0.08 * scale;
  const double pressDepth = 3.0;

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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.sp), // comfortable text padding
        child: Row(
          children: [
            Icon(icon, 
              color: textColor, 
              size: 18.sp,
            ),
            SizedBox(width: 20.sp),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // for long names like "Song of Solomon"
              maxLines: 2, // allow wrap if needed on very small screens
            ),
          ],
        ),
      ),
    ),
  );
}

Widget GradeButtons({
  required BuildContext context,
  required VoidCallback? onPressed,
  required String text,
  required IconData icon,
  required Color topColor,
  required Color textColor,
  //required Widget child, // ← NEW
  Color borderColor = Colors.transparent,
  double borderWidth = 0.0,
  double backOffset = 3.0,
  double backDarken = 0.45,
}) {
  final screenSize = MediaQuery.of(context).size;

  final double buttonWidth = screenSize.width * 0.35;
  final double buttonHeight = 40.sp;
  const double pressDepth = 3.0;

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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.sp), // comfortable text padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(icon, 
              color: textColor, 
              size: 18.sp,
            ),
            //SizedBox(width: 10.sp),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // for long names like "Song of Solomon"
              maxLines: 2, // allow wrap if needed on very small screens
            ),
          ],
        ),
      ),
    ),
  );
}

Widget ChurchChoiceButtons({
  required BuildContext context,
  required VoidCallback? onPressed,
  required String text,
  required IconData icon,
  required Color topColor,
  required Color textColor,
  //required Widget child, // ← NEW
  Color borderColor = Colors.transparent,
  double borderWidth = 0.0,
  double backOffset = 3.0,
  double backDarken = 0.45,
}) {
  final screenSize = MediaQuery.of(context).size;

  final double buttonWidth = screenSize.width * 0.25;
  final double buttonHeight = 40.sp;
  const double pressDepth = 3.0;

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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.sp), // comfortable text padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(icon, 
              color: textColor, 
              size: 18.sp,
            ),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // for long names like "Song of Solomon"
              maxLines: 2, // allow wrap if needed on very small screens
            ),
          ],
        ),
      ),
    ),
  );
}

Widget LoginButtons({
  required BuildContext context,
  required VoidCallback? onPressed,
  required Color topColor,
  required String text,                    // still supported
  Widget? child,                           // ← NEW
  Color borderColor = Colors.transparent,
  double borderWidth = 0.0,
  double backOffset = 4.0,
  double backDarken = 0.45,
}) {
  final scale = context.tabletScaleFactor;
  final screenSize = MediaQuery.of(context).size;

  final double buttonWidth = screenSize.width * 0.8;
  final double buttonHeight = screenSize.height * 0.05 * scale;
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
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
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
    double radius = 8.sp;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use full available size (square from GridView)
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          //behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _ctrl.forward(),
          onTapCancel: () => _ctrl.reverse(),
          onTapUp: (_) async {
            await _ctrl.forward();
            await _ctrl.reverse();
            widget.onTap?.call();       // ← Navigation happens AFTER animation
          },
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: OverflowBox(
              maxHeight: size.height + widget.backOffset + widget.pressDepth, // Allow shadow to draw below
              alignment: Alignment.topCenter,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // 1. DARK BACK-PLATE with optional border
                      Transform.translate(
                        offset: Offset(0, widget.backOffset),
                        child: Container(
                          height: size.height,
                          width: size.width,
                          //padding: EdgeInsets.symmetric(horizontal: 5.sp),
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
                          width: size.width,
                          height: size.height,
                          //padding: EdgeInsets.symmetric(horizontal: 5.sp),
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
            ),
          ),
        );
      }
    );
  }
}