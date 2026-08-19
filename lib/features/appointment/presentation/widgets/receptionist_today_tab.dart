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
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_week_strip.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_day_list.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_today_actions.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_today_helpers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

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
    final user = ref.watch(currentUserProvider).value;
    final bool canReplace =
        user?.isActive == true &&
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
        child: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (_, __) => <Widget>[
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Container(
                    key: const ValueKey<String>(
                      'receptionist-schedule-toolbar',
                    ),
                    child: Column(
                      children: [
                        TodaySearchField(
                          onChanged: onSearchChanged,
                          onFilterPressed: () =>
                              ReceptionistTodayActions.showFilter(
                                context,
                                ref,
                                state,
                              ),
                          isFilterActive: filterDoctorId != null,
                          canReplace: canReplace,
                          onReplacePressed: () =>
                              ReceptionistTodayActions.replaceDoctor(
                                context,
                                ref,
                                state,
                              ),
                        ),
                        if (filterDoctorId != null)
                          ActiveFilterChipsRow(
                            chips: [
                              ActiveFilterChip(
                                label:
                                    filterDoctorName ??
                                    AppStrings.unknownDoctorFallback,
                                onRemove: () => ref
                                    .read(
                                      receptionistAppointmentsProvider
                                          .notifier,
                                    )
                                    .setDoctorFilter(null),
                              ),
                            ],
                            onClearAll: () => ref
                                .read(
                                  receptionistAppointmentsProvider
                                      .notifier,
                                )
                                .setDoctorFilter(null),
                          ),
                      ],
                    ),
                  ),
                  DoctorWeekStrip(
                    dayCounts: state.dayAppointmentCounts,
                    selectedDate: state.selectedDate,
                    onDateSelected: (date) {
                      ref
                          .read(receptionistAppointmentsProvider.notifier)
                          .selectDate(date);
                    },
                  ),
                ],
              ),
            ),
          ],
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (c, a) =>
                FadeTransition(opacity: a, child: c),
            child: state.loading
                ? const KeyedSubtree(
                    key: ValueKey('today_loading'),
                    child: SkeletonTileList(count: 5),
                  )
                : state.error != null
                ? KeyedSubtree(
                    key: const ValueKey('today_error'),
                    child: _buildErrorState(context),
                  )
                : KeyedSubtree(
                    key: ValueKey(
                      'today_data_${state.selectedDate}_${state.itemsForSelectedDay.length}',
                    ),
                    child: ReceptionistDayList(
                      state: state,
                      searchQuery: searchQuery,
                      onStatusChanged: onStatusChanged,
                      onToggleCancelled: () => ref
                          .read(receptionistAppointmentsProvider.notifier)
                          .toggleShowCancelled(),
                      onRefresh: () async => onRefresh(),
                    ),
                  ),
          ),
        ),
      ),
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
}
