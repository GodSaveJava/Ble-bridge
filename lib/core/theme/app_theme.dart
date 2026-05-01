import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFE86C9A),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFFF7FB),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFFFEFF6),
        foregroundColor: colorScheme.onSurface,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFFFFFFFF),
        elevation: 0.8,
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData dark() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF8DB7),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF22131C),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}
