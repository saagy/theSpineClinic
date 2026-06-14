/// An interactive pill-shaped chip with smooth animated transitions.
///
/// Two variants:
/// - [AppFilterChipVariant.filled]: solid teal fill + white text (active filter).
/// - [AppFilterChipVariant.outlined]: white fill + teal border + teal text
///   (sort toggles, secondary selectors).
///
/// Designed for horizontal chip rows and inline filter bars.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Visual variant for [AppFilterChip].
enum AppFilterChipVariant {
  /// Solid teal fill, white text, subtle shadow.
  filled,

  /// White fill, teal border, teal text — always "active" appearance
  /// but outlined instead of solid.
  outlined,
}

/// A pill-shaped chip for filtering and sorting.
class AppFilterChip extends StatelessWidget {
  /// Creates an [AppFilterChip].
  const AppFilterChip({
    super.key,
    required this.label,
    this.variant = AppFilterChipVariant.filled,
    this.isActive = false,
    this.onTap,
    this.showShadow = true,
  });

  /// The chip's display text.
  final String label;

  /// The visual variant. Ignored when [isActive] is false (inactive
  /// chips always render as plain outlined).
  final AppFilterChipVariant variant;

  /// Whether this chip is in its active state.
  final bool isActive;

  /// Called when the chip is tapped.
  final VoidCallback? onTap;

  /// Whether to show a subtle shadow when active (filled variant only).
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final bool outlined = variant == AppFilterChipVariant.outlined;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final TextStyle textStyle;

    if (isActive && !outlined) {
      bgColor = AppColors.primary;
      borderColor = AppColors.primary;
      textColor = AppColors.textOnPrimary;
      textStyle = AppTextStyles.captionBold;
    } else if (isActive && outlined) {
      bgColor = AppColors.surface;
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
      textStyle = AppTextStyles.captionBold;
    } else {
      bgColor = AppColors.surface;
      borderColor = AppColors.border;
      textColor = AppColors.textSecondary;
      textStyle = AppTextStyles.captionMedium;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p8,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppSizes.borderRadiusPill,
          border: Border.all(
            color: borderColor,
            width: AppSizes.borderWidth,
          ),
          boxShadow: isActive && !outlined && showShadow
              ? [AppColors.cardShadow]
              : null,
        ),
        child: Text(label, style: textStyle.copyWith(color: textColor)),
      ),
    );
  }
}
