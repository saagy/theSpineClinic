/// Custom empty state placeholder widget matching the Spine Clinic styling tokens.
///
/// Renders a centered icon and descriptive text when list queries or searches
/// return zero active records. Touch-neutral.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A centered layout placeholder for empty data states styled with design tokens.
class EmptyState extends StatelessWidget {
  /// Creates an [EmptyState].
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
  });

  /// The descriptive string explaining why the view is blank.
  final String message;

  /// The line-art icon indicating an empty data bucket state.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p24, // Standard phone margin horizontal padding
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Fits compact within vertical scroll space
          children: [
            // Enlarged line-art icon asset colored in AppColors.textMuted
            Icon(
              icon,
              size: 48.0,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSizes.p16), // 16px grid separation spacing
            // Typographically muted description string text
            Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
