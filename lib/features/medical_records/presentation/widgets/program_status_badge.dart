library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';

/// Renders a status badge for a rehabilitation program.
class ProgramStatusBadge extends StatelessWidget {
  const ProgramStatusBadge({super.key, required this.status});

  final ProgramStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final clinic = ClinicColors.of(context);

    final (color, bgColor, label) = switch (status) {
      ProgramStatus.active => (
          cs.primary,
          cs.primary.withAlpha(25),
          AppStrings.programActive,
        ),
      ProgramStatus.completed => (
          clinic.success,
          clinic.successContainer,
          AppStrings.programCompleted,
        ),
      ProgramStatus.archived => (
          clinic.neutral,
          clinic.neutralContainer,
          AppStrings.programArchived,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p10,
        vertical: AppSizes.p4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.r999),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionBold.copyWith(color: color),
      ),
    );
  }
}
