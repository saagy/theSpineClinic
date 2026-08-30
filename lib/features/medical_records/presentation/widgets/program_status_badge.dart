library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';

/// Renders a status badge for a rehabilitation program.
class ProgramStatusBadge extends StatelessWidget {
  const ProgramStatusBadge({super.key, required this.status});

  final ProgramStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (color, label) = switch (status) {
      ProgramStatus.active => (cs.primary, AppStrings.programActive),
      ProgramStatus.completed => (
          cs.tertiary,
          AppStrings.programCompleted,
        ),
      ProgramStatus.archived => (
          cs.onSurfaceVariant.withAlpha(150),
          AppStrings.programArchived,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p10,
        vertical: AppSizes.p4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(AppSizes.r999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionBold.copyWith(color: color),
      ),
    );
  }
}
