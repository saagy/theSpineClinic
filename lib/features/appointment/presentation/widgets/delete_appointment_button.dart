/// Delete-appointment confirmation flow — callable from AppBar overflow menu.
///
/// Replaces the former full-width red pill widget. Same confirmation dialog,
/// same controller call, same snackbar, same pop — just triggered from a
/// menu item instead of a standalone button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/edit_appointment_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Returns `true` if the appointment was deleted, `false` if cancelled or failed.
Future<bool> deleteAppointmentWithConfirmation(
  BuildContext context,
  WidgetRef ref,
  Appointment appointment,
) async {
  if (appointment.status == AppointmentStatus.checkedIn ||
      appointment.status == AppointmentStatus.completed) {
    return false;
  }

  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => const ConfirmationDialog(
      title: AppStrings.deleteAppointment,
      message: AppStrings.deleteAppointmentWarning,
      isDestructive: true,
    ),
  );

  if (confirm != true) return false;

  final result = await ref
      .read(editAppointmentControllerProvider.notifier)
      .deleteAppointment(
        appointmentId: appointment.id,
        patientId: appointment.patientId,
      );

  if (!context.mounted) return false;

  bool success = false;
  result.when(
    success: (_) {
      success = true;
      AppSnackbar.show(
        context,
        message: AppStrings.appointmentDeleted,
        variant: AppSnackbarVariant.success,
      );
      context.pop();
    },
    failure: (e) {
      AppSnackbar.show(
        context,
        message: AppStrings.fromKey(e.userMessageKey),
        variant: AppSnackbarVariant.error,
      );
    },
  );
  return success;
}
