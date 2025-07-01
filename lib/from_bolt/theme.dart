import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ModernTheme {
  // Deep and darker primary colors
  static const Color primaryColor = Color(0xFF1a0d2e);
  static const Color secondaryColor = Color(0xFF16213e);
  static const Color accentColor = Color(0xFF0f3460);
  static const Color surfaceColor = Color(0xFF0a0a0a);
  static const Color backgroundColor = Color(0xFF000000);
  static const Color cardColor = Color(0xFF1a1a1a);
  
  // Text colors for dark theme
  static const Color textPrimary = Color(0xFFffffff);
  static const Color textSecondary = Color(0xFFb0b0b0);
  static const Color textTertiary = Color(0xFF808080);
  
  // Status colors
  static const Color successColor = Color(0xFF00ff88);
  static const Color errorColor = Color(0xFFff4757);
  static const Color warningColor = Color(0xFFffa502);
  static const Color infoColor = Color(0xFF3742fa);
  
  // Gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF1a0d2e),
    Color(0xFF16213e),
    Color(0xFF0f3460),
  ];
  
  static const List<Color> surfaceGradient = [
    Color(0xFF1a1a1a),
    Color(0xFF2a2a2a),
  ];

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onBackground: textPrimary,
        error: errorColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textPrimary,
          elevation: 8,
          shadowColor: primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textTertiary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textTertiary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textTertiary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),
    );
  }
}

class ModernColors {
  static const Color deepPurple = Color(0xFF1a0d2e);
  static const Color darkBlue = Color(0xFF16213e);
  static const Color mediumBlue = Color(0xFF0f3460);
  static const Color lightBlue = Color(0xFF533483);
  
  static const Color neonGreen = Color(0xFF00ff88);
  static const Color neonRed = Color(0xFFff4757);
  static const Color neonYellow = Color(0xFFffa502);
  static const Color neonBlue = Color(0xFF3742fa);
  
  static const Color darkGray = Color(0xFF1a1a1a);
  static const Color mediumGray = Color(0xFF2a2a2a);
  static const Color lightGray = Color(0xFF3a3a3a);
}