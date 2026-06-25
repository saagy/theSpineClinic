/// Centralised spacing, sizing, and corner-radius tokens.
///
/// Every value sits on a strict **4 px base grid** so that padding,
/// margins, and gaps always align visually. Generous spacing for
/// modern touch-friendly layouts with breathing room.
///
/// Rule 8 — no hardcoded sizes anywhere outside this file.
library;

import 'package:flutter/material.dart';

/// Application-wide dimension constants.
abstract final class AppSizes {
  // ──────────────── 4px Spacing Scale ────────────────

  /// 2 px — micro adjustments (icon-to-text nudges).
  static const double p2 = 2.0;

  /// 4 px — tightest standard spacing.
  static const double p4 = 4.0;

  /// 6 px — between badge icon and label.
  static const double p6 = 6.0;

  /// 8 px — compact cell padding, inline gaps.
  static const double p8 = 8.0;

  /// 12 px — inner card padding, form field spacing.
  static const double p12 = 12.0;

  /// 14 px — input content vertical padding.
  static const double p14 = 14.0;

  /// 16 px — standard section padding.
  static const double p16 = 16.0;

  /// 20 px — card internal padding (generous).
  static const double p20 = 20.0;

  /// 24 px — screen-level horizontal padding.
  static const double p24 = 24.0;

  /// 28 px — section vertical gaps.
  static const double p28 = 28.0;

  /// 32 px — large section gaps.
  static const double p32 = 32.0;

  /// 36 px — extra-large separation.
  static const double p36 = 36.0;

  /// 40 px — page-level vertical breathing room.
  static const double p40 = 40.0;

  /// 48 px — hero spacing, empty state top offset.
  static const double p48 = 48.0;

  // ──────────────── Corner Radii ────────────────

  /// 4 px — badges, small tags.
  static const double r4 = 4.0;

  /// 6 px — compact inputs.
  static const double r6 = 6.0;

  /// 8 px — buttons, small containers.
  static const double r8 = 8.0;

  /// 12 px — compact containers, small dialogs.
  static const double r12 = 12.0;

  /// 16 px — cards, modals, bottom sheets.
  static const double r16 = 16.0;

  /// 24 px — large cards, hero containers.
  static const double r24 = 24.0;

  /// 100 px — pill-shaped buttons, chips (effectively infinite radius).
  static const double r999 = 100.0;

  // ── Legacy aliases ──
  /// @deprecated Use [r999] instead.
  static const double radiusPill = r999;

  /// @deprecated Use [buttonHeight] or specific height token.
  static const double h48 = 48.0;

  /// Pre-built [BorderRadius] for badges and chips.
  static const BorderRadius borderRadiusBadge =
      BorderRadius.all(Radius.circular(r4));

  /// Pre-built [BorderRadius] for inputs and dropdowns.
  static const BorderRadius borderRadiusInput =
      BorderRadius.all(Radius.circular(r24));

  /// Pre-built [BorderRadius] for cards and containers.
  static const BorderRadius borderRadiusCard =
      BorderRadius.all(Radius.circular(r16));

  /// Pre-built [BorderRadius] for modals and dialogs.
  static const BorderRadius borderRadiusDialog =
      BorderRadius.all(Radius.circular(r16));

  /// Pre-built [BorderRadius] for pill-shaped elements.
  static const BorderRadius borderRadiusPill =
      BorderRadius.all(Radius.circular(r999));

  // ──────────────── Component Dimensions ────────────────

  /// Standard primary button height (52 px).
  static const double buttonHeight = 52.0;

  /// Compact button height for inline actions (36 px).
  static const double buttonHeightSmall = 36.0;

  /// Standard text input field height (48 px).
  static const double inputHeight = 48.0;

  /// App bar / top navigation bar height.
  static const double appBarHeight = 56.0;

  /// Bottom navigation bar height (M3 NavigationBar standard).
  static const double bottomNavHeight = 80.0;

  /// Side-navigation rail width (collapsed).
  static const double navRailWidth = 72.0;

  /// Side-navigation drawer width (expanded).
  static const double navDrawerWidth = 240.0;

  /// Maximum content width for centered page layouts.
  static const double maxContentWidth = 1080.0;

  /// Maximum content width for profile / settings surfaces that should
  /// read as a single column on wide monitors (e.g. Admin Hub, profile
  /// menu rows). Phone screens stay unaffected because intrinsic widths
  /// are below this.
  static const double profileLayoutMaxWidth = 640.0;

