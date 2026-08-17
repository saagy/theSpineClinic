import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_replacement_modal.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/replacement_day_picker_sheet.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_adaptive_modal.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/unified_filter_sheet.dart';

abstract final class ReceptionistTodayActions {
  static Future<void> showFilter(
    BuildContext context,
    WidgetRef ref,
    ReceptionistAppointmentsState state,
  ) async {
    final ReceptionistAppointmentsNotifier notifier = ref.read(
      receptionistAppointmentsProvider.notifier,
    );
    await AppBottomSheet.show<void>(
      context: context,
      title: AppStrings.filters,
      initialChildSize: AppSizes.sheetMax,
      builder: (BuildContext sheetContext, ScrollController controller) =>
          UnifiedFilterSheet(
            initialDoctorId: state.filterDoctorId,
            initialClinic: null,
            showBranchFilter: false,
            scrollController: controller,
            onApplied: (String? doctorId, _) {
              notifier.setDoctorFilter(doctorId);
              Navigator.of(sheetContext).pop();
            },
            onReset: () => notifier.setDoctorFilter(null),
          ),
    );
  }

  static Future<void> replaceDoctor(
    BuildContext context,
    WidgetRef ref,
    ReceptionistAppointmentsState state,
  ) async {
    String? chosenDoctorId;
    await AppBottomSheet.show<void>(
      context: context,
      title: AppStrings.selectAbsentDoctor,
      builder: (BuildContext sheetContext, ScrollController controller) =>
          UnifiedFilterSheet(
            initialDoctorId: null,
            initialClinic: null,
            showBranchFilter: false,
            showActions: false,
            scrollController: controller,
            onApplied: (String? doctorId, _) {
              chosenDoctorId = doctorId;
              Navigator.of(sheetContext).pop();
            },
          ),
    );
    if (chosenDoctorId == null || !context.mounted) return;

    final List<Staff> doctors = await ref.read(
      allDoctorsForFilterProvider.future,
    );
    final Staff? absentDoctor = doctors
        .where((Staff doctor) => doctor.id == chosenDoctorId)
        .firstOrNull;
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
        final bool? success = await AppAdaptiveModal.show<bool>(
          context: context,
          child: DoctorReplacementModal(
            absentDoctor: absentDoctor,
            availableDoctors: doctors
                .where((Staff doctor) => doctor.id != absentDoctor.id)
                .toList(),
            appointments: items,
            day: start,
            onSubmit:
                (List<String> replacementIds, List<String> appointmentIds) =>
                    ref
                        .read(appointmentRepositoryProvider)
                        .bulkReplaceDoctor(
                          absentDoctorId: absentDoctor.id,
                          replacementDoctorIds: replacementIds,
                          appointmentIds: appointmentIds,
                          day: start,
                        ),
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
