import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Extensible filter and sort options bar for patient search.
///
/// Designed to support additional filters and sorting parameters in the future.
class PatientSearchFilters extends StatelessWidget {
  /// Creates a [PatientSearchFilters].
  const PatientSearchFilters({
    required this.selectedClinic,
    required this.onClinicSelected,
    super.key,
  });

  /// Currently selected clinic filter option, or null for all.
  final ClinicLocation? selectedClinic;

  /// Callback when a clinic option is chosen.
  final ValueChanged<ClinicLocation?> onClinicSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _FilterChip(
                label: AppStrings.all,
                selected: selectedClinic == null,
                onTap: () => onClinicSelected(null),
              ),
              const SizedBox(width: AppSizes.p8),
              _FilterChip(
                label: AppStrings.clinicTagamoa,
                selected: selectedClinic == ClinicLocation.tagamoa,
                onTap: () => onClinicSelected(ClinicLocation.tagamoa),
              ),
              const SizedBox(width: AppSizes.p8),
              _FilterChip(
                label: AppStrings.clinicMasrElgedida,
                selected: selectedClinic == ClinicLocation.masrElgedida,
                onTap: () => onClinicSelected(ClinicLocation.masrElgedida),
              ),
            ],
          ),
          // Placeholder for future filter/sort rows (e.g., sorting dropdown or active status chips)
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p6,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: AppSizes.borderRadiusBadge,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: AppSizes.borderWidth,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
