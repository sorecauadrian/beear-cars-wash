import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ═══ Brand ═══
  static const Color brand = Color(0xFFE85D4C);

  // ═══ Primary: deep navy for structure, navigation, headings ═══
  static const Color primary = Color(0xFF1A2B47);
  static const Color primaryLight = Color(0xFF2C3E5A);
  static const Color onPrimary = Colors.white;

  // ═══ Accent: warm coral for CTAs, highlights ═══
  static const Color accent = Color(0xFFE85D4C);
  static const Color accentLight = Color(0xFFFFF0EE);

  // ═══ Secondary: teal for water/wash association ═══
  static const Color secondary = Color(0xFF0D7377);
  static const Color secondaryLight = Color(0xFFE0F2F1);
  static const Color onSecondary = Colors.white;

  // ═══ Neutrals (Light) ═══
  static const Color background = Color(0xFFF8FAFB);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF0F4F8);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color outline = Color(0xFFE2E8F0);
  static const Color outlineVariant = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFFE2E8F0);

  // ═══ Neutrals (Dark) ═══
  static const Color darkBackground = Color(0xFF0F1318);
  static const Color darkSurface = Color(0xFF1A1F27);
  static const Color darkSurfaceVariant = Color(0xFF242B35);
  static const Color darkOnSurface = Color(0xFFE8ECF1);
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color darkOutline = Color(0xFF2D3544);
  static const Color darkOutlineVariant = Color(0xFF3B4556);
  static const Color darkDivider = Color(0xFF2D3544);

  // ═══ Accent (Dark adjustments) ═══
  static const Color darkAccent = Color(0xFFEF7A6C);
  static const Color darkAccentLight = Color(0xFF2A1F1E);
  static const Color darkSecondary = Color(0xFF2CB8BC);
  static const Color darkSecondaryLight = Color(0xFF0F2726);

  // ═══ Semantic ═══
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color onError = Colors.white;
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEFF6FF);

  // ═══ Semantic (Dark) ═══
  static const Color darkError = Color(0xFFEF5350);
  static const Color darkErrorLight = Color(0xFF2A1515);
  static const Color darkSuccess = Color(0xFF4CAF50);
  static const Color darkSuccessLight = Color(0xFF132A15);
  static const Color darkWarning = Color(0xFFFFB74D);
  static const Color darkWarningLight = Color(0xFF2A2213);
  static const Color darkInfo = Color(0xFF64B5F6);
  static const Color darkInfoLight = Color(0xFF13202A);

  // ═══ Status colors ═══
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusAccepted = Color(0xFF0891B2);
  static const Color statusInProgress = Color(0xFF7C3AED);
  static const Color statusSuccess = Color(0xFF16A34A);
  static const Color statusRejected = Color(0xFFDC2626);

  // ═══ Wash type colors ═══
  static const Color washInterior = Color(0xFF3B82F6);
  static const Color washExterior = Color(0xFF06B6D4);
  static const Color washComplete = Color(0xFF8B5CF6);

  // ═══ Shadows ═══
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);

  // Legacy aliases
  static const Color darkNavy = onSurface;
  static const Color cream = background;
  static const Color requested = statusPending;
  static const Color accepted = statusAccepted;
  static const Color inProgress = statusInProgress;
  static const Color done = statusSuccess;
  static const Color rejected = statusRejected;
  static const Color cancelled = statusRejected;
  static const Color statusActive = statusInProgress;
}
