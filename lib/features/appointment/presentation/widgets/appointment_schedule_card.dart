import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/shared/widgets/info_row.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Card showing date, time, type, and package usage for appointment details.
class AppointmentScheduleCard extends StatelessWidget {
  const AppointmentScheduleCard({super.key, required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: SectionCard(
        child: Column(
          children: [
            InfoRow(
              label: AppStrings.date,
              value: Formatters.formatDateMedium(appointment.scheduledAt),
            ),
            InfoRow(
              label: AppStrings.time,
              value: Formatters.formatTime(appointment.scheduledAt),
            ),
            InfoRow(
              label: AppStrings.type,
              value: appointment.type.displayLabel,
            ),
            InfoRow(
              label: AppStrings.usePackage,
              value: appointment.usePackage ? AppStrings.yes : AppStrings.no,
            ),
          ],
        ),
      ),
    );
  }
}
