import 'package:flutter/material.dart';

abstract final class MtaaniColors {
  static const coral = Color(0xFFFF5A64);
  static const coralDeep = Color(0xFFEF3F55);
  static const blush = Color(0xFFFFE9E6);
  static const cream = Color(0xFFF2E1D6);
  static const canvas = Color(0xFFFFF8F5);
  static const ink = Color(0xFF26222A);
  static const muted = Color(0xFF7A707A);
  static const line = Color(0xFFF0E1DC);
  static const night = Color(0xFF130E12);
  static const like = Color(0xFF2BC48A);
  static const gold = Color(0xFFF5B83D);

  static const brandGradient = LinearGradient(colors: [coral, coralDeep]);
}

ThemeData buildMtaaniTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: MtaaniColors.coral,
    primary: MtaaniColors.coralDeep,
    surface: Colors.white,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: MtaaniColors.canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: MtaaniColors.canvas,
      foregroundColor: MtaaniColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: MtaaniColors.ink, fontSize: 20, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MtaaniColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MtaaniColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MtaaniColors.coral, width: 1.6),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: MtaaniColors.blush,
      side: const BorderSide(color: MtaaniColors.line),
      labelStyle: const TextStyle(color: MtaaniColors.ink, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
