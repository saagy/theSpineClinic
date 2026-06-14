/// Interactive header for the appointment detail screen.
///
/// Row: large initials avatar | patient name + micro-pills | chevron.
/// Fully tappable → PatientDetailScreen.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

/// Tappable patient identity block with avatar, name, badges, and chevron.
class AppointmentDetailHeader extends StatelessWidget {
  const AppointmentDetailHeader({
    super.key,
    required this.appointment,
    required this.patient,
  });
  final Appointment appointment;
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p24, vertical: AppSizes.p16),
      child: InkWell(
        onTap: () => context.push('/patient/${patient.id}'),
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p4),
          child: Row(
            children: [
              AppAvatar(name: patient.fullName, radius: 28),
              const SizedBox(width: AppSizes.p16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      patient.fullName,
                      style: AppTextStyles.headingLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 22),
                    ),
                    const SizedBox(height: AppSizes.p6),
                    Row(children: [
                      _Pill(
                        label: patient.clinic.displayLabel,
                        bg: AppColors.infoBg,
                        fg: AppColors.info,
                      ),
                      const SizedBox(width: AppSizes.p8),
                      _StatusPill(status: appointment.status),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: AppSizes.iconDefault),
            ],
          ),
        ),
      ),
    );
  }
}

/// Generic micro-pill for clinic / type badges.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12, vertical: AppSizes.p4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r24)),
      ),
      child: Text(label,
          style: AppTextStyles.captionMedium.copyWith(color: fg)),
    );
  }
}

/// Micro-pill with colour mapping per appointment status.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (status) {
      case AppointmentStatus.checkedIn:
        bg = AppColors.successBg;
        fg = AppColors.success;
      case AppointmentStatus.cancelled:
      case AppointmentStatus.noShow:
        bg = AppColors.errorBg;
        fg = AppColors.error;
      case AppointmentStatus.scheduled:
      case AppointmentStatus.completed:
        bg = AppColors.background;
        fg = AppColors.textSecondary;
    }
    return _Pill(label: status.displayLabel, bg: bg, fg: fg);
  }
}
