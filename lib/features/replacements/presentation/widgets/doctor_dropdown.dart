import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';

class DoctorDropdown extends StatelessWidget {
  const DoctorDropdown({
    required this.doctors,
    required this.selectedId,
    required this.hint,
    required this.onChanged,
    this.excludeId,
    super.key,
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
