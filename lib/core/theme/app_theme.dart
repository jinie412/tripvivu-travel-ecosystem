import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
            textStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      );
}

/// App-wide text styles reference
class AppTextStyles {
  AppTextStyles._();
  static const heading1 = TextStyle(
      fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static const heading2 = TextStyle(
      fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static const body = TextStyle(fontSize: 14, color: AppColors.textSecondary);
  static const caption =
      TextStyle(fontSize: 12, color: Color(0xFF9E9E9E));
}