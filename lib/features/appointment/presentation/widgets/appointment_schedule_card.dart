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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p8,
                        vertical: AppSizes.p2,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.neutralBg,
                        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r4)),
                      ),
                      child: Text(
                        appointment.type.displayLabel,
                        style: AppTextStyles.captionBold.copyWith(
                          color: AppColors.neutral,
                          fontSize: 11,
                        ),
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
                    if (appointment.usePackage)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.p8,
                          vertical: AppSizes.p2,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.all(Radius.circular(AppSizes.r4)),
                        ),
                        child: Text(
                          'Using Package',
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                          ),
                        ),
                      )
                    else
                      Text(
                        'No Package',
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
