import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Primary deep blue — used for CTA buttons, headings, and active elements
  static const Color primary = Color(0xFF1A6EBD);

  /// Slightly darker shade for pressed/hover states
  static const Color primaryDark = Color(0xFF155A9E);

  /// Light teal used for travel preference chips
  static const Color accent = Color(0xFF00C2B2);

  /// Main app background (light blue-gray)
  static const Color background = Color(0xFFF0F4F8);

  /// Card / surface background
  static const Color surface = Colors.white;

  /// Primary text color
  static const Color textPrimary = Color(0xFF1C1C1E);

  /// Secondary / hint text color
  static const Color textSecondary = Color(0xFF6B7280);

  /// Input field border color (unfocused)
  static const Color inputBorder = Color(0xFFD1D5DB);

  /// Input fill
  static const Color inputFill = Color(0xFFF9FAFB);

  /// Decorative blob colors for auth background
  static const Color blobLight = Color(0xFFBFD9F2);
  static const Color blobMedium = Color(0xFF90BDE8);
}