/// Compact patient header block for the appointment detail screen.
///
/// Displays patient identity, clinic branch, and next expected visit date.
/// Tappable to PatientDetailScreen.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

/// Compact tappable patient identity block with embedded next visit info and CTA.
class AppointmentDetailHeader extends StatelessWidget {
  const AppointmentDetailHeader({super.key, required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16,
            vertical: AppSizes.p12,
          ),
          child: InkWell(
            onTap: () => context.push(
              AppRoutes.patientDetail.replaceAll(':id', patient.id),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.p4),
              child: Row(
                children: [
                  AppAvatar(name: patient.fullName, radius: 20),
                  const SizedBox(width: AppSizes.p12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          patient.fullName,
                          style: AppTextStyles.headingSmall.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: AppSizes.p2),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: patient.clinic.displayLabel),
                              const TextSpan(text: '  ·  '),
                              if (patient.nextVisitDate != null)
                                TextSpan(
                                  text:
                                      '${AppStrings.nextVisit}: ${Formatters.formatDateMedium(patient.nextVisitDate!)} ↗',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              else
                                TextSpan(
                                  text: '+ ${AppStrings.setNextVisit} ↗',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          style: AppTextStyles.captionMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.p8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: ClinicColors.of(context).textMuted,
                    size: AppSizes.iconDefault,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
          child: Divider(
            color: colorScheme.outlineVariant,
            height: 1.0,
            thickness: 0.5,
          ),
        ),
      ],
    );
  }
}
