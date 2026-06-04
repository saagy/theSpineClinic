/// Custom badge widget matching the Spine Clinic styling tokens.
///
/// A polymorphic colored label container widget designed to replace StatusBadge,
/// TypeBadge, and ClinicBadge. Flat design, touch-neutral.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A scannable, compact visual badge styled with Spine Clinic design tokens.
class AppBadge extends StatelessWidget {
  /// Creates an [AppBadge].
  const AppBadge({
    super.key,
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  /// The text content displayed inside the badge.
  final String label;

  /// Foreground text color.
  final Color textColor;

  /// Background container color.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Fits tightly around text, no horizontal expansion
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r4)), // Strict r4 micro-pill radius
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8, // 8px horizontal padding
        vertical: AppSizes.p4,   // 4px vertical padding
      ),
      child: Text(
        label,
        style: AppTextStyles.captionBold.copyWith(
          color: textColor,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
