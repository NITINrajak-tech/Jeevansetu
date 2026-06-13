import 'package:flutter/material.dart';

/// Curated color palette for JeevanSetu
/// Deep navy base, vibrant semantic colors, glassmorphism-ready surfaces
class AppColors {
  AppColors._();

  // ─── Primary Palette ───
  static const Color primary = Color(0xFF4A90D9);
  static const Color primaryDark = Color(0xFF0A1628);
  static const Color primaryLight = Color(0xFF1A2A4A);
  static const Color accent = Color(0xFF6BB5FF);

  // ─── Semantic Colors ───
  static const Color sosRed = Color(0xFFFF2D55);
  static const Color sosRedDark = Color(0xFFD41E43);
  static const Color safeGreen = Color(0xFF34C759);
  static const Color safeGreenDark = Color(0xFF28A745);
  static const Color warningAmber = Color(0xFFFF9500);
  static const Color warningAmberDark = Color(0xFFE08600);
  static const Color criticalRed = Color(0xFFFF3B30);
  static const Color moderateYellow = Color(0xFFFFCC00);
  static const Color infoBlue = Color(0xFF007AFF);

  // ─── Dark Theme Surfaces ───
  static const Color surfaceDark = Color(0xFF0D1117);
  static const Color surfaceDarkElevated = Color(0xFF161B22);
  static const Color surfaceDarkCard = Color(0xFF1C2333);
  static const Color borderDark = Color(0xFF30363D);
  static const Color shimmerDark = Color(0xFF21262D);

  // ─── Light Theme Surfaces ───
  static const Color surfaceLight = Color(0xFFF6F8FA);
  static const Color surfaceLightElevated = Color(0xFFFFFFFF);
  static const Color surfaceLightCard = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFD0D7DE);

  // ─── Text Colors ───
  static const Color textPrimaryDark = Color(0xFFE6EDF3);
  static const Color textSecondaryDark = Color(0xFF8B949E);
  static const Color textTertiaryDark = Color(0xFF484F58);
  static const Color textPrimaryLight = Color(0xFF1F2328);
  static const Color textSecondaryLight = Color(0xFF656D76);
  static const Color textTertiaryLight = Color(0xFF8C959F);

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A5F), Color(0xFF0A1628)],
  );

  static const LinearGradient sosGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF2D55), Color(0xFFD41E43)],
  );

  static const LinearGradient safeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34C759), Color(0xFF28A745)],
  );

  static const LinearGradient alertGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFF2D55), Color(0xFF8B0000)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFF9500), Color(0xFFFF6B00)],
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C2333), Color(0xFF161B22)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A90D9), Color(0xFF6BB5FF)],
  );

  /// Returns severity color based on score 0–100
  static Color severityColor(int score) {
    if (score >= 70) return criticalRed;
    if (score >= 40) return warningAmber;
    return safeGreen;
  }

  /// Returns severity label based on score 0–100
  static String severityLabel(int score) {
    if (score >= 70) return 'Critical';
    if (score >= 40) return 'Moderate';
    return 'Safe';
  }
}
