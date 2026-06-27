/// Today tab content: stats strip, search bar, and appointments grouped
/// by status (Checked In → Scheduled → Cancelled).
///
/// Rule 1 — under 200 lines.
library;
import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

import 'package:spine_clinic_app/shared/widgets/animated_list_item.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_today_helpers.dart';

/// The "Today" tab content with stats, search, and grouped appointment list.
class ReceptionistTodayTab extends StatefulWidget {
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
  State<ReceptionistTodayTab> createState() => _ReceptionistTodayTabState();
}

class _ReceptionistTodayTabState extends State<ReceptionistTodayTab> {
  final Set<int> _animatedIndices = <int>{};

  @override
  void didUpdateWidget(ReceptionistTodayTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.todayLoading && !oldWidget.state.todayLoading) {
      _animatedIndices.clear();
    }
    if (widget.searchQuery != oldWidget.searchQuery) {
      _animatedIndices.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.todayLoading) {
      _animatedIndices.clear();
      return const SkeletonTileList(count: 5);
    }
    if (widget.state.todayError != null) {
      return _buildErrorState();
    }

    final filtered = _filter(widget.state.today);
    final checkedIn = _byStatus(filtered, AppointmentStatus.checkedIn);
    final scheduled = _byStatus(filtered, AppointmentStatus.scheduled);
    final cancelled = _byStatus(filtered, AppointmentStatus.cancelled);

    int animIdx = 0;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => widget.onRefresh.call(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSizes.p32),
        children: [
          TodayStatsStrip(state: widget.state),
          TodaySearchField(onChanged: widget.onSearchChanged),
          if (checkedIn.isNotEmpty) ...[
            AnimatedListItem(
              index: animIdx++,
              animatedIndices: _animatedIndices,
              child: TodaySectionHeader(title: 'Checked In', count: checkedIn.length),
            ),
            ...checkedIn.map((item) => AnimatedListItem(
                  index: animIdx++,
                  animatedIndices: _animatedIndices,
                  child: ReceptionistAppointmentCard(
                    item: item,
                    onStatusChanged: widget.onStatusChanged,
                  ),
                )),
          ],
          if (scheduled.isNotEmpty) ...[
            AnimatedListItem(
              index: animIdx++,
              animatedIndices: _animatedIndices,
              child: TodaySectionHeader(title: 'Scheduled', count: scheduled.length),
            ),
            ...scheduled.map((item) => AnimatedListItem(
                  index: animIdx++,
                  animatedIndices: _animatedIndices,
                  child: ReceptionistAppointmentCard(
                    item: item,
                    onStatusChanged: widget.onStatusChanged,
                  ),
                )),
          ],
          if (cancelled.isNotEmpty) ...[
            AnimatedListItem(
              index: animIdx++,
              animatedIndices: _animatedIndices,
              child: TodaySectionHeader(title: 'Cancelled', count: cancelled.length),
            ),
            ...cancelled.map((item) => AnimatedListItem(
                  index: animIdx++,
                  animatedIndices: _animatedIndices,
                  child: ReceptionistAppointmentCard(
                    item: item,
                    onStatusChanged: widget.onStatusChanged,
                  ),
                )),
          ],
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppSizes.p48),
              child: Center(child: Text('No appointments today')),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final Object error = widget.state.todayError!;
    final AppException ex = error is AppException
        ? error
        : UnknownException(message: '$error');
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () async => widget.onRefresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: ErrorView(exception: ex, onRetry: widget.onRefresh),
          ),
        ],
      ),
    );
  }

  List<AppointmentWithPatient> _filter(List<AppointmentWithPatient> items) {
    if (widget.searchQuery.isEmpty) return items;
    final q = widget.searchQuery.toLowerCase();
    return items.where((a) => a.patient.fullName.toLowerCase().contains(q)).toList();
  }

  List<AppointmentWithPatient> _byStatus(
    List<AppointmentWithPatient> items,
    AppointmentStatus status,
  ) {
    return items.where((a) => a.appointment.status == status).toList();
  }

}

