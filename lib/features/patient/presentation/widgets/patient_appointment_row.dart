import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_actions_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';

/// Single row representing a patient appointment.
class PatientAppointmentRow extends ConsumerWidget {
  /// Creates a [PatientAppointmentRow].
  const PatientAppointmentRow({
    super.key,
    required this.appointment,
  });

  /// The appointment entity.
  final Appointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsDetailsAsync = ref.watch(appointmentDoctorsDetailsProvider(appointment.id));

    final String subtitle = doctorsDetailsAsync.when(
      data: (details) {
        if (details.isEmpty) {
          return 'No doctor assigned';
        }

        return details.map((detail) {
          final String doctorName = detail.doctor.fullName;
          if (detail.assignment.isReplacement && detail.replacedDoctor != null) {
            return '$doctorName (Covering ${detail.replacedDoctor!.fullName})';
          }
          return doctorName;
        }).join(', ');
      },
      loading: () => 'Loading doctors...',
      error: (_, __) => 'Error loading doctors',
    );

    return DataListTile(
      title: appointment.scheduledAt.toDateTimeString(),
      subtitle: subtitle,
      leading: AppBadge(
        label: appointment.type.displayLabel,
        textColor: appointment.type.textColor,
        backgroundColor: appointment.type.backgroundColor,
      ),
      trailing: AppBadge(
        label: appointment.status.displayLabel,
        textColor: appointment.status.textColor,
        backgroundColor: appointment.status.backgroundColor,
      ),
      onTap: () => showModalBottomSheet(
        context: context,
        builder: (_) => AppointmentActionsSheet(appointment: appointment),
      ),
    );
  }
}
