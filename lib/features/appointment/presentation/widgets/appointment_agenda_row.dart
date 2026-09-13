import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_with_patient.dart';
import 'package:spine_clinic_app/features/appointment/presentation/agenda_status_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row_compact.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row_wide.dart';

class AppointmentAgendaRow extends ConsumerWidget {
  const AppointmentAgendaRow({
    super.key,
    required this.item,
    this.showDoctor = true,
    this.patientContext = false,
    this.showDate = false,
  });
  final AppointmentWithPatient item;
  final bool showDoctor;
  final bool patientContext;
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appt = item.appointment;
    final pending = ref.watch(agendaStatusControllerProvider(appt.id)).pending;
    final time = DateFormat.jm().format(appt.scheduledAt.toLocal());
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppSizes.agendaWideBreakpoint &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
          return AppointmentAgendaWideRow(
            item: item,
            timeStr: time,
            isCancelled: appt.status == AppointmentStatus.cancelled,
            isCheckingIn: pending,
            showDoctor: showDoctor,
            patientContext: patientContext,
            showDate: showDate,
          );
        }
        return AppointmentAgendaCompactRow(
          item: item,
          timeStr: time,
          isCancelled: appt.status == AppointmentStatus.cancelled,
          isCheckingIn: pending,
          showDoctor: showDoctor,
          patientContext: patientContext,
          showDate: showDate,
        );
      },
    );
  }
}
