import 'package:flutter/material.dart';
import 'program_status_control.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';

class ProgramDetailHeader extends StatelessWidget {
  const ProgramDetailHeader({super.key, required this.program});
  final PatientProgram program;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = program.affectedRegions.isEmpty
        ? AppStrings.program
        : program.affectedRegions.map((r) => r.displayName).join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingLarge.copyWith(color: cs.onSurface)),
          const SizedBox(height: AppSizes.p6),
          Text(
            AppStrings.createdLabel(Formatters.formatDateMedium(program.createdAt)),
            style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSizes.p12),
          ProgramStatusControl(program: program),
        ],
      ),
    );
  }
}
