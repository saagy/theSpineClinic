library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Reusable toggle card with optional expanded child for condition inputs.
class MedicalHistoryToggleCard extends StatelessWidget {
  const MedicalHistoryToggleCard({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.expandedChild,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? expandedChild;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(
          color: value ? cs.primary.withAlpha(80) : cs.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyBold.copyWith(
                  color: value ? cs.primary : cs.onSurface,
                ),
              ),
              Switch.adaptive(
                value: value,
                activeTrackColor: cs.primary,
                onChanged: onChanged,
              ),
            ],
          ),
          if (expandedChild != null) expandedChild!,
        ],
      ),
    );
  }
}
