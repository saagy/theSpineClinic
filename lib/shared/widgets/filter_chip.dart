/// An interactive pill-shaped chip with smooth animated transitions.
///
/// Two variants:
/// - [AppFilterChipVariant.filled]: solid primary fill + white text.
/// - [AppFilterChipVariant.outlined]: surface fill + primary border/text
///   (sort toggles, secondary selectors).
///
/// Designed for horizontal chip rows and inline filter bars.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

/// Visual variant for [AppFilterChip].
enum AppFilterChipVariant {
  /// Solid primary fill, white text, subtle shadow.
  filled,

  /// Surface fill, primary border/text — always "active" appearance
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
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final TextStyle textStyle;

    if (isActive && !outlined) {
      bgColor = cs.primary;
      borderColor = cs.primary;
      textColor = cs.onPrimary;
      textStyle = AppTextStyles.captionBold;
    } else if (isActive && outlined) {
      bgColor = cs.surface;
      borderColor = cs.primary;
      textColor = cs.primary;
      textStyle = AppTextStyles.captionBold;
    } else {
      bgColor = cs.surface;
      borderColor = cs.outline;
      textColor = cs.onSurfaceVariant;
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
          border: Border.all(color: borderColor, width: AppSizes.borderWidth),
          boxShadow: isActive && !outlined && showShadow
              ? [clinic.cardShadow]
              : null,
        ),
        child: Text(label, style: textStyle.copyWith(color: textColor)),
      ),
    );
  }
}
