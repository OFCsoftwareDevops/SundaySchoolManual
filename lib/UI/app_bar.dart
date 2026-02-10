import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../UI/app_colors.dart';
import '../utils/media_query.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final Color? actionColor;
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
    final resolvedActionColor =
        actionColor ?? theme.colorScheme.onSecondaryContainer;
    final style = CalendarDayStyle.fromContainer(context, 50);


    return AppBar(
      centerTitle: true,
      automaticallyImplyLeading: false,
       
      // ✅ BACK BUTTON (optional)
      leading: showBack
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            //color: resolvedActionColor,
            iconSize: style.monthFontSize.sp,
            onPressed: onBack ?? () => Navigator.pop(context),
          )
        : null,

      // ✅ TITLE (always provided by screen)
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          title,
          style: theme.appBarTheme.titleTextStyle?.copyWith(
          ),
        ),
      ),

      // ✅ ACTIONS (optional)
      //actions: actions,
      // ✅ FORCE color for ALL actions (icons + text)
      actions: actions == null
        ? null
        : [
            IconTheme(
              data: IconThemeData(color: resolvedActionColor,),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              ),
            ),
          ],
      bottom: bottom,
      elevation: 1,
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
    );
  }
}
