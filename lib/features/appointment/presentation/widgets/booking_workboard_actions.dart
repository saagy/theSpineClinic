import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_provider.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_state.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_replacement_modal.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_adaptive_modal.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/unified_filter_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class BookingWorkboardActions {
  static void moveDay(WidgetRef ref, DateTime date, int days) {
    ref
        .read(bookingWorkboardProvider.notifier)
        .selectDate(date.add(Duration(days: days)));
  }

  static Future<void> chooseDate(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
  ) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: AppStrings.chooseDate,
    );
    if (selected != null) {
      await ref.read(bookingWorkboardProvider.notifier).selectDate(selected);
    }
  }

  static Future<void> showDoctorFilter(
    BuildContext context,
    WidgetRef ref,
    BookingWorkboardState state,
  ) {
    return AppBottomSheet.show<void>(
      context: context,
      title: AppStrings.filters,
      builder: (sheetContext, scrollController) => UnifiedFilterSheet(
        initialDoctorId: state.doctorId,
        initialClinic: null,
        showBranchFilter: false,
        scrollController: scrollController,
        onApplied: (doctorId, _) {
          ref.read(bookingWorkboardProvider.notifier).setDoctorFilter(doctorId);
          Navigator.of(sheetContext).pop();
        },
        onReset: () =>
            ref.read(bookingWorkboardProvider.notifier).setDoctorFilter(null),
      ),
    );
  }

  static Future<void> call(BuildContext context, Patient patient) async {
    final Uri uri = Uri(scheme: 'tel', path: patient.phoneNumber);
    final bool launched =
        await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched) return;
    await Clipboard.setData(ClipboardData(text: patient.phoneNumber));
    if (context.mounted) {
      AppSnackbar.show(context, message: AppStrings.phoneCopied);
    }
  }

  static Future<void> book(
    BuildContext context,
    WidgetRef ref,
    Patient patient,
    BookingWorkboardState state,
  ) async {
    final Map<String, String> queryParameters = {
      'patientId': patient.id,
      'date': _dateOnly(state.date),
      'dueDate': _dateOnly(patient.nextVisitDate!),
      if (state.doctorId != null) 'doctorId': state.doctorId!,
    };
    final Uri route = Uri(
      path: AppRoutes.newAppointment,
      queryParameters: queryParameters,
    );
    await context.push(route.toString());
    if (context.mounted) {
      await ref.read(bookingWorkboardProvider.notifier).refresh();
    }
  }

  static Future<void> remind(
    BuildContext context,
    WidgetRef ref,
    Patient patient,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: patient.nextVisitDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: AppStrings.remindLater,
    );
    if (date == null) return;
    final result = await ref
        .read(bookingWorkboardProvider.notifier)
        .updateNextVisit(patient.id, date);
    if (context.mounted) _showMutationResult(context, result);
  }

  static Future<void> stop(
    BuildContext context,
    WidgetRef ref,
    Patient patient,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.stopFollowUpTitle,
        message: AppStrings.stopFollowUpMessage,
        confirmLabel: AppStrings.stopFollowUp,
        isDestructive: true,
      ),
    );
    if (confirmed != true) return;
    final result = await ref
        .read(bookingWorkboardProvider.notifier)
        .updateNextVisit(patient.id, null);
    if (context.mounted) _showMutationResult(context, result);
  }

  static Future<void> replaceDoctor(
    BuildContext context,
    WidgetRef ref,
    Staff absentDoctor,
    List<Staff> doctors,
    BookingWorkboardState state,
  ) {
    final appointments = state.schedule
        .where((item) => item.appointment.status != AppointmentStatus.cancelled)
        .toList();
    final String absentDoctorId = absentDoctor.id;
    final DateTime day = state.date;
    return AppAdaptiveModal.show<bool>(
      context: context,
      child: DoctorReplacementModal(
        absentDoctor: absentDoctor,
        availableDoctors: doctors
            .where((doctor) => doctor.id != absentDoctorId)
            .toList(),
        appointments: appointments,
        day: day,
        onSubmit: (doctorIds, appointmentIds) => ref
            .read(bookingWorkboardProvider.notifier)
            .replaceDoctor(
              absentDoctorId: absentDoctorId,
              day: day,
              replacementDoctorIds: doctorIds,
              appointmentIds: appointmentIds,
            ),
      ),
    );
  }

  static void _showMutationResult(BuildContext context, Result<void> result) {
    result.when(
      success: (_) => AppSnackbar.show(
        context,
        message: AppStrings.nextVisitUpdated,
        variant: AppSnackbarVariant.success,
      ),
      failure: (error) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(error.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
