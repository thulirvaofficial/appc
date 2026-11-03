import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Headlines - Playfair Display
  static TextStyle displayLarge = GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.forestGreen,
  );

  static TextStyle displayMedium = GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.forestGreen,
  );

  static TextStyle displaySmall = GoogleFonts.playfairDisplay(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.forestGreen,
  );

  // Body & Titles - DM Sans
  static TextStyle titleLarge = GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static TextStyle titleMedium = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static TextStyle titleSmall = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static TextStyle bodyLarge = GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textMid,
  );

  static TextStyle bodyMedium = GoogleFonts.dmSans(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textMid,
  );

  static TextStyle bodySmall = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );

  static TextStyle button = GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  static TextStyle price = GoogleFonts.dmSans(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.forestGreen,
  );
}

