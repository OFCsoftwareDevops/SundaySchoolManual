// lib/widgets/profile/color_palette_page.dart

import 'package:flutter/material.dart';
import '../../UI/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'snackbar.dart';

class ColorPalettePage extends StatelessWidget {
  const ColorPalettePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Color Palette"),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              "App Color Palette",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Primary Colors
            _colorSection(
              title: "Primary Colors",
              colors: [
                _ColorTile(name: "Primary", color: AppColors.primary),
                _ColorTile(name: "Primary Container", color: AppColors.primaryContainer),
                _ColorTile(name: "On Primary", color: AppColors.onPrimary),
              ],
            ),
            const SizedBox(height: 24),

            // Secondary Colors
            _colorSection(
              title: "Secondary Colors",
              colors: [
                _ColorTile(name: "Secondary", color: AppColors.secondary),
                _ColorTile(name: "Secondary Container", color: AppColors.secondaryContainer),
                _ColorTile(name: "On Secondary", color: AppColors.onSecondary),
                _ColorTile(name: "Divine Accent", color: AppColors.divineAccent),
                _ColorTile(name: "Scripture Highlight", color: AppColors.scriptureHighlight),
              ],
            ),
            const SizedBox(height: 24),

            // Neutral / Background
            _colorSection(
              title: "Neutral & Background",
              colors: [
                _ColorTile(name: "Background", color: AppColors.background),
                _ColorTile(name: "Surface", color: AppColors.surface),
                _ColorTile(name: "On Background", color: AppColors.onBackground),
                _ColorTile(name: "On Surface", color: AppColors.onSurface),
              ],
            ),
            const SizedBox(height: 24),

            // Status Colors
            _colorSection(
              title: "Status Colors",
              colors: [
                _ColorTile(name: "Error", color: AppColors.error),
                _ColorTile(name: "On Error", color: AppColors.onError),
                _ColorTile(name: "Success", color: AppColors.success),
                _ColorTile(name: "Warning", color: AppColors.warning),
              ],
            ),
            const SizedBox(height: 24),

            // Grey Scale
            _colorSection(
              title: "Grey Scale",
              colors: [
                _ColorTile(name: "Grey 50", color: AppColors.grey50),
                _ColorTile(name: "Grey 100", color: AppColors.grey100),
                _ColorTile(name: "Grey 200", color: AppColors.grey200),
                _ColorTile(name: "Grey 300", color: AppColors.grey300),
                _ColorTile(name: "Grey 400", color: AppColors.grey400),
                _ColorTile(name: "Grey 500", color: AppColors.grey500),
                _ColorTile(name: "Grey 600", color: AppColors.grey600),
                _ColorTile(name: "Grey 700", color: AppColors.grey700),
                _ColorTile(name: "Grey 800", color: AppColors.grey800),
                _ColorTile(name: "Grey 900", color: AppColors.grey900),
              ],
            ),
            const SizedBox(height: 24),

            // Dark Theme
            _colorSection(
              title: "Dark Theme",
              colors: [
                _ColorTile(name: "Dark Background", color: AppColors.darkBackground),
                _ColorTile(name: "Dark Surface", color: AppColors.darkSurface),
                _ColorTile(name: "Dark On Background", color: AppColors.darkOnBackground),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _colorSection({
    required String title,
    required List<_ColorTile> colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors
              .map((tile) => _ColorBox(name: tile.name, color: tile.color))
              .toList(),
        ),
      ],
    );
  }
}

class _ColorTile {
  final String name;
  final Color color;

  _ColorTile({required this.name, required this.color});
}

class _ColorBox extends StatelessWidget {
  final String name;
  final Color color;

  const _ColorBox({
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if text should be white or black based on luminance
    final textColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Material(
      child: InkWell(
        onTap: () {
          // Show snackbar with hex code
          final hex = '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
          showTopToast(
            context,
            'Copied: $hex',
            duration: const Duration(seconds: 3),
          );
        },
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
