import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _accent = Color(0xFF6C63FF);
  static const _surface = Color(0xFF12131A);
  static const _surfaceElevated = Color(0xFF181B24);
  static const _lightSurface = Color(0xFFF7F5EF);
  static const _lightSurfaceElevated = Color(0xFFFFFFFF);

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.dark,
      surface: _surface,
    ),
    scaffoldBackgroundColor: const Color(0xFF090A0F),
    cardColor: _surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0E1016),
      indicatorColor: _accent.withAlpha(51),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _surfaceElevated,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      behavior: SnackBarBehavior.floating,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.white12,
        disabledForegroundColor: Colors.white38,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withAlpha(30)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: Colors.white70,
        backgroundColor: Colors.white.withAlpha(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white.withAlpha(8),
      selectedColor: _accent.withAlpha(48),
      disabledColor: Colors.white10,
      side: BorderSide(color: Colors.white.withAlpha(18)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _accent,
      linearTrackColor: Color(0x22FFFFFF),
    ),
    dividerColor: Colors.white.withAlpha(10),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 14),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: _accent,
      selectionColor: Color(0x556C63FF),
      selectionHandleColor: _accent,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 30,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 24,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
      titleMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      bodyLarge: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
      bodyMedium: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
      bodySmall: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
      labelLarge: TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static final amoled = dark.copyWith(
    scaffoldBackgroundColor: Colors.black,
    cardColor: const Color(0xFF080808),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.black,
      indicatorColor: _accent.withAlpha(51),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.dark,
      surface: const Color(0xFF080808),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF0E0E0E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 14),
    ),
  );

  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.light,
      surface: _lightSurface,
    ),
    scaffoldBackgroundColor: const Color(0xFFFCFBF7),
    cardColor: _lightSurfaceElevated,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Color(0xFF11131A),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: Color(0xFF11131A)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFFF3F1EA),
      indicatorColor: _accent.withAlpha(28),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: Color(0xFF3B4050), fontSize: 12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _lightSurfaceElevated,
      contentTextStyle: const TextStyle(color: Color(0xFF11131A)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      behavior: SnackBarBehavior.floating,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.black12,
        disabledForegroundColor: Colors.black38,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF11131A),
        side: BorderSide(color: Colors.black.withAlpha(16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: const Color(0xFF3B4050),
        backgroundColor: Colors.black.withAlpha(6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.black.withAlpha(5),
      selectedColor: _accent.withAlpha(28),
      disabledColor: Colors.black12,
      side: BorderSide(color: Colors.black.withAlpha(10)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(color: Color(0xFF3B4050), fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _accent,
      linearTrackColor: Color(0x22000000),
    ),
    dividerColor: Colors.black.withAlpha(10),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _lightSurfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(
        color: Color(0xFF11131A),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: const TextStyle(color: Color(0xFF4E5465), fontSize: 14),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: _accent,
      selectionColor: Color(0x336C63FF),
      selectionHandleColor: _accent,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Color(0xFF11131A),
        fontWeight: FontWeight.w800,
        fontSize: 30,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        color: Color(0xFF11131A),
        fontWeight: FontWeight.w700,
        fontSize: 24,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        color: Color(0xFF11131A),
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
      titleMedium: TextStyle(
        color: Color(0xFF11131A),
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      bodyLarge: TextStyle(color: Color(0xFF2F3442), fontSize: 16, height: 1.6),
      bodyMedium: TextStyle(
        color: Color(0xFF4E5465),
        fontSize: 14,
        height: 1.5,
      ),
      bodySmall: TextStyle(color: Color(0xFF6F7584), fontSize: 12, height: 1.4),
      labelLarge: TextStyle(
        color: Color(0xFF11131A),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
