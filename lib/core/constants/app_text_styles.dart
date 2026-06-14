/// Centralised typography tokens for the Spine Clinic application.
///
/// **Design rationale — bold hierarchy, generous scale:**
/// Five size tiers (24 / 20 / 18 / 14 / 12 px) with strong weight
/// contrast. Large bold titles paired with muted gray subtitles create
/// clear visual hierarchy.
///
/// Font family: **Plus Jakarta Sans** — a modern geometric sans-serif
/// with distinctive character, optimised for UI readability.
///
/// Rule 8 — no hardcoded text styles outside this file.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';

/// Application-wide [TextStyle] constants.
///
/// Uses [GoogleFonts.plusJakartaSans] for the brand typeface. Styles are
/// `static final` rather than `const` because the Google Fonts package
/// resolves font files at runtime.
abstract final class AppTextStyles {
  // ──────────────── Headings ────────────────

  /// Screen titles, page headers — 24px bold.
  static final TextStyle headingLarge = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// Card headers, dialog titles — 20px bold.
  static final TextStyle headingMedium = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  /// Section headers, form group labels — 16px semibold.
  static final TextStyle headingSmall = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ──────────────── Body ────────────────

  /// Default body copy — 14px regular.
  static final TextStyle body = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Bold body — inline emphasis, row labels.
  static final TextStyle bodyBold = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Medium-weight body — buttons, nav items, interactive text.
  static final TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Secondary body — metadata, descriptions, helper text.
  static final TextStyle bodySecondary = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  /// Larger body for intro text and empty states — 16px regular.
  static final TextStyle bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  /// Card title — patient names, list item primary text. 18px bold.
  static final TextStyle cardTitle = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ──────────────── Captions ────────────────

  /// Timestamps, metadata labels — 12px regular.
  static final TextStyle caption = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textMuted,
  );

  /// Medium-weight caption — column headers, tab labels, chip text.
  static final TextStyle captionMedium = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  /// Bold caption — active tabs, badge text, highlighted chips.
  static final TextStyle captionBold = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // ──────────────── Special Purpose ────────────────

  /// Brand wordmark — the "Spine Clinic" header identity. 20px extrabold.
  static final TextStyle brand = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// Button label — semibold 16px on primary-coloured background.
  static final TextStyle button = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.0,
    color: AppColors.textOnPrimary,
  );

  /// Numeric data cells — tabular (monospaced-like) figures.
  static final TextStyle number = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Large numeric display — KPI cards, summary stats.
  static final TextStyle numberLarge = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
