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

  // Premium visual language used by the main mobile surfaces. These are
  // additive tokens so itinerary summary/detail keep their existing styling.
  static const Color premiumNavy = Color(0xFF0B2341);
  static const Color premiumBlue = Color(0xFF176BBD);
  static const Color premiumTeal = Color(0xFF168A9C);
  static const Color premiumBackground = Color(0xFFF6F8FB);
  static const Color premiumSurface = Color(0xFFFFFFFF);
  static const Color premiumBorder = Color(0xFFE3EAF1);
  static const Color premiumMuted = Color(0xFF74849A);
  static const Color premiumSoftBlue = Color(0xFFEAF3FB);
}
