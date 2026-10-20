import 'package:flutter/material.dart';

/// Design 1: dark indigo. Never hardcode colors in screens, use these.
class AppColors {
  static const bg = Color(0xFF171538);
  static const card = Color(0xFF231F52);
  static const border = Color(0xFF2E2A66);
  static const primary = Color(0xFF7F77DD);
  static const primaryDark = Color(0xFF534AB7);
  static const muted = Color(0xFFAFA9EC);
  static const success = Color(0xFF5DCAA5);
  static const danger = Color(0xFFF09595);
  static const warning = Color(0xFFEF9F27);
}

class AppTheme {
  static const fontFamily = 'Cairo';

  static ThemeData get dark {
    const textTheme = TextTheme(
      displayLarge: TextStyle(fontFamily: fontFamily, color: Colors.white),
      displayMedium: TextStyle(fontFamily: fontFamily, color: Colors.white),
      displaySmall: TextStyle(fontFamily: fontFamily, color: Colors.white),
      headlineLarge: TextStyle(fontFamily: fontFamily, color: Colors.white),
      headlineMedium: TextStyle(fontFamily: fontFamily, color: Colors.white),
      headlineSmall: TextStyle(fontFamily: fontFamily, color: Colors.white),
      titleLarge: TextStyle(fontFamily: fontFamily, color: Colors.white),
      titleMedium: TextStyle(fontFamily: fontFamily, color: Colors.white),
      titleSmall: TextStyle(fontFamily: fontFamily, color: Colors.white),
      bodyLarge: TextStyle(fontFamily: fontFamily, color: Colors.white),
      bodyMedium: TextStyle(fontFamily: fontFamily, color: Colors.white),
      bodySmall: TextStyle(fontFamily: fontFamily, color: Colors.white),
      labelLarge: TextStyle(fontFamily: fontFamily, color: Colors.white),
      labelMedium: TextStyle(fontFamily: fontFamily, color: Colors.white),
      labelSmall: TextStyle(fontFamily: fontFamily, color: AppColors.muted),
    );
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c),
        );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.card,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        labelStyle: const TextStyle(color: AppColors.muted, fontFamily: fontFamily),
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.primary),
        errorBorder: border(AppColors.danger),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
