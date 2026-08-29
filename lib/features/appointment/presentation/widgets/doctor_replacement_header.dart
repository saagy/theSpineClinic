import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';

import 'package:spine_clinic_app/shared/widgets/doctor_filter_tile.dart';

/// Top header section for doctor replacement with date summary,
/// doctor selector trigger, and selection counter.
class DoctorReplacementHeader extends StatelessWidget {
  const DoctorReplacementHeader({
    super.key,
    required this.day,
    required this.totalAppointments,
    required this.selectedCount,
    required this.selectedDoctor,
    required this.allSelected,
    required this.onChooseDoctor,
    required this.onSelectAllChanged,
  });

  final DateTime day;
  final int totalAppointments;
  final int selectedCount;
  final Staff? selectedDoctor;
  final bool allSelected;
  final VoidCallback onChooseDoctor;
  final ValueChanged<bool?> onSelectAllChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.replacementSummary(
              DateFormat('EEE, MMM d').format(day),
              totalAppointments,
            ),
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSizes.p16),
          DoctorFilterTile(
            selectedDoctor: selectedDoctor,
            placeholderText: AppStrings.selectReplacementDoctors,
            onTap: onChooseDoctor,
          ),
          const SizedBox(height: AppSizes.p16),
          Row(
            children: [
              Checkbox(
                value: allSelected,
                onChanged: onSelectAllChanged,
              ),
              const Text(AppStrings.selectAll, style: AppTextStyles.bodyBold),
              const Spacer(),
              Text(
                AppStrings.sectionCount(
                  AppStrings.affectedAppointments,
                  selectedCount,
                ),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
