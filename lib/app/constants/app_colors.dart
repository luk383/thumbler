import 'package:flutter/material.dart';

/// Central color palette for the WAJE brand.
///
/// Use these constants everywhere instead of raw `Color(0xFF...)` literals so
/// that a single palette change propagates across the whole app.
abstract final class AppColors {
  // ── Backgrounds ─────────────────────────────────────────────────────────────
  /// Main scaffold / page background.
  static const Color darkBg = Color(0xFF070B12);

  /// Card, dialog, and panel background (slightly lighter than [darkBg]).
  static const Color darkPanel = Color(0xFF0A0F18);

  /// Elevated surface (nav bar, bottom sheet background).
  static const Color darkSurface = Color(0xFF0E1626);

  // ── Brand ────────────────────────────────────────────────────────────────────
  /// Primary accent — WAJE orange.
  static const Color orange = Color(0xFFFF7A00);

  /// Secondary / navy.
  static const Color navy = Color(0xFF0B1F3A);

  // ── Borders & Dividers ───────────────────────────────────────────────────────
  /// Standard border / divider line.
  static const Color border = Color(0xFF1A2540);

  /// Softer border, also used for placeholder / ghost text.
  static const Color borderMuted = Color(0xFF2A3A55);

  // ── Text ─────────────────────────────────────────────────────────────────────
  /// Primary text on dark backgrounds.
  static const Color textPrimary = Color(0xFFF3F6FB);

  /// Secondary / subtitle text.
  static const Color textSecondary = Color(0xFFA8B3C7);

  /// Muted label / section-header text.
  static const Color textMuted = Color(0xFF3A4A60);

  /// Very faint hint / placeholder text.
  static const Color textFaint = Color(0xFF2A3A55);

  /// Disabled / close-icon color.
  static const Color textDisabled = Color(0xFF4A5568);

  // ── Semantic ─────────────────────────────────────────────────────────────────
  /// Success / run / green accent.
  static const Color green = Color(0xFF00C853);

  /// Error / danger.
  static const Color red = Color(0xFFEF5350);

  /// Warning / attention.
  static const Color yellow = Color(0xFFFFC107);

  /// Weight workout / power zone accent.
  static const Color purple = Color(0xFF7C4DFF);

  /// Lighter purple (used for zone gradients).
  static const Color lightPurple = Color(0xFFB39DDB);

  /// Water / hydration / blue accent.
  static const Color blue = Color(0xFF2196F3);
}
