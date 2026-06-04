/// Custom metadata row widget matching the Spine Clinic styling tokens.
///
/// A high-density typography row used to display key-value pairs cleanly
/// across details, profiles, and summary widgets. Touch-neutral.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A high-density key-value text row styled with Spine Clinic design tokens.
class InfoRow extends StatelessWidget {
  /// Creates an [InfoRow].
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.isMuted = false,
  });

  /// The descriptive key of the metadata pair (e.g. 'Phone Number').
  final String label;

  /// The data value displayed (e.g. '+20 101...').
  final String value;

  /// If true, turns the value text down to AppColors.textMuted.
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    // Resolve value text styling color
    final Color valueColor = isMuted ? AppColors.textMuted : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.p6, // Compact grid vertical cushioning
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start, // Align baselines to top on wrap
        children: [
          // Key label on the left edge
          Text(
            label,
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSizes.p16), // Guarantees a minimum horizontal spacing gap
          // Value text expands and wraps cleanly to the right edge
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyBold.copyWith(
                color: valueColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
