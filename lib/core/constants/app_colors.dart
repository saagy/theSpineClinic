/// Centralised colour palette for the Spine Clinic application.
///
/// Design tokens follow the Stripe Dashboard aesthetic:
/// Slate-family neutrals, a single "Blurple" primary accent,
/// and paired foreground/background status colours for badges.
///
/// Rule 8 — no hardcoded colours anywhere outside this file.
library;

import 'package:flutter/material.dart';

/// Application-wide colour constants.
///
/// All values are `const` so they can be used in widget constructors
/// and as compile-time defaults.
abstract final class AppColors {
  // ──────────────────── Canvas & Surfaces ────────────────────

  /// Slate 50 — full-page background canvas.
  static const Color background = Color(0xFFF8FAFC);

  /// Pure white — card / container / modal surfaces.
  static const Color surface = Color(0xFFFFFFFF);

  /// Slate 200 — crisp 1px borders, dividers, input outlines.
  static const Color border = Color(0xFFE2E8F0);

  /// Slightly darker border used on hover / focus states.
  static const Color borderStrong = Color(0xFFCBD5E1);

  // ──────────────────── Primary (Blurple) ────────────────────

  /// Stripe Blurple — primary action buttons, links, active states.
  static const Color primary = Color(0xFF635BFF);

  /// Darkened Blurple for hover / pressed states.
  static const Color primaryHover = Color(0xFF5346E0);

  /// Very light tint used for selected-row highlights or badges.
  static const Color primaryLight = Color(0xFFEBEAFF);

  // ──────────────────── Text Hierarchy ────────────────────

  /// Slate 900 — headings, primary labels.
  static const Color textPrimary = Color(0xFF0F172A);

  /// Slate 600 — secondary body copy, metadata.
  static const Color textSecondary = Color(0xFF475569);

  /// Slate 400 — placeholders, disabled text, timestamps.
  static const Color textMuted = Color(0xFF94A3B8);

  /// White text for use on dark or primary backgrounds.
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ──────────────────── Status Pairs ────────────────────

  /// Emerald 600 — success foreground (text, icon, border).
  static const Color success = Color(0xFF059669);

  /// Emerald 50 — success badge / chip background.
  static const Color successBg = Color(0xFFECFDF5);

  /// Amber 600 — warning foreground.
  static const Color warning = Color(0xFFD97706);

  /// Amber 50 — warning badge / chip background.
  static const Color warningBg = Color(0xFFFFFBEB);

  /// Rose 600 — error / destructive foreground.
  static const Color error = Color(0xFFE11D48);

  /// Alias for error/destructive action color.
  static const Color danger = error;

  /// Rose 50 — error badge / chip background.
  static const Color errorBg = Color(0xFFFFF1F2);

  /// Sky 600 — informational foreground.
  static const Color info = Color(0xFF0284C7);

  /// Sky 50 — informational badge / chip background.
  static const Color infoBg = Color(0xFFF0F9FF);

  // ──────────────────── Elevation / Shadow ────────────────────

  /// Crisp, bottom-oriented micro-shadow for cards and containers.
  ///
  /// Produces a subtle 1px-feel drop instead of a diffuse glow,
  /// consistent with the Stripe Dashboard depth language.
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x0D0F172A), // ~5 % opacity of Slate 900
    blurRadius: 3,
    offset: Offset(0, 1),
  );

  /// Slightly stronger shadow for elevated elements (dropdowns, dialogs).
  static const BoxShadow elevatedShadow = BoxShadow(
    color: Color(0x1A0F172A), // ~10 % opacity of Slate 900
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  // ──────────────────── Utility ────────────────────

  /// Fully transparent — for surfaceTintColor, background barriers.
  static const Color transparent = Colors.transparent;

  /// Semi-transparent black scrim for loading overlays and modal backdrops (~40 % opacity).
  static const Color overlayScrim = Color(0x66000000);
}
