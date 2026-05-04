import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography theo design system - Manrope + Inter
class AppTextStyles {
  // Display - Manrope (cho số lớn và hero text)
  static TextStyle displayLarge = GoogleFonts.manrope(
    fontSize: 56,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );
  
  static TextStyle displayMedium = GoogleFonts.manrope(
    fontSize: 44,
    fontWeight: FontWeight.w800,
    height: 1.15,
  );
  
  static TextStyle displaySmall = GoogleFonts.manrope(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  
  // Headline - Manrope (page titles)
  static TextStyle headlineLarge = GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  
  static TextStyle headlineMedium = GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  
  static TextStyle headlineSmall = GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );
  
  // Title - Inter (card titles, navigation)
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // Body - Inter (main content)
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  // Label - Inter (buttons, chips)
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );
  
  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.5,
  );
  
  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0.8,
  );
}
