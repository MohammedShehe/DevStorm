import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';

class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility Options')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Text Size', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  'Preview: Take medicine on time',
                  style: TextStyle(fontSize: 14 * themeProvider.textScale),
                ),
                Slider(
                  value: themeProvider.textScale,
                  min: 0.85,
                  max: 1.4,
                  divisions: 5,
                  activeColor: AppColors.primary,
                  label: '${(themeProvider.textScale * 100).round()}%',
                  onChanged: (v) => context.read<ThemeProvider>().setTextScale(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.contrast_rounded, color: AppColors.primary),
                  title: const Text('High Contrast Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Improve visibility with bolder contrast'),
                  value: themeProvider.highContrast,
                  activeColor: AppColors.primary,
                  onChanged: (v) => context.read<ThemeProvider>().setHighContrast(v),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                  title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                  value: themeProvider.isDarkMode,
                  activeColor: AppColors.primary,
                  onChanged: (v) => context.read<ThemeProvider>().toggleDarkMode(v),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                SwitchListTile(
                  secondary: const Icon(Icons.record_voice_over_outlined, color: AppColors.primary),
                  title: const Text('Voice Announcements', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Speak reminder details aloud'),
                  value: false,
                  activeColor: AppColors.primary,
                  onChanged: (v) {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
