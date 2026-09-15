import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_dimensions.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      // The real background is the app-wide image painted once behind
      // every route in BytlBattleApp's MaterialApp.builder — every
      // Scaffold stays transparent so that image always shows through.
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: AppColors.primary,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accentCyan,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.heading2,
      ),
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.heading1,
        headlineMedium: AppTextStyles.heading2,
        bodyMedium: AppTextStyles.body,
        labelLarge: AppTextStyles.button,
      ),
      inputDecorationTheme: InputDecorationTheme(
        // No more solid filled "box" look — fill is kept, but mostly
        // see-through, with a light, shiny border doing the work of
        // outlining the field instead.
        filled: true,
        fillColor: AppColors.inputFill.withOpacity(0.25),
        hintStyle: AppTextStyles.hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1.1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1.1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.accentCyan, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: AppTextStyles.link,
        ),
      ),
      useMaterial3: true,
    );
  }
}
