import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors - Dark Navy & Neon Cyan
  static const Color primaryColor = Color(0xFF06B6D4); // Neon Cyan
  static const Color primaryDark = Color(0xFF0891B2);
  static const Color primaryLight = Color(0xFF67E8F9);

  // Secondary Colors - Danger Red for Spy
  static const Color accentColor = Color(0xFFEF4444); // Neon Red
  static const Color secondaryColor = Color(0xFF3B82F6); // Blue

  // Background Colors - Deep Space/Navy
  static const Color scaffoldBg = Color(0xFF0F172A); // Very Dark Navy
  static const Color surfaceBg = Color(0xFF1E293B); // Dark Navy
  static const Color cardBg = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC); // White-ish
  static const Color textSecondary = Color(0xFF94A3B8); // Light Grey
  static const Color textLight = Colors.white;

  // Indication Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // Dimensions
  static const double cardElevation = 0.0; // Flat design with borders
  static const double buttonElevation = 4.0;
  static const double borderRadius = 12.0;
  static const double contentPadding = 24.0;

  // Text Styles - Using Google Fonts (Changa for bulky/tech look)
  static TextStyle get headingStyle => GoogleFonts.changa(
        fontSize: 32.0,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        height: 1.2,
      );

  static TextStyle get subheadingStyle => GoogleFonts.changa(
        fontSize: 24.0,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        height: 1.2,
      );

  static TextStyle get bodyStyle => GoogleFonts.changa(
        fontSize: 16.0,
        color: textSecondary,
        height: 1.5,
      );

  static TextStyle get captionStyle => GoogleFonts.changa(
        fontSize: 14.0,
        color: textSecondary.withValues(alpha: 0.7),
      );

  // Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: scaffoldBg, // Dark text on bright button
        elevation: 8,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        shadowColor: primaryColor.withValues(alpha: 0.4),
        textStyle: GoogleFonts.changa(
          fontSize: 20.0, // Increased font size slightly
          fontWeight: FontWeight.bold,
        ),
      );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: surfaceBg,
        foregroundColor: primaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          side: BorderSide(color: primaryColor, width: 1),
        ),
        textStyle: GoogleFonts.changa(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      );

  // Card Decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      );

  // Gradient Backgrounds
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryDark],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [scaffoldBg, Color(0xFF020617)],
  );

  // App Theme
  static ThemeData get currentTheme => darkTheme;

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: scaffoldBg,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceBg,
      error: error,
      onPrimary: scaffoldBg,
      onSecondary: textLight,
      onSurface: textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: textLight),
      titleTextStyle: GoogleFonts.changa(
        color: textLight,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceBg,
      elevation: 0,
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle,
    ),
    textTheme: TextTheme(
      displayLarge: headingStyle,
      headlineMedium: subheadingStyle,
      bodyLarge: bodyStyle,
      bodyMedium: captionStyle,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceBg,
      contentPadding: const EdgeInsets.all(20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: TextStyle(color: textSecondary),
      hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
    ),
    iconTheme: const IconThemeData(color: primaryColor),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.1),
      thickness: 1,
    ),
  );
}
