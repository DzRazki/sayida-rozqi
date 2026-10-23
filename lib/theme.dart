import 'package:flutter/material.dart';

class AppColors {
  static const darkBrown = Color(0xFF3B2118);
  static const brown = Color(0xFF5A3423);
  static const gold = Color(0xFFE5B563);
  static const cream = Color(0xFFFBF5E9);
  static const card = Color(0xFFFFFDF8);
  static const muted = Color(0xFF806D5D);
  static const line = Color(0xFFEADBC6);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.darkBrown,
          primary: AppColors.darkBrown,
          secondary: AppColors.gold,
          surface: AppColors.card,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBrown,
          foregroundColor: AppColors.gold,
          centerTitle: true,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.darkBrown,
            foregroundColor: AppColors.cream,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
