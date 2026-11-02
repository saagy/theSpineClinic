import 'package:flutter/material.dart';
import 'package:spine_clinic_app/shared/widgets/filter_sheet_frame.dart';
import 'package:spine_clinic_app/shared/widgets/filter_option_chip.dart';
import 'package:spine_clinic_app/shared/widgets/filter_doctor_field.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
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

  @override
  Widget build(BuildContext context) => FilterSheetBody(
    onReset: onReset,
    onApply: onApply,
    children: [
      const FilterSectionTitle(AppStrings.clinic),
      Wrap(
        spacing: AppSizes.p8,
        runSpacing: AppSizes.p8,
        children: [
          for (final clinic in <ClinicLocation?>[null, ...ClinicLocation.values])
            FilterOptionChip(
              label: clinic?.displayLabel ?? AppStrings.filterAllBranches,
              isSelected: selectedClinic == clinic,
              onTap: () => onClinicChanged(clinic),
            ),
        ],
      ),
      if (canFilterDoctor) ...[
        const SizedBox(height: AppSizes.p20),
        const FilterSectionTitle(AppStrings.assignedDoctors),
        FilterDoctorField(
          selectedDoctorId: selectedDoctorId,
          doctors: doctors,
          onTap: onOpenDoctorPicker,
        ),
      ],
      const SizedBox(height: AppSizes.p20),
      const FilterSectionTitle(AppStrings.sortOrder),
      PatientFilterSortList(selectedSort: selectedSort, onSortChanged: onSortChanged),
      const SizedBox(height: AppSizes.p20),
    ],
  );
}
