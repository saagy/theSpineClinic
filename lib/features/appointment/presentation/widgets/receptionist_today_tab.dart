import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_table_header.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_week_strip.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_day_list.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/schedule_filter_sheet.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/schedule_toolbar.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// The receptionist dashboard schedule tab content.
///
/// Implements a clean 3-layer architecture:
/// 1. Header context & CTA (screen level)
/// 2. Date Navigation with week strip and Show/Hide Cancelled quick toggle
/// 3. Search & Filter toolbar matching the Patients directory design
///
/// Upper controls scroll away on mobile via [NestedScrollView] so appointment
/// density remains high.
class ReceptionistTodayTab extends ConsumerWidget {
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

  Future<void> _openFilters(
    BuildContext context,
    WidgetRef ref,
    ReceptionistAppointmentsState state,
  ) async {
    final result = await ScheduleFilterSheet.show(
      context: context,
      doctorId: state.filterDoctorId,
    );
    if (result != null) {
      ref
          .read(receptionistAppointmentsProvider.notifier)
          .setDoctorFilter(result.doctorId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int activeFiltersCount = state.filterDoctorId != null ? 1 : 0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => <Widget>[
            SliverToBoxAdapter(
              child: Column(
                key: const ValueKey<String>(
                  'receptionist-schedule-upper-controls',
                ),
                children: [
                  DoctorWeekStrip(
                    dayCounts: state.dayAppointmentCounts,
                    selectedDate: state.selectedDate,
                    showCancelled: state.showCancelled,
                    onToggleCancelled: () => ref
                        .read(receptionistAppointmentsProvider.notifier)
                        .toggleShowCancelled(),
                    onDateSelected: (date) => ref
                        .read(receptionistAppointmentsProvider.notifier)
                        .selectDate(date),
                  ),
                  ScheduleToolbar(
                    searchQuery: searchQuery,
                    onSearchChanged: onSearchChanged,
                    activeFiltersCount: activeFiltersCount,
                    onFilterTap: () => _openFilters(context, ref, state),
                  ),
                ],
              ),
            ),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppointmentAgendaTableHeader(showDoctor: true),
              Expanded(
                child: AnimatedSwitcher(
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
                            'today_data_${state.selectedDate}_${state.itemsForSelectedDay.length}_${state.showCancelled}',
                          ),
                          child: ReceptionistDayList(
                            state: state,
                            searchQuery: searchQuery,
                            onStatusChanged: onStatusChanged,
                            onRefresh: () async => onRefresh(),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final Object error = state.error!;
    final AppException ex =
        error is AppException ? error : UnknownException(message: '$error');
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
