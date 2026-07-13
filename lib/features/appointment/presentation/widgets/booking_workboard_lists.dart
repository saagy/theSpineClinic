import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_state.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/due_patient_card.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
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
            child: _Pane(
              title: AppStrings.duePatients,
              count: state.duePatients.length,
              child: _dueContent(),
            ),
          ),
          const SizedBox(width: AppSizes.p16),
          Expanded(
            child: _Pane(
              title: AppStrings.schedule,
              count: state.schedule.length,
              child: _scheduleContent(),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<BookingWorkboardView>(
            segments: [
              ButtonSegment(
                value: BookingWorkboardView.due,
                label: Text(
                  AppStrings.sectionCount(
                    AppStrings.duePatients,
                    state.duePatients.length,
                  ),
                ),
              ),
              ButtonSegment(
                value: BookingWorkboardView.schedule,
                label: Text(
                  AppStrings.sectionCount(
                    AppStrings.schedule,
                    state.schedule.length,
                  ),
                ),
              ),
            ],
            selected: {state.view},
            onSelectionChanged: (values) => onViewChanged(values.single),
          ),
        ),
        const SizedBox(height: AppSizes.p12),
        Expanded(
          child: state.view == BookingWorkboardView.due
              ? _dueContent()
              : _scheduleContent(),
        ),
      ],
    );
  }

  Widget _dueContent() {
    if (state.dueLoading) return const SkeletonTileList(count: 5);
    if (state.dueError != null) return _error(state.dueError!);
    return _dueList();
  }

  Widget _scheduleContent() {
    if (state.scheduleLoading) return const SkeletonTileList(count: 5);
    if (state.scheduleError != null) return _error(state.scheduleError!);
    return _scheduleList();
  }

  Widget _error(Object error) {
    return ErrorView(
      exception: error is AppException
          ? error
          : UnknownException(message: error.toString()),
      onRetry: onRefresh,
    );
  }

  Widget _dueList() {
    if (state.duePatients.isEmpty) {
      return _refreshableEmpty(
        AppStrings.noDuePatients,
        Icons.event_available_rounded,
      );
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
          );
        },
      ),
    );
  }

  Widget _scheduleList() {
    if (state.schedule.isEmpty) {
      return _refreshableEmpty(
        AppStrings.noScheduleForDate,
        Icons.calendar_today_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSizes.p24),
        itemCount: state.schedule.length,
        itemBuilder: (_, index) => ReceptionistAppointmentCard(
          item: state.schedule[index],
          onStatusChanged: onRefresh,
        ),
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

class _Pane extends StatelessWidget {
  const _Pane({required this.title, required this.count, required this.child});
  final String title;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.sectionCount(title, count),
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: AppSizes.p12),
        Expanded(child: child),
      ],
    );
  }
}
