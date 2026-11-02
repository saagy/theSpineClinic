/// Summary tile displaying current selected doctor or trigger to doctor picker.
library;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';

/// Doctor selector tile in the main appointment filter sheet.
class FilterDoctorField extends StatelessWidget {
  const FilterDoctorField({
    super.key,
    required this.selectedDoctorId,
    required this.doctors,
    required this.onTap,
  });

  final String? selectedDoctorId;
  final List<Staff> doctors;
  final VoidCallback onTap;

  String get _doctorSummary {
    if (selectedDoctorId == null) return AppStrings.filterAllDoctors;
    final doc = doctors.cast<Staff?>().firstWhere(
      (d) => d?.id == selectedDoctorId,
      orElse: () => null,
    );
    return doc?.fullName ?? AppStrings.filterAllDoctors;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasDoctor = selectedDoctorId != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.r8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p14, vertical: AppSizes.p12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withAlpha(100),
          borderRadius: BorderRadius.circular(AppSizes.r8),
          border: Border.all(color: cs.outlineVariant.withAlpha(120), width: AppSizes.borderWidth),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              LucideIcons.user,
              size: AppSizes.iconSmall,
              color: hasDoctor ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: AppSizes.p10),
            Expanded(
              child: Text(
                _doctorSummary,
                style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
              ),
            ),
            const SizedBox(width: AppSizes.p8),
            Icon(LucideIcons.chevron_right, size: AppSizes.iconSmall, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
