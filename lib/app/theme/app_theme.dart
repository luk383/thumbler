import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _accent = Color(0xFF6C63FF);

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.dark,
      surface: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.black,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0D0D0D),
      indicatorColor: _accent.withAlpha(51),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 28,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 22,
        height: 1.4,
      ),
      bodyLarge: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
      bodyMedium: TextStyle(color: Colors.white60, fontSize: 14),
      labelLarge: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
