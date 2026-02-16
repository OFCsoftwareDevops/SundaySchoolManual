import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/media_query.dart';
import 'app_sound.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final Color? actionColor; // ← keep if you want override, but usually not needed
  final PreferredSizeWidget? bottom;

  const AppAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions,
    this.onBack,
    this.actionColor,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Define the color once — used for back arrow, title, and all actions
    final iconAndTextColor = actionColor ??               // allow override if passed
        theme.appBarTheme.foregroundColor ??              // most reliable theme value
        theme.colorScheme.onPrimary;                      // fallback to onPrimary (common for dark text on primary bg)

    return AppBar(
      centerTitle: true,
      automaticallyImplyLeading: false,

      // Force foreground color for everything (icons + title text)
      foregroundColor: iconAndTextColor,

      // ✅ BACK BUTTON (optional)
      leading: showBack
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: iconAndTextColor, // ← explicit for safety
              ),
              iconSize: 24.sp, // or keep your style.monthFontSize.sp
              onPressed: onBack ?? () => Navigator.pop(context),
              enableFeedback: AppSounds.soundEnabled,
            )
          : null,

      // ✅ TITLE (always provided by screen)
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          title,
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            color: iconAndTextColor, // ← ensure title matches icons
          ),
        ),
      ),

      // ✅ ACTIONS (optional)
      // Wrap actions in IconTheme to force color on all icons inside
      actions: actions == null || actions!.isEmpty
          ? null
          : <Widget>[
              IconTheme(
                data: IconThemeData(
                  color: iconAndTextColor,     // ← this colors ALL icons in actions
                  size: 24.sp,                 // consistent size
                  opacity: 1.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
              ),
              SizedBox(width: 8.sp),
            ],

      bottom: bottom,
      elevation: 1,
      backgroundColor: theme.appBarTheme.backgroundColor,
    );
  }
}
