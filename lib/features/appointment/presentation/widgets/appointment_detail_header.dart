/// Compact patient header block for the appointment detail screen.
///
/// Row: compact avatar | patient name + clinic label | chevron.
/// Tappable to PatientDetailScreen, gated by [appointmentPatientAccessProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_appointment_access.dart';
import 'package:spine_clinic_app/features/patient/presentation/appointment_patient_access_provider.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

/// Compact tappable patient identity block.
class AppointmentDetailHeader extends ConsumerWidget {
  const AppointmentDetailHeader({
    super.key,
    required this.appointment,
    required this.patient,
  });
  final Appointment appointment;
  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PatientAppointmentAccess> accessAsync =
        ref.watch(appointmentPatientAccessProvider(appointment));
    final bool enabled =
        accessAsync.maybeWhen(data: (a) => a is Granted, orElse: () => true);

    final String tooltip = accessAsync.maybeWhen(
      data: (a) => switch (a) {
        Granted() => '',
        AccessExpired() => AppStrings.patientPillAccessExpired,
        NotAuthenticated() => AppStrings.patientPillAccessNotAuthenticated,
      },
      orElse: () => '',
    );

    final VoidCallback? onTap = enabled
        ? () => context.push('/patient/${patient.id}')
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p24,
            vertical: AppSizes.p12,
          ),
          child: Tooltip(
            message: tooltip,
            triggerMode: TooltipTriggerMode.tap,
            child: InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
              child: Opacity(
                opacity: enabled ? 1.0 : 0.55,
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
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: AppSizes.p2),
                            Text(
                              patient.clinic.displayLabel,
                              style: AppTextStyles.captionMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.p8),
                      if (enabled)
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textMuted, size: AppSizes.iconDefault)
                      else
                        const Icon(Icons.lock_outline_rounded,
                            color: AppColors.textMuted, size: AppSizes.iconDefault),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ],
    );
  }
}
