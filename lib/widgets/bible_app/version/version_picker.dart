import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bible.dart';

class VersionPicker extends StatelessWidget {
  final Color iconColor;
  final Color textColor;
  final bool compact;
  final double textSize;

  const VersionPicker({
    super.key,
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
    this.compact = true,
    this.textSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BibleVersionManager>(
      builder: (context, manager, child) {
        return manager.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : DropdownButton<String>(
                value: manager.currentVersion,
                dropdownColor: const Color(0xFF5D8668),
                icon: Icon(Icons.keyboard_arrow_down, color: iconColor),
                underline: const SizedBox(),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: textSize,
                ),
                items: manager.availableVersions
                    .map((v) => DropdownMenuItem(
                          value: v['code'],
                          child: Text(v['name']!),
                        ))
                    .toList(),
                onChanged: (v) => v != null ? manager.changeVersion(v) : null,
              );
      },
    );
  }
}
