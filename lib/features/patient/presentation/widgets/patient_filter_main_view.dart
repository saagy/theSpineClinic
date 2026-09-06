import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_sort_options.dart';

/// Main page of the patient filter sheet showing branch chips, doctor summary tile, and sort radio rows.
class PatientFilterMainView extends StatelessWidget {
  const PatientFilterMainView({
    super.key,
    required this.selectedClinic,
    required this.selectedDoctorId,
    required this.selectedSort,
    required this.canFilterDoctor,
    required this.doctors,
    required this.onClinicChanged,
    required this.onOpenDoctorPicker,
    required this.onSortChanged,
    required this.onReset,
    required this.onApply,
  });

  final ClinicLocation? selectedClinic;
  final String? selectedDoctorId;
  final PatientSortOption selectedSort;
  final bool canFilterDoctor;
  final List<Staff> doctors;
  final ValueChanged<ClinicLocation?> onClinicChanged;
  final VoidCallback onOpenDoctorPicker;
  final ValueChanged<PatientSortOption> onSortChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;

  String get _doctorSummary {
    if (selectedDoctorId == null) return AppStrings.filterAllDoctors;
    final doc = doctors.cast<Staff?>().firstWhere((d) => d?.id == selectedDoctorId, orElse: () => null);
    return doc?.fullName ?? AppStrings.filterAllDoctors;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, cs),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(cs, AppStrings.clinic),
                _buildClinicOptions(cs),
                if (canFilterDoctor) ...[
                  const SizedBox(height: AppSizes.p20),
                  _buildSectionTitle(cs, AppStrings.assignedDoctors),
                  _buildDoctorTile(cs),
                ],
                const SizedBox(height: AppSizes.p20),
                _buildSectionTitle(cs, 'Sort Order'),
                PatientFilterSortList(selectedSort: selectedSort, onSortChanged: onSortChanged),
                const SizedBox(height: AppSizes.p20),
              ],
            ),
          ),
        ),
        _buildFooter(cs),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p16, AppSizes.p12, AppSizes.p8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(AppStrings.filtersButton, style: AppTextStyles.headingMedium.copyWith(color: cs.onSurface)),
          Row(
            children: [
              TextButton(
                onPressed: onReset,
                child: Text(AppStrings.resetFilters, style: AppTextStyles.bodyBold.copyWith(color: cs.primary)),
              ),
              IconButton(icon: const Icon(LucideIcons.x, size: 20), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ColorScheme cs, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.captionBold.copyWith(color: cs.onSurfaceVariant, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildClinicOptions(ColorScheme cs) {
    final clinics = <ClinicLocation?>[null, ClinicLocation.tagamoa, ClinicLocation.masrElgedida];
    return Wrap(
      spacing: AppSizes.p8,
      runSpacing: AppSizes.p8,
      children: clinics.map((c) {
        final isSelected = selectedClinic == c;
        return InkWell(
          onTap: () => onClinicChanged(c),
          borderRadius: BorderRadius.circular(AppSizes.r8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p8),
            decoration: BoxDecoration(
              color: isSelected ? cs.primaryContainer : cs.surfaceContainerHighest.withAlpha(120),
              borderRadius: BorderRadius.circular(AppSizes.r8),
              border: Border.all(color: isSelected ? cs.primary : cs.outlineVariant.withAlpha(100), width: AppSizes.borderWidth),
            ),
            child: Text(
              c == null ? AppStrings.filterAllBranches : c.displayLabel,
              style: AppTextStyles.captionBold.copyWith(color: isSelected ? cs.onPrimaryContainer : cs.onSurface),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDoctorTile(ColorScheme cs) {
    return InkWell(
      onTap: onOpenDoctorPicker,
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
            Row(
              children: [
                Icon(LucideIcons.user, size: 16, color: selectedDoctorId != null ? cs.primary : cs.onSurfaceVariant),
                const SizedBox(width: AppSizes.p10),
                Text(
                  _doctorSummary,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: cs.onSurface,
                    fontWeight: selectedDoctorId != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            Icon(LucideIcons.chevron_right, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant, width: AppSizes.borderWidth)),
      ),
      child: FilledButton(
        onPressed: onApply,
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size.fromHeight(44.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
        ),
        child: Text(AppStrings.applyFilters, style: AppTextStyles.bodyBold),
      ),
    );
  }
}
