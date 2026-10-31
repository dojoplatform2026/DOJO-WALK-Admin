import 'package:flutter/material.dart';

class DojoWalkAdminTheme {
  static const Color brandOrange = Color(0xFFFF7900);
  static const Color warmBackground = Color(0xFFFFFAF5);
  static const Color primaryText = Color(0xFF252525);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandOrange,
      brightness: Brightness.light,
    ).copyWith(
      primary: brandOrange,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: primaryText,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: warmBackground,
      colorScheme: scheme,
      fontFamily: 'Arial',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: primaryText,
        surfaceTintColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFF0E8E0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE7DED5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE7DED5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandOrange, width: 1.5),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
