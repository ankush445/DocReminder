import 'package:flutter/material.dart';

/// Centralized color palette for the DocReminder application
/// Follows Material 3 design principles with custom accent colors
class AppColors {
  // ── Light Theme Backgrounds ────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8F9FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F2F5);
  static const Color lightBackground2 = Color(0xFFFFFFFF);
  static const Color lightBackground3 = Color(0xFFF0F2F5);

  // ── Dark Theme Backgrounds ─────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkSurface = Color(0xFF1A1F2E);
  static const Color darkSurfaceVariant = Color(0xFF252D3D);

  // ── Primary Accent Colors ─────────────────────────────────────────────
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // ── Text Colors ────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ── Status Colors ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Semantic Color Variants ────────────────────────────────────────────
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color infoLight = Color(0xFFDEF2FF);

  // ── Dimmed Status Colors (for backgrounds) ─────────────────────────────
  static Color successDim = success.withValues(alpha: 0.12);
  static Color warningDim = warning.withValues(alpha: 0.12);
  static Color errorDim = error.withValues(alpha: 0.12);
  static Color infoDim = info.withValues(alpha: 0.12);
  static Color primaryDim = primary.withValues(alpha: 0.15);

  // ── Borders & Dividers ─────────────────────────────────────────────────
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);
  static const Color divider = Color(0xFFD1D5DB);

  // ── Overlay & Shadows ──────────────────────────────────────────────────
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);
  static const Color scrim = Color(0x33000000);

  // ── Deprecated color names (for backward compatibility) ────────────────
  @Deprecated('Use AppColors.lightBackground instead')
  static const Color navy = lightBackground;

  @Deprecated('Use AppColors.lightSurface instead')
  static const Color navy2 = lightSurface;

  @Deprecated('Use AppColors.lightSurfaceVariant instead')
  static const Color navy3 = lightSurfaceVariant;

  @Deprecated('Use AppColors.primary instead')
  static const Color gold = primary;

  @Deprecated('Use AppColors.primaryLight instead')
  static const Color goldLight = primaryLight;

  @Deprecated('Use AppColors.textPrimary instead')
  static const Color text1 = textPrimary;

  @Deprecated('Use AppColors.textSecondary instead')
  static const Color text2 = textSecondary;

  @Deprecated('Use AppColors.textTertiary instead')
  static const Color text3 = textTertiary;

  @Deprecated('Use AppColors.success instead')
  static const Color green = success;

  @Deprecated('Use AppColors.warning instead')
  static const Color amber = warning;

  @Deprecated('Use AppColors.error instead')
  static const Color red = error;

  @Deprecated('Use AppColors.successDim instead')
  static Color greenDim = success.withValues(alpha: 0.12);

  @Deprecated('Use AppColors.warningDim instead')
  static Color amberDim = warning.withValues(alpha: 0.12);

  @Deprecated('Use AppColors.errorDim instead')
  static Color redDim = error.withValues(alpha: 0.12);

  @Deprecated('Use AppColors.primaryDim instead')
  static Color goldDim = primary.withValues(alpha: 0.15);
}
