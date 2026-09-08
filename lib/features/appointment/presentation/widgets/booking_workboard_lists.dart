import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_state.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_workboard_pane.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/due_patient_card.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/segmented_count_tabs.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

class BookingWorkboardLists extends StatelessWidget {
  const BookingWorkboardLists({
    super.key,
    required this.state,
    required this.wide,
    required this.onRefresh,
    required this.onViewChanged,
    required this.onCall,
    required this.onBook,
    required this.onRemind,
    required this.onStop,
  });

  final BookingWorkboardState state;
  final bool wide;
  final Future<void> Function() onRefresh;
  final ValueChanged<BookingWorkboardView> onViewChanged;
  final ValueChanged<Patient> onCall;
  final ValueChanged<Patient> onBook;
  final ValueChanged<Patient> onRemind;
  final ValueChanged<Patient> onStop;

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: BookingWorkboardPane(
              title: AppStrings.duePatients,
              count: state.duePatients.length,
              child: _dueContent(context),
            ),
          ),
          const SizedBox(width: AppSizes.p16),
          Expanded(
            child: BookingWorkboardPane(
              title: AppStrings.schedule,
              count: state.schedule.length,
              child: _scheduleContent(context),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        if (state.dueLoading || state.scheduleLoading)
          const BookingWorkboardTabsSkeleton()
        else
          SegmentedCountTabs(
            items: [
              SegmentedCountTabItem(
                icon: Icons.groups_2_outlined,
                label: AppStrings.duePatients,
                count: state.duePatients.length,
                isActive: state.view == BookingWorkboardView.due,
                onTap: () => onViewChanged(BookingWorkboardView.due),
              ),
              SegmentedCountTabItem(
                icon: Icons.event_outlined,
                label: AppStrings.schedule,
                count: state.schedule.length,
                isActive: state.view == BookingWorkboardView.schedule,
                onTap: () => onViewChanged(BookingWorkboardView.schedule),
              ),
            ],
          ),
        const SizedBox(height: AppSizes.p12),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
            child: state.view == BookingWorkboardView.due
                ? KeyedSubtree(
                    key: ValueKey('workboard_due_${state.dueLoading}'),
                    child: _dueContent(context),
                  )
                : KeyedSubtree(
                    key: ValueKey('workboard_sched_${state.scheduleLoading}'),
                    child: _scheduleContent(context),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _dueContent(BuildContext context) {
    if (state.dueLoading) return const SkeletonTileList(count: 5);
    if (state.dueError != null) return _error(state.dueError!);
    return _dueList(context);
  }

  Widget _scheduleContent(BuildContext context) {
    if (state.scheduleLoading) return const SkeletonTileList(count: 5);
    if (state.scheduleError != null) return _error(state.scheduleError!);
    return _scheduleList(context);
  }

  Widget _error(Object error) => ErrorView(
    exception: error is AppException ? error : UnknownException(message: error.toString()),
    onRetry: onRefresh,
  );

  Widget _dueList(BuildContext context) {
    if (state.duePatients.isEmpty) {
      return _refreshableEmpty(AppStrings.noDuePatients, Icons.event_available_rounded);
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSizes.p24),
        itemCount: state.duePatients.length,
        itemBuilder: (_, index) {
          final Patient patient = state.duePatients[index];
          return DuePatientCard(
            patient: patient,
            referenceDate: state.date,
            onCall: () => onCall(patient),
            onBook: () => onBook(patient),
            onRemindLater: () => onRemind(patient),
            onStopFollowUp: () => onStop(patient),
            onTap: () => context.push(AppRoutes.patientDetail.replaceAll(':id', patient.id)),
          );
        },
      ),
    );
  }

  Widget _scheduleList(BuildContext context) {
    if (state.schedule.isEmpty) {
      return _refreshableEmpty(
        AppStrings.noScheduleForDate,
        Icons.calendar_today_outlined,
      );
    }
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSizes.p24),
        itemCount: state.schedule.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          thickness: AppSizes.borderWidth,
          color: cs.outlineVariant.withAlpha(80),
        ),
        itemBuilder: (_, index) {
          final item = state.schedule[index];
          return AppointmentAgendaRow(
            key: ValueKey(item.appointment.id),
            item: item,
            onStatusChanged: onRefresh,
          );
        },
      ),
    );
  }

  Widget _refreshableEmpty(String message, IconData icon) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(message: message, icon: icon),
          ),
        ],
      ),
    );
  }
}
