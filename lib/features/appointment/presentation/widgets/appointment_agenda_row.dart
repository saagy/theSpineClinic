import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_with_patient.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart'
    show appointmentRepositoryProvider;
import 'package:spine_clinic_app/features/appointment/presentation/appointment_refresh.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row_compact.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row_wide.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Responsive appointment agenda row: 1 line on PC/wide (>=650px),
/// 2 compact lines on mobile (<650px).
class AppointmentAgendaRow extends ConsumerStatefulWidget {
  const AppointmentAgendaRow({
    super.key,
    required this.item,
    this.showDoctor = true,
    this.onStatusChanged,
  });

  final AppointmentWithPatient item;
  final bool showDoctor;
  final VoidCallback? onStatusChanged;

  @override
  ConsumerState<AppointmentAgendaRow> createState() => _AppointmentAgendaRowState();
}

class _AppointmentAgendaRowState extends ConsumerState<AppointmentAgendaRow> {
  bool _isCheckingIn = false;

  Future<void> _checkIn() async {
    if (_isCheckingIn) return;
    setState(() => _isCheckingIn = true);

    final id = widget.item.appointment.id;
    final patientId = widget.item.patient.id;
    ref.read(receptionistAppointmentsProvider.notifier).changeStatus(id, AppointmentStatus.checkedIn);
    ref.read(doctorScheduleProvider.notifier).changeStatus(id, AppointmentStatus.checkedIn);
    ref.read(allAppointmentsProvider.notifier).updateStatus(id, AppointmentStatus.checkedIn);
    ref.read(patientAppointmentsProvider(patientId).notifier).changeStatus(id, AppointmentStatus.checkedIn);

    final result = await ref.read(appointmentRepositoryProvider).updateAppointmentStatus(id, AppointmentStatus.checkedIn);
    if (!mounted) return;
    setState(() => _isCheckingIn = false);

    result.when(
      success: (_) {
        AppointmentRefresh.patientAndDashboards(ref, patientId: patientId);
        widget.onStatusChanged?.call();
        AppSnackbar.show(context, message: AppStrings.statusUpdateSuccess, variant: AppSnackbarVariant.success);
      },
      failure: (err) {
        ref.read(receptionistAppointmentsProvider.notifier).changeStatus(id, widget.item.appointment.status);
        ref.read(doctorScheduleProvider.notifier).changeStatus(id, widget.item.appointment.status);
        ref.read(allAppointmentsProvider.notifier).updateStatus(id, widget.item.appointment.status);
        AppSnackbar.show(context, message: AppStrings.fromKey(err.userMessageKey), variant: AppSnackbarVariant.error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final appt = item.appointment;
    final isCancelled = appt.status == AppointmentStatus.cancelled;
    final timeStr = DateFormat('h:mm a').format(appt.scheduledAt.toLocal());

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 650.0) {
          return AppointmentAgendaWideRow(
            item: item,
            timeStr: timeStr,
            isCancelled: isCancelled,
            isCheckingIn: _isCheckingIn,
            onCheckIn: _checkIn,
            showDoctor: widget.showDoctor,
            onStatusChanged: widget.onStatusChanged,
          );
        }

        return AppointmentAgendaCompactRow(
          item: item,
          timeStr: timeStr,
          isCancelled: isCancelled,
          isCheckingIn: _isCheckingIn,
          onCheckIn: _checkIn,
          showDoctor: widget.showDoctor,
          onStatusChanged: widget.onStatusChanged,
        );
      },
    );
  }
}
