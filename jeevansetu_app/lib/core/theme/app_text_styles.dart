import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized text styles for consistent typography across the app
class AppTextStyles {
  AppTextStyles._();

  // ─── Headings (Outfit) ───
  static TextStyle get heroTitle => GoogleFonts.outfit(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.5,
      );

  static TextStyle get screenTitle => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  static TextStyle get sectionTitle => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get cardTitle => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  // ─── Body Text (Inter) ───
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  // ─── Labels ───
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );

  // ─── Special Styles ───
  static TextStyle get countdown => GoogleFonts.outfit(
        fontSize: 72,
        fontWeight: FontWeight.w800,
        height: 1.0,
      );

  static TextStyle get scoreDisplay => GoogleFonts.outfit(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.0,
      );

  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get chipText => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get otpDigit => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get statusText => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      );
}
