/// Custom metadata row widget matching the Spine Clinic styling tokens.
///
/// A high-density typography row used to display key-value pairs cleanly
/// across details, profiles, and summary widgets. Touch-neutral.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

/// A high-density key-value text row styled with Spine Clinic design tokens.
///
/// Two layout variants are supported:
/// - **Default** (space-between): label on the left, value right-aligned with
///   a minimum gap. Best for detail screens with short labels.
/// - **Fixed-label-width**: label column uses [AppSizes.labelColumnWidth].
///   Value flows naturally from the column edge. Used by profile screens.
class InfoRow extends StatelessWidget {
  /// Creates an [InfoRow] with the default space-between layout.
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.isMuted = false,
    this.useFixedLabelWidth = false,
  });

  /// Creates an [InfoRow] with a fixed-width label column (profile style).
  const InfoRow.fixedLabel({
    super.key,
    required this.label,
    required this.value,
    this.isMuted = false,
  }) : useFixedLabelWidth = true;

  /// The descriptive key of the metadata pair (e.g. 'Phone Number').
  final String label;

  /// The data value displayed (e.g. '+20 101...').
  final String value;

  /// If true, turns the value text down to AppColors.textMuted.
  final bool isMuted;

  /// When true, uses a fixed-width label column via [AppSizes.labelColumnWidth].
  final bool useFixedLabelWidth;

  @override
  Widget build(BuildContext context) {
    if (useFixedLabelWidth) {
      return _buildFixedLabelLayout(context);
    }
    return _buildSpaceBetweenLayout(context);
  }

  Widget _buildSpaceBetweenLayout(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color muted = ClinicColors.of(context).textMuted;
    final Color valueColor = isMuted ? muted : cs.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySecondary.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSizes.p16),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyBold.copyWith(color: valueColor),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedLabelLayout(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color muted = ClinicColors.of(context).textMuted;
    final Color valueColor = isMuted ? muted : cs.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppSizes.labelColumnWidth,
          child: Text(
            label,
            style: AppTextStyles.captionMedium.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(color: valueColor),
          ),
        ),
      ],
    );
  }
}
