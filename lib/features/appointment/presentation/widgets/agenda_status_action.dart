import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/agenda_status_controller.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/reason_dialog.dart';

const _t = AppStrings.visit;

/// Payment staff and the admin may change an outcome recorded on an earlier
/// day (the database enforces the same rule).
bool canOverrideVisitOutcome(Staff? user) => user != null && user.isActive && user.canHandlePayments;

/// Whether [user] may change [appointment]'s recorded outcome now.
bool canChangeVisitOutcome(Appointment appointment, Staff? user) =>
    !appointment.outcomeLocked() || canOverrideVisitOutcome(user);

/// A visit's day has come, so its outcome can be recorded.
bool visitDayHasCome(Appointment appointment) =>
    !DateUtils.dateOnly(appointment.scheduledAt.toLocal()).isAfter(DateUtils.dateOnly(DateTime.now()));

/// Records [status] for [appointment]. An outcome from an earlier day needs a
/// reason, asked for here. Returns the result, or null when nothing was sent.
Future<bool?> changeVisitStatus(
  BuildContext context,
  WidgetRef ref, {
  required Appointment appointment,
  required AppointmentStatus status,
  bool showSuccess = true,
}) async {
  String? reason;
  if (appointment.outcomeLocked()) {
    if (!canOverrideVisitOutcome(ref.read(currentUserProvider).value)) {
      AppSnackbar.show(context, message: _t.lockedForDesk, variant: AppSnackbarVariant.error);
      return null;
    }
    reason = await showReasonDialog(
      context,
      title: _t.reasonTitle,
      message: _t.reasonMessage,
      label: _t.reasonLabel,
      hint: _t.reasonHint,
      requiredMessage: _t.reasonRequired,
      confirmLabel: _t.saveChange,
      cancelLabel: _t.keepAsIs,
    );
    if (reason == null || !context.mounted) return null;
  }
  final result = await ref
      .read(agendaStatusControllerProvider(appointment.id).notifier)
      .update(appointment.patientId, status, reason: reason);
  if (!context.mounted || result == null) return null;
  return result.when(
    success: (_) {
      if (showSuccess) {
        AppSnackbar.show(
          context,
          message: AppStrings.statusUpdateSuccess,
          variant: AppSnackbarVariant.success,
        );
      }
      return true;
    },
    failure: (error) {
      AppSnackbar.show(
        context,
        message: AppStrings.fromKey(error.userMessageKey),
        variant: AppSnackbarVariant.error,
      );
      return false;
    },
  );
}
