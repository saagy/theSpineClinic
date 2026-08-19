/// Card displaying schedule details (date, time, visit type, package status)
/// and any linked sessions on the same day.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_linked_session_row.dart';

/// Section card displaying appointment schedule information and linked sessions.
class AppointmentInfoCard extends StatelessWidget {
  const AppointmentInfoCard({
    super.key,
    required this.appointment,
    this.linkedAppointments = const <Appointment>[],
  });

  final Appointment appointment;
  final List<Appointment> linkedAppointments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final clinic = ClinicColors.of(context);

    final labelStyle = AppTextStyles.captionMedium.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      fontSize: 10,
      letterSpacing: 1.0,
    );

    final valueStyle = AppTextStyles.headingSmall.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p8,
      ),
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
        boxShadow: [clinic.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.date.toUpperCase(), style: labelStyle),
                    const SizedBox(height: AppSizes.p4),
                    Text(
                      Formatters.formatDateMedium(appointment.scheduledAt),
                      style: valueStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.time.toUpperCase(), style: labelStyle),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.visitType.toUpperCase(), style: labelStyle),
                    const SizedBox(height: AppSizes.p4),
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
              const SizedBox(width: AppSizes.p16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.packageStatus.toUpperCase(),
                      style: labelStyle,
                    ),
                    const SizedBox(height: AppSizes.p4),
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
                              const SizedBox(width: AppSizes.p6),
                              Text(
                                AppStrings.usingPackage,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            AppStrings.noPackage,
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
          if (linkedAppointments.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
              child: Divider(
                color: colorScheme.outlineVariant,
                height: 1.0,
                thickness: 0.5,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  color: colorScheme.secondary,
                  size: AppSizes.iconSmall,
                ),
                const SizedBox(width: AppSizes.p6),
                Text(
                  AppStrings.linkedSessions,
                  style: labelStyle.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p8),
            ...linkedAppointments.map(
              (linked) => AppointmentLinkedSessionRow(appointment: linked),
            ),
          ],
        ],
      ),
    );
  }
}
