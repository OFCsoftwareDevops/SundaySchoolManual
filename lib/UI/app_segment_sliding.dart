import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

class SegmentItem {
  final String label;
  final bool enabled;

  const SegmentItem(this.label, {this.enabled = true});
}

Widget segmentedControl({
  required int selectedIndex,
  required List<SegmentItem> items,
  required ValueChanged<int> onChanged,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final double padding_choice = 5.sp;
      final double outerPadding = padding_choice * 2; // left + right
      final double usableWidth = constraints.maxWidth - outerPadding;
      final double segmentWidth = ((usableWidth / items.length))/*.floorToDouble()*/;

      final backgroundColor = Theme.of(context).colorScheme.onPrimary;
      final indicatorColor = Theme.of(context).colorScheme.primaryContainer;

      return Container(
        height: 40.sp,
        padding: EdgeInsets.all(padding_choice),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30.sp),
        ),
        child: Stack(
          children: [
            // 🔹 Sliding indicator
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              left: segmentWidth * selectedIndex,
              top: 0,
              bottom: 0,
              width: segmentWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(26.sp),
                ),
              ),
            ),

            // 🔹 Segments
            SizedBox.expand(
              child: Row(
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final bool selected = i == selectedIndex;
              
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: item.enabled
                        ? () {
                          HapticFeedback.selectionClick();
                          onChanged(i);
                        }
                      : null,
                      child: Center(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !item.enabled
                              ? Colors.grey
                              : selected
                                ? Colors.white
                                : AppColors.secondary
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    },
  );
}
