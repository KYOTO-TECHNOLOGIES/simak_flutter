import 'package:flutter/material.dart';

/// Centralized color constants matching the updated premium Simak Fresh brand.
/// Deep Teal · Gold · Cyan/Action Blue · White · Black
class AppColors {
  AppColors._();

  // ─── Primary (Brand Teal) ────────────────────────────────────
  static const Color primary = Color(0xFF003D4D);
  static const Color primaryDark = Color(0xFF002A35);
  static const Color primaryLight = Color(0xFF005668);

  // ─── Accent (Gold / Yellow) ─────────────────────────────────
  static const Color accent = Color(0xFFD4A843);
  static const Color accentLight = Color(0xFFE8C76B);
  static const Color accentDark = Color(0xFFB08C2E);

  // ─── Action (Vibrant Light Blue from Screenshot) ───────────────────
  static const Color actionBlue = Color(0xFF1297BA);
  static const Color actionBlueLight = Color(0xFFE1F5FE);

  // ─── Neutrals ───────────────────────────────────────────────
  static const Color black = Color(0xFF121212);
  static const Color darkGrey = Color(0xFF2C2C2C);
  static const Color midGrey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFF5F7F8);
  static const Color white = Color(0xFFFFFFFF);

  // ─── Compatibility / Gradients ───────────────────────────────
  static const Color lightBackground = Color(0xFFF5F7F8);
  static const Color lightReddishTop = Color(0xFFE0F7FA);

  static const List<Color> bgGradient = [
    Color(0xFF001A1F),
    Color(0xFF002A35),
    Color(0xFF001A1F),
  ];

  // ─── Status ─────────────────────────────────────────────────
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);
  static const Color error = Color(0xFFD32F2F);

  // ─── Themes ─────────────────────────────────────────────────


  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightGrey,
      primaryColor: primary,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: white,
        error: error,
        onPrimary: white,
        onSecondary: black,
        onSurface: Color(0xFF1A1A1A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightGrey,
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 0,
      ),
      cardColor: white,
      dividerColor: const Color(0xFFE0E0E0),
      shadowColor: Colors.black.withOpacity(0.05),
    );
  }
}
