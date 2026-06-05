import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_chip.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';

/// A custom form field for multi-selecting active doctors.
class DoctorMultiselectField extends FormField<List<Staff>> {
  /// Creates a [DoctorMultiselectField].
  DoctorMultiselectField({
    super.key,
    required List<Staff> initialValue,
    required void Function(List<Staff>) onSavedDoctors,
    super.validator,
  }) : super(
          initialValue: initialValue,
          onSaved: (value) => onSavedDoctors(value ?? []),
          builder: (FormFieldState<List<Staff>> state) {
            return _DoctorMultiselectFieldWidget(
              state: state,
            );
          },
        );
}

class _DoctorMultiselectFieldWidget extends ConsumerWidget {
  const _DoctorMultiselectFieldWidget({
    required this.state,
  });

  final FormFieldState<List<Staff>> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDoctors = ref.watch(activeDoctorsProvider);
    final selectedDoctors = state.value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.assignedDoctors,
              style: AppTextStyles.captionMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            asyncDoctors.when(
              data: (doctors) {
                if (doctors.isEmpty) return const SizedBox.shrink();
                return TextButton.icon(
                  onPressed: () => _showSelectionSheet(context, doctors),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add/Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
              loading: () => const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
              error: (_, __) => TextButton(
                onPressed: () => ref.invalidate(activeDoctorsProvider),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p6),
        if (selectedDoctors.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.p12,
              horizontal: AppSizes.p16,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
              border: Border.all(
                color: state.hasError ? AppColors.error : AppColors.border,
                width: AppSizes.borderWidth,
              ),
            ),
            child: Text(
              'No doctors assigned yet. Tap Add/Edit to select.',
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSizes.p8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
              border: Border.all(
                color: state.hasError ? AppColors.error : AppColors.border,
                width: AppSizes.borderWidth,
              ),
            ),
            child: Wrap(
              spacing: AppSizes.p8,
              runSpacing: AppSizes.p8,
              children: selectedDoctors.map((doctor) {
                return AppChip(
                  label: doctor.fullName,
                  onDeleted: () {
                    final updated = selectedDoctors.where((d) => d.id != doctor.id).toList();
                    state.didChange(updated);
                  },
                );
              }).toList(),
            ),
          ),
        if (state.hasError) ...[
          const SizedBox(height: AppSizes.p6),
          Text(
            state.errorText ?? '',
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  void _showSelectionSheet(BuildContext context, List<Staff> allDoctors) {
    final currentlySelected = state.value ?? [];

    AppBottomSheet.show(
      context: context,
      title: 'Select Doctors',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = allDoctors[index];
                    final isSelected = currentlySelected.any((d) => d.id == doctor.id);

                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(
                        doctor.fullName,
                        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        doctor.email,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      activeColor: AppColors.primary,
                      onChanged: (checked) {
                        setSheetState(() {
                          if (checked == true) {
                            currentlySelected.add(doctor);
                          } else {
                            currentlySelected.removeWhere((d) => d.id == doctor.id);
                          }
                        });
                        state.didChange(List.from(currentlySelected));
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSizes.p16),
            ],
          );
        },
      ),
    );
  }
}
