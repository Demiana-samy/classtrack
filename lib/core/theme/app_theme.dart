import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

export '../utils/app_colors.dart';
export '../utils/app_text_styles.dart';

class AppTheme {
  static const fontFamily = AppTextStyles.fontFamily;

  static ThemeData get dark {
    const textTheme = TextTheme(
      displayLarge: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white),
      displayMedium: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white),
      displaySmall: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white),
      headlineLarge: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white),
      headlineMedium: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white),
      headlineSmall: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white),
      titleLarge: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white),
      titleMedium: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white),
      titleSmall: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white),
      bodyLarge: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white),
      bodyMedium: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white),
      bodySmall: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white),
      labelLarge: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white),
      labelMedium: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white),
      labelSmall: TextStyle(fontFamily: AppTextStyles.fontFamily, color: AppColors.muted),
    );
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c),
        );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.card,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.withColor(AppTextStyles.cairo20W600, Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        labelStyle: AppTextStyles.withColor(AppTextStyles.cairo14W400, AppColors.muted),
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
          textStyle: AppTextStyles.withColor(AppTextStyles.cairo16W500, Colors.white),
        ),
      ),
    );
  }
}
