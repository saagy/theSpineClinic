import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_refresh.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_appointment_sort_option.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_appointment_filter_content.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';

/// User actions for [PatientTabAppointments] extracted to respect Rule 1.
class PatientAppointmentTabActions {
  const PatientAppointmentTabActions._();

  static Future<void> showSortSheet({
    required BuildContext context,
    required WidgetRef ref,
    required String patientId,
  }) async {
    final state = ref.read(patientAppointmentsProvider(patientId));
    final notifier = ref.read(patientAppointmentsProvider(patientId).notifier);
    final selected = await SortOptionsSheet.show<PatientAppointmentSortOption>(
      context: context,
      title: AppStrings.sortOptions,
      options: PatientAppointmentSortOption.values
          .map(
            (o) => SortOption(
              value: o,
              label: o.displayLabel,
              buttonLabel: o.buttonLabel,
            ),
          )
          .toList(),
      selected: state.sort,
    );
    if (selected != null) notifier.setSort(selected);
  }

  static void openFilterSheet(BuildContext context, String patientId) {
    AppBottomSheet.show(
      context: context,
      title: AppStrings.filters,
      initialChildSize: AppSizes.sheetMax,
      builder: (context, scrollController) => PatientAppointmentFilterContent(
        patientId: patientId,
        scrollController: scrollController,
      ),
    );
  }

  static Future<void> openNewAppointment({
    required BuildContext context,
    required WidgetRef ref,
    required String patientId,
  }) async {
    final route = '${AppRoutes.newAppointment}?patientId=$patientId';
    await context.push(route);
    AppointmentRefresh.patientAndDashboards(ref, patientId: patientId);
  }
}