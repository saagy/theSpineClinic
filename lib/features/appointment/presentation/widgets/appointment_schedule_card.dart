import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';

/// Segment showing date, time, type, and package usage in a 2-column layout.
class AppointmentScheduleCard extends StatelessWidget {
  const AppointmentScheduleCard({super.key, required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p24,
        AppSizes.p16,
        AppSizes.p24,
        AppSizes.p8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Date & Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.formatDateMedium(appointment.scheduledAt),
                      style: AppTextStyles.headingSmall.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: AppSizes.p4),
                    Text(
                      appointment.type.displayLabel,
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p24),
              // Column 2: Time & Package
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.formatTime(appointment.scheduledAt),
                      style: AppTextStyles.headingSmall.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: AppSizes.p4),
                    Text(
                      appointment.usePackage ? 'Using Package' : 'No Package',
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p16),
          const Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ],
      ),
    );
  }
}
