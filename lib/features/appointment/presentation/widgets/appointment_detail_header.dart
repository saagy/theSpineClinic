/// Compact patient header block for the appointment detail screen.
///
/// Row: compact avatar | patient name + clinic label | chevron.
/// Tappable to PatientDetailScreen. Supabase RLS enforces patient access.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

/// Compact tappable patient identity block.
class AppointmentDetailHeader extends StatelessWidget {
  const AppointmentDetailHeader({super.key, required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context) {
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
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: AppSizes.p2),
                        Text(
                          patient.clinic.displayLabel,
                          style: AppTextStyles.captionMedium.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
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
            color: Theme.of(context).colorScheme.outlineVariant,
            height: 1.0,
            thickness: 0.5,
          ),
        ),
      ],
    );
  }
}
