import 'package:flutter/material.dart';

/// Centralized color palette for the app — a calm, trustworthy
/// healthcare-inspired teal & indigo scheme with soft accents.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0EA5A0); // teal
  static const Color primaryDark = Color(0xFF0B7F7B);
  static const Color primaryLight = Color(0xFF6FE0DB);
  static const Color secondary = Color(0xFF6C63FF); // indigo/violet accent
  static const Color secondaryLight = Color(0xFFB4AFFF);

  // Status
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFE74C3C);
  static const Color info = Color(0xFF4A90D9);

  // Neutrals — Light theme
  static const Color backgroundLight = Color(0xFFF6F8FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1B2430);
  static const Color textSecondaryLight = Color(0xFF6B7684);
  static const Color borderLight = Color(0xFFE7ECF1);

  // Neutrals — Dark theme
  static const Color backgroundDark = Color(0xFF0F1417);
  static const Color surfaceDark = Color(0xFF1A2126);
  static const Color textPrimaryDark = Color(0xFFF1F5F7);
  static const Color textSecondaryDark = Color(0xFF9BA7B0);
  static const Color borderDark = Color(0xFF2A343B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0EA5A0), Color(0xFF6C63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunriseGradient = LinearGradient(
    colors: [Color(0xFFFFA751), Color(0xFFFFE259)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient calmGradient = LinearGradient(
    colors: [Color(0xFF6FE0DB), Color(0xFF0EA5A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Adherence chart colors
  static const List<Color> chartColors = [
    Color(0xFF0EA5A0),
    Color(0xFF6C63FF),
    Color(0xFFF5A623),
    Color(0xFFE74C3C),
  ];
}
