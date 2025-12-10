import 'package:flutter/material.dart';

/// Brand colors for Beear Cars Wash - extracted from logo
class AppColors {
  AppColors._();

  // Primary brand color (red from car in logo)
  static const Color primary = Color(0xFFE93A1F); // rgb(233,58,31)
  
  // Secondary color (cyan/light blue from splashes and lights)
  static const Color secondary = Color(0xFF119BCB); // rgb(17,155,203)
  
  // Dark navy (text color from logo)
  static const Color darkNavy = Color(0xFF062746); // rgb(6,39,70)
  
  // Cream/off-white (bear skin color)
  static const Color cream = Color(0xFFFCF9F6); // rgb(252,249,246)
  
  // Additional colors
  static const Color background = Color(0xFFFCF9F6); // Cream background
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB00020);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onSurface = Color(0xFF062746); // Dark navy for text
  static const Color onError = Colors.white;
  
  // Status colors for bookings
  static const Color requested = Color(0xFFFF9800); // Orange
  static const Color accepted = Color(0xFF119BCB); // Cyan (matches brand)
  static const Color rejected = Color(0xFFE93A1F); // Red (matches primary)
  static const Color cancelled = Color(0xFFFF6B6B); // Light red/orange for cancellations
  static const Color inProgress = Color(0xFF9C27B0); // Purple
  static const Color done = Color(0xFF4CAF50); // Green
}

