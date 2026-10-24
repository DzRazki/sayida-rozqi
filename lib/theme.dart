import 'package:flutter/material.dart';

class AppColors {
  static const darkBrown = Color(0xFF2A1B12);
  static const brown = Color(0xFF5A3423);
  static const gold = Color(0xFFD4AF37);
  static const cream = Color(0xFFF8F4EF);
  static const card = Color(0xFFFFFFFF);
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
            foregroundColor: AppColors.gold,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
