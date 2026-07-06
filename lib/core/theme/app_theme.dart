import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // Premium Warm & Minimalist Palette
  static const Color _primary = Color(0xFFC8B4BA); // Cooler Mauve / 藕粉色
  static const Color _background = Color(0xFFFDFBFB); // Warm Off-White
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _error = Color(
    0xFFE63946,
  ); // Highly visible red for emergency stop
  static const Color _textPrimary = Color(0xFF332D2D);

  static ThemeData light() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      error: _error,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _background,
      appBarTheme: const AppBarTheme(
        backgroundColor: _background,
        foregroundColor: _textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0, // Keep it flat and clean
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Large premium rounding
        ),
        margin: EdgeInsets.zero,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      error: _error,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF1E1A1A), // Warm dark grey
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1A1A),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2B2525),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
