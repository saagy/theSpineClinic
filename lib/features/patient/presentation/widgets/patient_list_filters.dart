/// Filter bar widget for the patient list screen with unified doctor picker.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_picker_sheet.dart';

/// Renders doctor and branch filter controls for the patient list.
class PatientListFilters extends ConsumerWidget {
  const PatientListFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(patientListProvider);
    final selectedDoctorId = ref.read(patientListProvider.notifier).currentDoctorFilter;
    final doctorsAsync = ref.watch(allDoctorsForFilterProvider);

    Staff? selectedDoctor;
    if (selectedDoctorId != null && doctorsAsync.hasValue) {
      selectedDoctor = doctorsAsync.value!
          .where((d) => d.id == selectedDoctorId)
          .firstOrNull;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      child: Row(
        children: [
          Expanded(
            child: _DoctorFilterTrigger(
              selectedDoctor: selectedDoctor,
              selectedDoctorId: selectedDoctorId,
            ),
          ),
          const SizedBox(width: AppSizes.p8),
          Expanded(child: _BranchFilterDropdown()),
        ],
      ),
    );
  }
}

class _DoctorFilterTrigger extends ConsumerWidget {
  const _DoctorFilterTrigger({
    required this.selectedDoctor,
    required this.selectedDoctorId,
  });

  final Staff? selectedDoctor;
  final String? selectedDoctorId;

  Future<void> _pickDoctor(BuildContext context, WidgetRef ref) async {
    final picked = await DoctorPickerSheet.showSingle(
      context: context,
      selectedDoctorId: selectedDoctorId,
      showAllOption: true,
      showDeactivated: true,
      title: AppStrings.filterByDoctor,
    );
    ref.read(patientListProvider.notifier).setDoctorFilter(picked?.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final hasDoctor = selectedDoctorId != null;
    final label = selectedDoctor?.fullName ?? (hasDoctor ? 'Loading...' : AppStrings.allDoctors);

    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
        side: BorderSide(
          color: hasDoctor ? cs.primary : cs.outlineVariant,
          width: AppSizes.borderWidth,
        ),
      ),
      child: InkWell(
        onTap: () => _pickDoctor(context, ref),
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
        child: SizedBox(
          height: AppSizes.inputHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
            child: Row(
              children: [
                Icon(
                  Icons.person_search_rounded,
                  size: AppSizes.iconSmall,
                  color: hasDoctor ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: AppSizes.p8),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.captionMedium.copyWith(
                      color: hasDoctor ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasDoctor)
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: AppSizes.iconSmall,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () => ref
                        .read(patientListProvider.notifier)
                        .setDoctorFilter(null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else
                  Icon(
                    Icons.unfold_more_rounded,
                    size: AppSizes.iconSmall,
                    color: cs.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BranchFilterDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(patientListProvider.notifier);
    final border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant,
        width: AppSizes.borderWidth,
      ),
    );
    return DropdownButtonFormField<ClinicLocation?>(
      initialValue: notifier.currentClinicFilter,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p8,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(
            color: ClinicColors.of(context).outlineStrong,
            width: AppSizes.borderWidthFocused,
          ),
        ),
      ),
      hint: Text(
        AppStrings.allBranches,
        style: AppTextStyles.captionMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      items: const [
        DropdownMenuItem<ClinicLocation?>(
          value: null,
          child: Text(AppStrings.allBranches),
        ),
        DropdownMenuItem<ClinicLocation?>(
          value: ClinicLocation.tagamoa,
          child: Text(AppStrings.clinicTagamoa),
        ),
        DropdownMenuItem<ClinicLocation?>(
          value: ClinicLocation.masrElgedida,
          child: Text(AppStrings.clinicMasrElgedida),
        ),
      ],
      onChanged: notifier.setClinicFilter,
    );
  }
}