  // ──────────────── Avatar Sizes ────────────────

  /// Small avatar — inline badges, compact lists.
  static const double avatarSmall = 36.0;

  /// Medium avatar — standard list tile avatars.
  static const double avatarMedium = 48.0;

  /// Tile avatar — patient/staff list row avatars.
  static const double avatarTile = 46.0;

  /// Large avatar — profile headers, detail screens.
  static const double avatarLarge = 56.0;

  // ──────────────── Icon Sizes ────────────────

  /// Icon size — small (badges, inline indicators).
  static const double iconSmall = 16.0;

  /// Icon size — default (buttons, list tiles).
  static const double iconDefault = 20.0;

  /// Icon size — large (empty-state illustrations).
  static const double iconLarge = 24.0;

  /// Icon size — hero (login, empty states).
  static const double iconHero = 56.0;

  // ──────────────── Border Widths ────────────────

  /// Standard 1px border for cards and inputs.
  static const double borderWidth = 1.0;

  /// 2px border for focused inputs / active selection.
  static const double borderWidthFocused = 2.0;

  /// Medium border width for diagnostic/emphasis borders (1.5 px).
  static const double borderWidthMedium = 1.5;

  // ──────────────── Convenience EdgeInsets ────────────────

  /// Symmetric horizontal screen padding (24 px).
  static const EdgeInsets paddingScreenH =
      EdgeInsets.symmetric(horizontal: p24);

  /// Standard card inner padding (20 px all sides).
  static const EdgeInsets paddingCard = EdgeInsets.all(p20);

  /// Compact cell padding (12 px vertical, 16 px horizontal).
  static const EdgeInsets paddingCell =
      EdgeInsets.symmetric(horizontal: p16, vertical: p12);

  /// Dialog body padding (20 px all sides).
  static const EdgeInsets paddingDialog = EdgeInsets.all(p20);

  // ──────────────── Layout Constants ────────────────

  /// Info-row label column width (e.g. profile detail screens).
  static const double labelColumnWidth = 90.0;

  /// Y-offset for overlay dropdowns.
  static const double overlayDropdownOffset = 52.0;

  /// Default Material elevation for dropdown overlays.
  static const double overlayElevation = 6.0;

  /// Minimum tappable touch target size per accessibility guidelines
  /// (44 px).
  static const double tappableMin = 44.0;

  // ──────────────── Chart Sizes ────────────────

  /// Height of a single bar in a trend chart.
  static const double chartBarMaxHeight = 160.0;

  /// Minimum height for a non-zero chart bar.
  static const double chartBarMinHeight = 4.0;

  /// Width of each bar in a trend chart.
  static const double chartBarWidth = 24.0;

  /// Height of the trend chart container.
  static const double chartContainerHeight = 220.0;

  /// Skeleton placeholder width for metric label.
  static const double skeletonLabelWidth = 80.0;

  /// Skeleton placeholder width for metric value.
  static const double skeletonValueWidth = 50.0;

  /// Skeleton placeholder width for subtitle.
  static const double skeletonSubtitleWidth = 110.0;

  /// Skeleton placeholder height for label text.
  static const double skeletonLabelHeight = 14.0;

  /// Skeleton placeholder height for value text.
  static const double skeletonValueHeight = 24.0;

  /// Skeleton placeholder height for subtitle text.
  static const double skeletonSubtitleHeight = 12.0;

  /// Revenue card icon container size.
  static const double revenueIconSize = 40.0;

  // ──────────────── Font Size Overrides ────────────────

  /// Extra-small font size for chart axis labels (9 px).
  static const double fontSizeXs = 9.0;

  /// Small-2 font size for bottom navigation labels (10.5 px).
  static const double fontSizeSm2 = 10.5;

  // ──────────────── Misc Component Tokens ────────────────

  /// Default thumbnail size for document/image loading indicators.
  static const double thumbnailDefault = 20.0;

  /// Thin stroke width for compact progress indicators.
  static const double strokeWidthThin = 2.0;

  /// Top offset for centering empty-state placeholder views vertically.
  static const double emptyStateTopOffset = 120.0;

  /// Drag handle width for bottom sheet cosmetic indicator.
  static const double handleWidth = 32.0;

  /// Drag handle height for bottom sheet cosmetic indicator.
  static const double handleHeight = 4.0;

  /// Maximum height constraint for doctor dropdown overlay lists.
  static const double overlayDropdownMaxHeight = 220.0;
}
