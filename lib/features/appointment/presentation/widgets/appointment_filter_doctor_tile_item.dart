/// Doctor item tile used inside the searchable doctor picker list.
library;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';

/// Renders a single selectable doctor option with monogram badge and checkmark.
class AppointmentFilterDoctorTileItem extends StatelessWidget {
  const AppointmentFilterDoctorTileItem({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.isAll = false,
    this.isInactive = false,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isAll;
  final bool isInactive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.r6),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.p8,
          horizontal: AppSizes.p8,
        ),
        child: Row(
          children: [
            if (!isAll) ...[
              PatientMonogramBadge(name: title, size: 28.0),
              const SizedBox(width: AppSizes.p10),
            ] else ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.users,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSizes.p10),
            ],
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: cs.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isInactive) ...[
                    const SizedBox(width: AppSizes.p6),
                    Text(
                      AppStrings.inactiveLabel,
                      style: AppTextStyles.caption.copyWith(color: cs.error),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.check, size: 18, color: cs.primary),
          ],
        ),
      ),
    );
  }
}
