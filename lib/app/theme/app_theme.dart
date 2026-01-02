import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.ice,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.navy,
      secondary: AppColors.highlight,
      surface: Colors.white,
      background: AppColors.ice,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.navy,
      selectedItemColor: Colors.white,
      unselectedItemColor: Color(0xDDFFFFFF),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme().copyWith(
      headlineSmall: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyMedium: const TextStyle(color: AppColors.textSecondary),
    ),
  );
}
