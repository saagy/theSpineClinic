import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_replacement_args.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/replacement_day_picker_sheet.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_picker_sheet.dart';

abstract final class ReceptionistTodayActions {
  static Future<void> showFilter(
    BuildContext context,
    WidgetRef ref,
    ReceptionistAppointmentsState state,
  ) async {
    final ReceptionistAppointmentsNotifier notifier = ref.read(
      receptionistAppointmentsProvider.notifier,
    );
    final picked = await DoctorPickerSheet.showSingle(
      context: context,
      selectedDoctorId: state.filterDoctorId,
      showAllOption: true,
      showDeactivated: true,
      title: AppStrings.filterByDoctor,
    );
    notifier.setDoctorFilter(picked?.id);
  }

  static Future<void> replaceDoctor(
    BuildContext context,
    WidgetRef ref,
    ReceptionistAppointmentsState state,
  ) async {
    final absentDoctor = await DoctorPickerSheet.showSingle(
      context: context,
      title: AppStrings.selectAbsentDoctor,
      showAllOption: false,
      showDeactivated: true,
    );
    if (absentDoctor == null || !context.mounted) return;

    final DateTime? chosenDay = await ReplacementDayPickerSheet.show(
      context: context,
      absentDoctorName: absentDoctor.fullName,
      defaultDate: state.selectedDate ?? DateTime.now(),
    );
    if (chosenDay == null || !context.mounted) return;

    final DateTime start = DateTime(
      chosenDay.year,
      chosenDay.month,
      chosenDay.day,
    );
    final Result<List<AppointmentWithPatient>> result = await ref
        .read(appointmentRepositoryProvider)
        .getAllAppointments(
          dateFrom: start,
          dateTo: start.add(const Duration(days: 1)),
          doctorId: absentDoctor.id,
          clinic: ref.read(activeBranchProvider).dbValue,
          offset: 0,
          limit: 500,
          ascending: true,
        );
    if (!context.mounted) return;

    await result.when(
      success: (List<AppointmentWithPatient> items) async {
        if (items.isEmpty) {
          AppSnackbar.show(
            context,
            message: AppStrings.noAffectedAppointments,
            variant: AppSnackbarVariant.info,
          );
          return;
        }
        final List<Staff> doctors =
            (await ref.read(activeDoctorsProvider.future));
        if (!context.mounted) return;
        final bool? success = await context.push<bool>(
          AppRoutes.doctorReplacementLocation(
            absentDoctorId: absentDoctor.id,
            date: start,
          ),
          extra: DoctorReplacementArgs(
            absentDoctor: absentDoctor,
            availableDoctors: doctors
                .where((Staff doctor) => doctor.id != absentDoctor.id)
                .toList(),
            appointments: items,
            day: start,
          ),
        );
        if (success == true && context.mounted) {
          await ref.read(receptionistAppointmentsProvider.notifier).loadToday();
        }
      },
      failure: (error) async => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(error.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
  }
}
