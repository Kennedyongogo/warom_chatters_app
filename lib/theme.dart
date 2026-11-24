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
  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: MtaaniColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: MtaaniColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: MtaaniColors.coral, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: MtaaniColors.blush,
      side: const BorderSide(color: MtaaniColors.line),
      labelStyle: const TextStyle(color: MtaaniColors.ink, fontWeight: FontWeight.w600, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MtaaniColors.coralDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(64, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, letterSpacing: -0.1),
        shape: pill,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MtaaniColors.coralDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: MtaaniColors.coral.withValues(alpha: 0.25),
        minimumSize: const Size(64, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        shape: pill,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MtaaniColors.coralDeep,
        side: const BorderSide(color: MtaaniColors.line),
        minimumSize: const Size(64, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        shape: pill,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MtaaniColors.coralDeep,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      contentTextStyle: const TextStyle(color: MtaaniColors.ink, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
