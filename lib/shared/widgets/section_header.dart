/// A clean section header with bold title on the left and an optional
/// teal action link on the right.
///
/// Used to introduce card groups, list sections, and form groupings.
/// No divider — cards themselves provide visual separation.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A section divider header with title and optional trailing action.
class SectionHeader extends StatelessWidget {
  /// Creates a [SectionHeader].
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.padding,
  });

  /// The bold section title displayed on the left.
  final String title;

  /// Optional teal action text (e.g. "See all", "Edit").
  final String? actionLabel;

  /// Called when the action text is tapped.
  final VoidCallback? onActionTap;

  /// Override the default horizontal padding.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSizes.p24,
            vertical: AppSizes.p12,
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.headingSmall,
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionLabel!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
