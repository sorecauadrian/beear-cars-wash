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

  // ═══ Neutrals ═══
  static const Color background = Color(0xFFF8FAFB);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF0F4F8);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color outline = Color(0xFFE2E8F0);
  static const Color outlineVariant = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFFE2E8F0);

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

  // ═══ Status colors ═══
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusAccepted = Color(0xFF0891B2);
  static const Color statusInProgress = Color(0xFF7C3AED);
  static const Color statusSuccess = Color(0xFF16A34A);
  static const Color statusRejected = Color(0xFFDC2626);

  // ═══ Wash type colors ═══
  static const Color washInterior = Color(0xFF3B82F6);
  static const Color washExterior = Color(0xFF06B6D4);
  static const Color washTapiterie = Color(0xFFF97316);
  static const Color washComplete = Color(0xFF8B5CF6);

  // ═══ Shadows ═══
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);

  // Legacy aliases (kept to avoid breaking existing code during migration)
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
