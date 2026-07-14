/// Today tab content: search bar with filter & replace buttons, horizontal
/// week day picker, and daily time-sorted appointments list.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_replacement_modal.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_week_strip.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/replacement_day_picker_sheet.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_day_list.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_today_helpers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/shared/widgets/app_adaptive_modal.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
import 'package:spine_clinic_app/shared/widgets/unified_filter_sheet.dart';

/// The receptionist dashboard schedule tab content.
class ReceptionistTodayTab extends ConsumerWidget {
  /// Creates a [ReceptionistTodayTab].
  const ReceptionistTodayTab({
    super.key,
    required this.state,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onStatusChanged,
  });

  final ReceptionistAppointmentsState state;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;
  final VoidCallback onStatusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loading) {
      return const SkeletonTileList(count: 5);
    }
    if (state.error != null) {
      return _buildErrorState(context);
    }

    final user = ref.watch(currentUserProvider).value;
    final bool canReplace = user?.isActive == true &&
        (user?.role == UserRole.receptionist ||
            user?.role == UserRole.superAdmin);

    final String? filterDoctorId = state.filterDoctorId;
    String? filterDoctorName;
    if (filterDoctorId != null) {
      final doctors = ref.watch(allDoctorsForFilterProvider).value ?? [];
      final doctor = doctors.cast<Staff?>().firstWhere(
            (d) => d?.id == filterDoctorId,
            orElse: () => null,
          );
      filterDoctorName = doctor?.fullName;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TodaySearchField(onChanged: onSearchChanged),
            ),
            IconButton.filledTonal(
              onPressed: () => _showFilterSheet(context, ref),
              icon: const Icon(Icons.filter_list_rounded),
              tooltip: AppStrings.filters,
            ),
            const SizedBox(width: AppSizes.p8),
            if (canReplace) ...[
              IconButton.filledTonal(
                onPressed: () => _handleDoctorReplacement(context, ref),
                icon: const Icon(Icons.swap_horiz_rounded),
                tooltip: AppStrings.replaceDoctor,
              ),
              const SizedBox(width: AppSizes.p16),
            ],
          ],
        ),
        if (filterDoctorId != null)
          ActiveFilterChipsRow(
            chips: [
              ActiveFilterChip(
                label: filterDoctorName ?? AppStrings.unknownDoctorFallback,
                onRemove: () => ref
                    .read(receptionistAppointmentsProvider.notifier)
                    .setDoctorFilter(null),
              ),
            ],
            onClearAll: () => ref
                .read(receptionistAppointmentsProvider.notifier)
                .setDoctorFilter(null),
          ),
        DoctorWeekStrip(
          dayCounts: state.dayAppointmentCounts,
          selectedDate: state.selectedDate,
          onDateSelected: (date) {
            ref.read(receptionistAppointmentsProvider.notifier).selectDate(date);
          },
        ),
        Expanded(
          child: ReceptionistDayList(
            state: state,
            searchQuery: searchQuery,
            onStatusChanged: onStatusChanged,
            onRefresh: () async => onRefresh(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final Object error = state.error!;
    final AppException ex = error is AppException
        ? error
        : UnknownException(message: '$error');
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () async => onRefresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: ErrorView(exception: ex, onRetry: onRefresh),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterSheet(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(receptionistAppointmentsProvider.notifier);
    await AppBottomSheet.show<void>(
      context: context,
      title: AppStrings.filters,
      builder: (sheetContext, scrollController) => UnifiedFilterSheet(
        initialDoctorId: state.filterDoctorId,
        initialClinic: null,
        showBranchFilter: false,
        scrollController: scrollController,
        onApplied: (doctorId, _) {
          notifier.setDoctorFilter(doctorId);
          Navigator.of(sheetContext).pop();
        },
        onReset: () {
          notifier.setDoctorFilter(null);
        },
      ),
    );
  }

  Future<void> _handleDoctorReplacement(BuildContext context, WidgetRef ref) async {
    String? chosenDoctorId;
    await AppBottomSheet.show<void>(
      context: context,
      title: AppStrings.selectAbsentDoctor,
      builder: (sheetContext, scrollController) => UnifiedFilterSheet(
        initialDoctorId: null,
        initialClinic: null,
        showBranchFilter: false,
        showActions: false,
        scrollController: scrollController,
        onApplied: (doctorId, _) {
          chosenDoctorId = doctorId;
          Navigator.of(sheetContext).pop();
        },
      ),
    );

    if (chosenDoctorId == null || !context.mounted) return;

    final doctors = await ref.read(allDoctorsForFilterProvider.future);
    final Staff? absentDoctor = doctors.cast<Staff?>().firstWhere(
          (d) => d?.id == chosenDoctorId,
          orElse: () => null,
        );

    if (absentDoctor == null || !context.mounted) return;

    final DateTime defaultDay =
        state.selectedDate ?? DateTime.now();
    final DateTime? chosenDay = await ReplacementDayPickerSheet.show(
      context: context,
      absentDoctorName: absentDoctor.fullName,
      defaultDate: defaultDay,
    );
    if (chosenDay == null || !context.mounted) return;

    final DateTime start = DateTime(
      chosenDay.year,
      chosenDay.month,
      chosenDay.day,
    );
    final DateTime end = start.add(const Duration(days: 1));
    final String clinic = ref.read(activeBranchProvider).dbValue;

    final Result<List<AppointmentWithPatient>> result = await ref
        .read(appointmentRepositoryProvider)
        .getAllAppointments(
          dateFrom: start,
          dateTo: end,
          doctorId: absentDoctor.id,
          clinic: clinic,
          offset: 0,
          limit: 500,
          ascending: true,
        );

    if (!context.mounted) return;

    result.when(
      success: (items) async {
        if (items.isEmpty) {
          AppSnackbar.show(
            context,
            message: AppStrings.noAffectedAppointments,
            variant: AppSnackbarVariant.info,
          );
          return;
        }
        final List<Staff> availableDoctors = doctors
            .where((d) => d.id != absentDoctor.id)
            .toList();

        final success = await AppAdaptiveModal.show<bool>(
          context: context,
          child: DoctorReplacementModal(
            absentDoctor: absentDoctor,
            availableDoctors: availableDoctors,
            appointments: items,
            day: start,
            onSubmit: (replacementDoctorIds, appointmentIds) => ref
                .read(appointmentRepositoryProvider)
                .bulkReplaceDoctor(
                  absentDoctorId: absentDoctor.id,
                  replacementDoctorIds: replacementDoctorIds,
                  appointmentIds: appointmentIds,
                  day: start,
                ),
          ),
        );

        if (success == true && context.mounted) {
          ref.read(receptionistAppointmentsProvider.notifier).loadToday();
        }
      },
      failure: (error) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(error.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
  }
}
