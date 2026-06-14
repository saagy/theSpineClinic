/// Centralised colour palette for the Spine Clinic application.
///
/// Design tokens follow the Medics Medical App UI Kit aesthetic:
/// Pure white canvases, a single teal primary accent (#2BB5A0),
/// soft shadows, and paired foreground/background status colours.
///
/// Rule 8 — no hardcoded colours anywhere outside this file.
library;

import 'package:flutter/material.dart';

/// Application-wide colour constants.
///
/// All values are `const` so they can be used in widget constructors
/// and as compile-time defaults.
abstract final class AppColors {
  // ──────────────── Canvas & Surfaces ────────────────

  /// Pure white — full-page background canvas.
  static const Color background = Color(0xFFFFFFFF);

  /// Pure white — card / container / modal surfaces.
  static const Color surface = Color(0xFFFFFFFF);

  /// Light gray — subtle 1px borders, dividers, input outlines.
  static const Color border = Color(0xFFE8E8E8);

  /// Slightly darker border used on focus states.
  static const Color borderStrong = Color(0xFFD0D0D0);

  // ──────────────── Primary (Teal) ────────────────

  /// Teal — primary action buttons, links, active states, icons.
  static const Color primary = Color(0xFF2BB5A0);

  /// Darker teal for pressed / hover states.
  static const Color primaryDark = Color(0xFF239A8A);

  /// Very light teal tint used for selected-row highlights or badges.
  static const Color primaryLight = Color(0xFFE8F7F4);

  // ──────────────── Text Hierarchy ────────────────

  /// Near-black — headings, primary labels, titles.
  static const Color textPrimary = Color(0xFF1A1A1A);

  /// Medium gray — secondary body copy, metadata, subtitles.
  static const Color textSecondary = Color(0xFF6B7280);

  /// Light gray — placeholders, disabled text, timestamps.
  static const Color textMuted = Color(0xFF9CA3AF);

  /// White text for use on dark or teal backgrounds.
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ──────────────── Status Pairs ────────────────

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

  // ──────────────── Elevation / Shadow ────────────────

  /// Soft, barely-visible card shadow that lifts surfaces off white
  /// backgrounds without hard borders. Medics UI Kit style.
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x08000000), // ~3 % opacity black
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  /// Slightly stronger shadow for elevated elements (dropdowns, dialogs).
  static const BoxShadow elevatedShadow = BoxShadow(
    color: Color(0x0F000000), // ~6 % opacity black
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  // ──────────────── Utility ────────────────

  /// Fully transparent — for surfaceTintColor, background barriers.
  static const Color transparent = Colors.transparent;

  /// Semi-transparent black scrim for loading overlays and modal
  /// backdrops (~30 % opacity).
  static const Color overlayScrim = Color(0x4D000000);
}
