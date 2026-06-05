/// Header section for the appointment detail screen.
///
/// Renders the patient name (tappable → PatientDetailScreen),
/// clinic badge, and appointment status badge.
///
/// Rule 1 — extracted sub-widget to keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';

/// Displays the patient identity and appointment status header.
class AppointmentDetailHeader extends StatelessWidget {
  /// Creates an [AppointmentDetailHeader].
  const AppointmentDetailHeader({
    super.key,
    required this.appointment,
    required this.patient,
  });

  /// The appointment being displayed.
  final Appointment appointment;

  /// The resolved patient record.
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p24,
        vertical: AppSizes.p16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient name — tappable link to PatientDetailScreen
          GestureDetector(
            onTap: () => context.push('/patient/${patient.id}'),
            child: Text(
              patient.fullName,
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p12),
          // Badges row: clinic + status
          Row(
            children: [
              AppBadge(
                label: patient.clinic.displayLabel,
                textColor: AppColors.info,
                backgroundColor: AppColors.infoBg,
              ),
              const SizedBox(width: AppSizes.p8),
              AppBadge(
                label: appointment.status.displayLabel,
                textColor: appointment.status.textColor,
                backgroundColor: appointment.status.backgroundColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
