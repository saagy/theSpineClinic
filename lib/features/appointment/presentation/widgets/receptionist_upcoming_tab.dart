/// Upcoming tab: future appointments grouped by date with count headers.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

import 'package:spine_clinic_app/shared/widgets/animated_list_item.dart';

/// The "Upcoming" tab content with date-grouped future appointments.
class ReceptionistUpcomingTab extends StatefulWidget {
  /// Creates a [ReceptionistUpcomingTab].
  const ReceptionistUpcomingTab({
    super.key,
    required this.state,
    this.onStatusChanged,
    this.onRefresh,
  });

  final ReceptionistAppointmentsState state;
  final VoidCallback? onStatusChanged;
  final Future<void> Function()? onRefresh;

  @override
  State<ReceptionistUpcomingTab> createState() => _ReceptionistUpcomingTabState();
}

class _ReceptionistUpcomingTabState extends State<ReceptionistUpcomingTab> {
  final Set<int> _animatedIndices = <int>{};

  @override
  void didUpdateWidget(ReceptionistUpcomingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.upcomingLoading && !oldWidget.state.upcomingLoading) {
      _animatedIndices.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.upcomingLoading) {
      _animatedIndices.clear();
      return const SkeletonTileList(count: 5);
    }
    if (widget.state.upcomingError != null) {
      return Center(
        child: Text('${widget.state.upcomingError}',
            style: AppTextStyles.bodySecondary),
      );
    }
    if (widget.state.upcoming.isEmpty) {
      return const Center(child: Text('No upcoming appointments'));
    }

    final grouped = _groupByDate(widget.state.upcoming);

    final list = ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSizes.p8, bottom: AppSizes.p32),
      itemCount: grouped.length,
      itemBuilder: (_, i) => grouped[i],
    );

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: widget.onRefresh!,
        child: list,
      );
    }
    return list;
  }

  List<Widget> _groupByDate(List<AppointmentWithPatient> items) {
    final List<Widget> result = [];
    String? lastKey;
    int animIdx = 0;

    for (final item in items) {
      final date = item.appointment.scheduledAt.toLocal();
      final key = DateFormat('yyyy-MM-dd').format(date);
      if (key != lastKey) {
        lastKey = key;
        final formatted = DateFormat('E, MMM d').format(date);
        final int count = items.where((a) {
          final d = a.appointment.scheduledAt.toLocal();
          return DateFormat('yyyy-MM-dd').format(d) == key;
        }).length;
        result.add(AnimatedListItem(
          index: animIdx++,
          animatedIndices: _animatedIndices,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p8),
            child: Text(
              '$formatted · $count appointment${count == 1 ? '' : 's'}',
              style: AppTextStyles.captionBold
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ));
      }
      result.add(AnimatedListItem(
        index: animIdx++,
        animatedIndices: _animatedIndices,
        child: ReceptionistAppointmentCard(
          item: item,
          onStatusChanged: widget.onStatusChanged,
        ),
      ));
    }
    return result;
  }
}
