import 'package:flutter/material.dart';

/// Fresh DOJO WALK Admin design tokens.
///
/// Keep these presentation tokens separate from backend/API configuration.
abstract final class AdminTheme {
  static const Color brandOrange = Color(0xFFFF7900);
  static const Color pageBackground = Color(0xFFFFFAF5);
  static const Color primaryText = Color(0xFF252525);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFECE5DE);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandOrange,
      brightness: Brightness.light,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: brandOrange,
        onPrimary: Colors.white,
        surface: surface,
      ),
      scaffoldBackgroundColor: pageBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: pageBackground,
        foregroundColor: primaryText,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
      ),
    );
  }
}
