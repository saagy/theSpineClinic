/// Step 1 widget for the replacement wizard — doctor selectors and date.
///
/// Renders absent/covering doctor dropdowns and a date picker.
/// Rule 1 — dedicated sub-file to keep main screen compact.
/// Rule 2 — no Supabase calls; reads from Riverpod providers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/replacements/presentation/manage_replacement_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Form collecting the absent doctor, covering doctor, and target date.
class ReplacementSetupForm extends ConsumerWidget {
  /// Creates a [ReplacementSetupForm].
  const ReplacementSetupForm({
    required this.state,
    required this.controller,
    super.key,
  });

  /// Current wizard state.
  final ManageReplacementState state;

  /// Controller reference for mutations.
  final ManageReplacementController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Staff>> doctorsAsync =
        ref.watch(activeDoctorsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.p16),
      child: SectionCard(
        title: AppStrings.initiateReplacement,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Absent Doctor Dropdown ──
            Text(AppStrings.absentDoctor, style: AppTextStyles.bodyBold),
            const SizedBox(height: AppSizes.p8),
            doctorsAsync.when(
              loading: () => const SizedBox(
                height: AppSizes.inputHeight,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
              error: (_, __) => Text(
                AppStrings.errorDatabaseGeneric,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: AppColors.error,
                ),
              ),
              data: (List<Staff> doctors) => _DoctorDropdown(
                doctors: doctors,
                selectedId: state.absentDoctorId,
                excludeId: state.coveringDoctorId,
                hint: AppStrings.selectAbsentDoctor,
                onChanged: controller.setAbsentDoctor,
              ),
            ),

            const SizedBox(height: AppSizes.p16),

            // ── Covering Doctor Dropdown ──
            Text(
              AppStrings.coveringDoctor,
              style: AppTextStyles.bodyBold,
            ),
            const SizedBox(height: AppSizes.p8),
            doctorsAsync.when(
              loading: () => const SizedBox(
                height: AppSizes.inputHeight,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
              error: (_, __) => Text(
                AppStrings.errorDatabaseGeneric,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: AppColors.error,
                ),
              ),
              data: (List<Staff> doctors) => _DoctorDropdown(
                doctors: doctors,
                selectedId: state.coveringDoctorId,
                excludeId: state.absentDoctorId,
                hint: AppStrings.selectCoveringDoctor,
                onChanged: controller.setCoveringDoctor,
              ),
            ),

            const SizedBox(height: AppSizes.p16),

            // ── Date Picker ──
            Text(
              AppStrings.replacementDate,
              style: AppTextStyles.bodyBold,
            ),
            const SizedBox(height: AppSizes.p8),
            _DatePickerTile(
              selectedDate: state.selectedDate,
              onDateSelected: controller.setDate,
            ),

            const SizedBox(height: AppSizes.p24),

            // ── Confirm Button ──
            AppButton(
              labelText: AppStrings.confirmReplacement,
              onPressed:
                  state.isSaving ? null : controller.confirmReplacement,
              isLoading: state.isSaving,
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable doctor dropdown that excludes a specific ID.
class _DoctorDropdown extends StatelessWidget {
  const _DoctorDropdown({
    required this.doctors,
    required this.selectedId,
    required this.hint,
    required this.onChanged,
    this.excludeId,
  });

  final List<Staff> doctors;
  final String? selectedId;
  final String? excludeId;
  final String hint;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final List<Staff> filtered = excludeId != null
        ? doctors.where((Staff d) => d.id != excludeId).toList()
        : doctors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: AppSizes.borderRadiusInput,
        color: AppColors.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          hint: Text(hint, style: AppTextStyles.bodySecondary),
          style: AppTextStyles.body,
          dropdownColor: AppColors.surface,
          items: filtered
              .map(
                (Staff d) => DropdownMenuItem<String>(
                  value: d.id,
                  child: Text(d.fullName, style: AppTextStyles.body),
                ),
              )
              .toList(),
          onChanged: (String? value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

/// Tappable date tile that opens a platform date picker.
class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 7)),
          lastDate: DateTime.now().add(const Duration(days: 90)),
        );
        if (picked != null) onDateSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p12,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: AppSizes.borderRadiusInput,
          color: AppColors.surface,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: AppSizes.iconDefault,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSizes.p12),
            Text(
              Formatters.formatDateMedium(selectedDate),
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }
}
