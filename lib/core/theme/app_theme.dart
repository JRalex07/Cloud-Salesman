import 'package:flutter/material.dart';

class AppTheme {
  // Vibrant FMCG distribution branding colors
  static const Color primaryColor = Color(0xFF1E3A8A); // Deep Blue
  static const Color secondaryColor = Color(0xFF10B981); // Emerald Green Accent
  static const Color accentColor = Color(0xFFF3F4F6); // Warm Off-White
  static const Color darkCanvas = Color(0xFF111827); // Charcoal Dark Background

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        background: Colors.grey[50]!,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.grey[50],
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        background: darkCanvas,
        surface: const Color(0xFF1F2937),
      ),
      scaffoldBackgroundColor: darkCanvas,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1F2937),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F2937),
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
    );
  }
}
