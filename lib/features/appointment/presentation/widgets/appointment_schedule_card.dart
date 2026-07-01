import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';

/// Segment showing date, time, type, and package usage in a 2-column layout.
class AppointmentScheduleCard extends StatelessWidget {
  const AppointmentScheduleCard({super.key, required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final labelStyle = AppTextStyles.captionMedium.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      fontSize: 10,
      letterSpacing: 1.0,
    );

    final valueStyle = AppTextStyles.headingSmall.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

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
              // Column 1: Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DATE',
                      style: labelStyle,
                    ),
                    const SizedBox(height: AppSizes.p4),
                    Text(
                      Formatters.formatDateMedium(appointment.scheduledAt),
                      style: valueStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p24),
              // Column 2: Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIME',
                      style: labelStyle,
                    ),
                    const SizedBox(height: AppSizes.p4),
                    Text(
                      Formatters.formatTime(appointment.scheduledAt),
                      style: valueStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Treatment
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.visitType.toUpperCase(),
                      style: labelStyle,
                    ),
                    const SizedBox(height: AppSizes.p6),
                    Text(
                      appointment.type.displayLabel,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p24),
              // Column 2: Package Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PACKAGE STATUS',
                      style: labelStyle,
                    ),
                    const SizedBox(height: AppSizes.p6),
                    appointment.usePackage
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Using Package',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'No Package',
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p16),
          Divider(color: colorScheme.outlineVariant, height: 1.0, thickness: 0.5),
        ],
      ),
    );
  }
}
