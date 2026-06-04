/// Custom chip (token) widget matching the Spine Clinic styling tokens.
///
/// An interactive entity token widget designed to handle item representation
/// (e.g. doctor assignments, tags, active filters). Touch-only.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A compact pill chip styled with Spine Clinic design tokens.
class AppChip extends StatelessWidget {
  /// Creates an [AppChip].
  const AppChip({
    super.key,
    required this.label,
    this.onDeleted,
  });

  /// The text content displayed inside the chip.
  final String label;

  /// Optional callback to delete/remove the chip.
  /// If provided, renders a trailing close cross button.
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final bool hasDelete = onDeleted != null;

    return Container(
      // Fits tightly, no horizontal stretching
      decoration: BoxDecoration(
        color: AppColors.background, // Slate 50 neutral fill
        borderRadius: const BorderRadius.all(Radius.circular(100)), // Full pill roundness
        border: Border.all(
          color: AppColors.border, // Slate 200 crisp lines
          width: AppSizes.borderWidth,
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSizes.p12,
        right: hasDelete ? AppSizes.p8 : AppSizes.p12, // Optical balance adjustment
        top: AppSizes.p4,
        bottom: AppSizes.p4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Token string text
          Text(
            label,
            style: AppTextStyles.captionMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (hasDelete) ...[
            const SizedBox(width: AppSizes.p4),
            // Isolated GestureDetector for independent touch target bounds
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDeleted,
              child: const Padding(
                padding: EdgeInsets.all(AppSizes.p2), // Expands tap boundary target
                child: Icon(
                  Icons.close,
                  size: 14.0, // Standard compact size
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
