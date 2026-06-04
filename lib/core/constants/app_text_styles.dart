/// Centralised typography tokens for the Spine Clinic application.
///
/// **Design rationale — data-density over decoration:**
/// Only four size tiers (20 / 16 / 14 / 12 px) are used.
/// Visual hierarchy is achieved through **font-weight** (w400–w700)
/// and **colour** ([AppColors.textPrimary] vs [textSecondary] vs
/// [textMuted]) rather than large size jumps. This keeps tables,
/// list views, and forms vertically compact.
///
/// Font family: **Inter** — a variable-weight sans-serif optimised
/// for UI and tabular data at small sizes.
///
/// Rule 8 — no hardcoded text styles outside this file.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';

/// Application-wide [TextStyle] constants.
abstract final class AppTextStyles {
  /// Base font family applied to every style.
  static const String _fontFamily = 'Inter';

  // ──────────────────── Tier 1 — Headings (20 px) ────────────

  /// Page titles, modal titles.
  static const TextStyle headingLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ──────────────────── Tier 2 — Sub-headings (16 px) ────────

  /// Section headers, card titles, form group labels.
  static const TextStyle headingSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  // ──────────────────── Tier 3 — Body (14 px) ────────────────

  /// Default body copy. Used for paragraphs, table cells, form values.
  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  /// Bold body — inline emphasis, row labels, field names.
  static const TextStyle bodyBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  /// Medium-weight body — buttons, nav items.
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  /// Secondary body — metadata, descriptions, helper text.
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  // ──────────────────── Tier 4 — Captions (12 px) ────────────

  /// Timestamps, badges, table column headers, chip labels.
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textMuted,
  );

  /// Medium-weight caption — column headers, tab labels.
  static const TextStyle captionMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  /// Bold caption — active tab, highlighted badge text.
  static const TextStyle captionBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // ──────────────────── Special Purpose ────────────────────

  /// Button label — medium weight body on primary-coloured background.
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.0,
    color: AppColors.textOnPrimary,
  );

  /// Numeric data cells — tabular (monospaced-like) figures.
  static const TextStyle number = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Large numeric display — KPI cards, summary stats.
  static const TextStyle numberLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
