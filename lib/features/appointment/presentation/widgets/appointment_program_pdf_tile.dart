/// Compact, responsive tile allowing doctors to preview and export the patient's
/// Clinical Program & Treatment Plan PDF.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/services/program_pdf_service.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

/// Lightweight tile displaying program report status and an on-demand PDF export action.
class AppointmentProgramPdfTile extends ConsumerWidget {
  const AppointmentProgramPdfTile({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAccessAsync = ref.watch(canAccessPatientProvider(patient.id));
    final bool canAccess = canAccessAsync.value ?? false;
    if (!canAccess) return const SizedBox.shrink();

    final programsAsync = ref.watch(patientProgramsProvider(patient.id));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final clinic = ClinicColors.of(context);

    final String subtitleText = programsAsync.maybeWhen(
      data: (programs) {
        if (programs.isEmpty) return AppStrings.noProgramsRecorded;
        final active = programs.firstWhere(
          (p) => p.status == ProgramStatus.active,
          orElse: () => programs.first,
        );
        final regionText = active.affectedRegions.isNotEmpty
            ? active.affectedRegions.map((r) => r.displayName).join(' & ')
            : AppStrings.rehabilitationProgram;
        final planName = active.activePlan?.planName;
        return planName != null ? '$regionText · $planName' : regionText;
      },
      orElse: () => AppStrings.clinicalAssessmentAndPlan,
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
        boxShadow: [clinic.cardShadow],
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface.withAlpha(0),
        child: InkWell(
          onTap: () => ProgramPdfService.exportProgramForPatient(
            context: context,
            ref: ref,
            patient: patient,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth >= 480;

                return Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(26),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppSizes.r12),
                        ),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: colorScheme.primary,
                        size: AppSizes.iconDefault,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppStrings.programReport,
                            style: AppTextStyles.headingSmall.copyWith(
                              fontSize: 15,
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSizes.p2),
                          Text(
                            subtitleText,
                            style: AppTextStyles.caption.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    if (isWide)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.p12,
                          vertical: AppSizes.p6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(20),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(AppSizes.r999),
                          ),
                          border: Border.all(
                            color: colorScheme.primary.withAlpha(60),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.picture_as_pdf_outlined,
                              size: AppSizes.iconSmall,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: AppSizes.p6),
                            Text(
                              AppStrings.exportPdf,
                              style: AppTextStyles.captionBold.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: AppSizes.p2),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      )
                    else
                      Icon(
                        Icons.picture_as_pdf_outlined,
                        color: colorScheme.primary,
                        size: AppSizes.iconDefault,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
