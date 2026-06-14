/// Centralised typography tokens for the Spine Clinic application.
///
/// **Design rationale — bold hierarchy, generous scale:**
/// Five size tiers (24 / 20 / 16 / 14 / 12 px) with strong weight
/// contrast. Large bold titles paired with muted gray subtitles create
/// clear visual hierarchy. Inter font throughout for clean, modern
/// rendering at all sizes.
///
/// Font family: **Inter** — a variable-weight sans-serif optimised
/// for UI readability and tabular data.
///
/// Rule 8 — no hardcoded text styles outside this file.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';

/// Application-wide [TextStyle] constants.
abstract final class AppTextStyles {
  /// Base font family applied to every style.
  static const String _fontFamily = 'Inter';

  // ──────────────── Headings ────────────────

  /// Screen titles, page headers — 24px bold.
  static const TextStyle headingLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// Card headers, dialog titles — 20px bold.
  static const TextStyle headingMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  /// Section headers, form group labels — 16px semibold.
  static const TextStyle headingSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ──────────────── Body ────────────────

  /// Default body copy — 14px regular.
  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Bold body — inline emphasis, row labels, patient names.
  static const TextStyle bodyBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Medium-weight body — buttons, nav items, interactive text.
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Secondary body — metadata, descriptions, helper text.
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  /// Larger body for intro text and empty states — 16px regular.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // ──────────────── Captions ────────────────

  /// Timestamps, metadata labels — 12px regular.
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textMuted,
  );

  /// Medium-weight caption — column headers, tab labels, chip text.
  static const TextStyle captionMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  /// Bold caption — active tabs, badge text, highlighted chips.
  static const TextStyle captionBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // ──────────────── Special Purpose ────────────────

  /// Button label — semibold 16px on primary-coloured background.
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.0,
    color: AppColors.textOnPrimary,
  );

  /// Numeric data cells — tabular (monospaced-like) figures.
  static const TextStyle number = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Large numeric display — KPI cards, summary stats.
  static const TextStyle numberLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
