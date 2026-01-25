import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showTopToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
  Color? backgroundColor,
  Color? textColor,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;

  // Use theme color as fallback if no custom color is provided
  final effectiveBgColor = backgroundColor ?? Theme.of(context).colorScheme.onSurface;
  final effectiveTextColor = textColor ?? Theme.of(context).colorScheme.surface;

  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 10.sp,
      left: 5.sp,
      right: 5.sp,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 16.sp),
          decoration: BoxDecoration(
            color: effectiveBgColor,
            borderRadius: BorderRadius.circular(5.sp),
            boxShadow: [
              BoxShadow(
                blurRadius: 5.sp,
                color: Colors.black26,
              )
            ],
          ),
          child: Center(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 15.sp,
                color: effectiveTextColor,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  Future.delayed(duration, () {
    entry.remove();
  });
}
