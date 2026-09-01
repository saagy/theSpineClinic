library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_status_badge.dart';

/// Bottom sheet allowing a doctor to select a specific program to export or view.
class ProgramPickerBottomSheet extends StatelessWidget {
  const ProgramPickerBottomSheet({
    super.key,
    required this.programs,
    required this.scrollController,
  });

  final List<PatientProgram> programs;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView.separated(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p8,
        AppSizes.p16,
        AppSizes.p24,
      ),
      itemCount: programs.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.p12),
      itemBuilder: (context, index) {
        final program = programs[index];
        final title = program.affectedRegions.isNotEmpty
            ? program.affectedRegions.map((r) => r.displayName).join(' & ')
            : AppStrings.rehabilitationProgram;

        final isArchived = program.status == ProgramStatus.archived;
        final (cardBg, borderColor, borderWidth) = switch (program.status) {
          ProgramStatus.active => (
              cs.surfaceContainerLow,
              cs.primary.withAlpha(90),
              1.5,
            ),
          ProgramStatus.completed => (
              cs.surfaceContainerLow,
              cs.outlineVariant,
              1.0,
            ),
          ProgramStatus.archived => (
              cs.surfaceContainerLowest,
              cs.outlineVariant.withAlpha(120),
              1.0,
            ),
        };

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppSizes.r16),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Opacity(
            opacity: isArchived ? 0.82 : 1.0,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(program),
              borderRadius: BorderRadius.circular(AppSizes.r16),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.headingSmall.copyWith(
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSizes.p8),
                        ProgramStatusBadge(status: program.status),
                      ],
                    ),
                    const SizedBox(height: AppSizes.p8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: AppSizes.iconSmall,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSizes.p6),
                        Text(
                          Formatters.formatDateMedium(program.createdAt),
                          style: AppTextStyles.caption.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (program.activePlan != null) ...[
                          const SizedBox(width: AppSizes.p12),
                          Icon(
                            Icons.assignment_outlined,
                            size: AppSizes.iconSmall,
                            color: cs.primary,
                          ),
                          const SizedBox(width: AppSizes.p4),
                          Expanded(
                            child: Text(
                              program.activePlan!.planName,
                              style: AppTextStyles.captionBold.copyWith(
                                color: cs.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
