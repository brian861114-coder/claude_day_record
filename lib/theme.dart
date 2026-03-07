import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFFFF9F5);
  static const Color accent = Color(0xFFFF8C42);
  static const Color accentLight = Color(0xFFFFE0C8);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF888888);
  static const Color cardColor = Colors.white;

  static ThemeData get themeData => ThemeData(
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          primary: accent,
          surface: background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: textSecondary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
          hintStyle: const TextStyle(
            fontSize: 16,
            color: textSecondary,
          ),
        ),
      );
}
