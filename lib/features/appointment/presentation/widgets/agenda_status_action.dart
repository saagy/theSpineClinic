import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/agenda_status_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

Future<void> updateAgendaStatus(
  BuildContext context,
  WidgetRef ref, {
  required String appointmentId,
  required String patientId,
  required AppointmentStatus status,
}) async {
  final result = await ref
      .read(agendaStatusControllerProvider(appointmentId).notifier)
      .update(patientId, status);
  if (!context.mounted || result == null) return;
  result.when(
    success: (_) {
      AppSnackbar.show(
        context,
        message: AppStrings.statusUpdateSuccess,
        variant: AppSnackbarVariant.success,
      );
    },
    failure: (error) => AppSnackbar.show(
      context,
      message: AppStrings.fromKey(error.userMessageKey),
      variant: AppSnackbarVariant.error,
    ),
  );
}
