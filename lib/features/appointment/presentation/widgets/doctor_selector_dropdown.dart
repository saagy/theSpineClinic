import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';

/// A dropdown selector to select and assign doctors to an appointment.
class DoctorSelectorDropdown extends StatelessWidget {
  /// Creates a [DoctorSelectorDropdown].
  const DoctorSelectorDropdown({
    required this.activeDoctors,
    required this.selectedDoctors,
    required this.isEnabled,
    required this.onDoctorSelected,
    super.key,
  });

  /// The list of all active doctors.
  final List<Staff> activeDoctors;

  /// The list of currently selected/assigned doctors.
  final List<Staff> selectedDoctors;

  /// Whether the selector dropdown is active and enabled.
  final bool isEnabled;

  /// Callback when a doctor is selected.
  final ValueChanged<Staff> onDoctorSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Doctor',
          style: AppTextStyles.captionMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.p6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isEnabled ? AppColors.border : AppColors.border.withAlpha(128),
            ),
            borderRadius: AppSizes.borderRadiusInput,
            color: isEnabled ? AppColors.surface : AppColors.background,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: null, // Always null so it resets after selection
              isExpanded: true,
              hint: Text(
                isEnabled ? 'Select doctor to add...' : 'Select patient first',
                style: AppTextStyles.bodySecondary.copyWith(
                  color: isEnabled ? AppColors.textSecondary : AppColors.textMuted,
                ),
              ),
              style: AppTextStyles.body,
              dropdownColor: AppColors.surface,
              items: isEnabled
                  ? activeDoctors.map((Staff d) {
                      final isSelected = selectedDoctors.any((doc) => doc.id == d.id);
                      return DropdownMenuItem<String>(
                        value: d.id,
                        child: Text(
                          d.fullName + (isSelected ? ' (Selected)' : ''),
                          style: AppTextStyles.body.copyWith(
                            color: isSelected ? AppColors.textMuted : AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList()
                  : null,
              onChanged: isEnabled
                  ? (String? val) {
                      if (val == null) return;
                      final doctor = activeDoctors.firstWhere((d) => d.id == val);
                      onDoctorSelected(doctor);
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
