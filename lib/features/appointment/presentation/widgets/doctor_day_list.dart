/// Appointment list for a single day with now-indicator, time-sorted items,
/// and status-aware styling.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/schedule_density_controller.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_day_list_helpers.dart';

/// The appointment list for a single day selected in the week strip.
class DoctorDayList extends ConsumerStatefulWidget {
  /// Creates a [DoctorDayList].
  const DoctorDayList({
    super.key,
    required this.state,
    this.onStatusChanged,
    this.onRefresh,
  });

  final DoctorScheduleState state;
  final VoidCallback? onStatusChanged;
  final Future<void> Function()? onRefresh;

  @override
  ConsumerState<DoctorDayList> createState() => _DoctorDayListState();
}

class _DoctorDayListState extends ConsumerState<DoctorDayList> {
  late final ScrollController _scrollController;
  DateTime? _lastAutoScrolledDate;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _checkAutoScroll();
  }

  @override
  void didUpdateWidget(covariant DoctorDayList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedDate != widget.state.selectedDate) {
      _checkAutoScroll();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkAutoScroll() {
    if (!widget.state.isToday) return;
    if (_lastAutoScrolledDate == widget.state.selectedDate) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final items = widget.state.itemsForSelectedDay;
      final nowIndex = _getNowIndex(items);

      if (nowIndex > 0) {
        final isCompact = ref.read(scheduleCompactControllerProvider);
        final double itemHeight = isCompact ? 36.0 : 84.0;
        final double target = (nowIndex * itemHeight - 20.0).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        if (target > 0) {
          _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      }
      _lastAutoScrolledDate = widget.state.selectedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.state.itemsForSelectedDay;

    if (items.isEmpty) {
      final emptyWidget = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.p20,
          AppSizes.p48,
          AppSizes.p20,
          AppSizes.p32,
        ),
        children: [
          Center(
            child: Text(
              AppStrings.noAppointmentsFound,
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );

      if (widget.onRefresh != null) {
        return RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: widget.onRefresh!,
          child: emptyWidget,
        );
      }
      return emptyWidget;
    }

    final nowIndex = _getNowIndex(items);
    final hasNow = nowIndex >= 0;
    final totalCount = items.length + (hasNow ? 1 : 0);

    final list = ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, AppSizes.p8, 0, AppSizes.p32),
      itemCount: totalCount,
      itemBuilder: (_, index) {
        if (hasNow && index == nowIndex) {
          return const ScheduleNowIndicator();
        }

        final cardIndex = hasNow && index > nowIndex ? index - 1 : index;
        return _buildCard(items[cardIndex]);
      },
    );

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: widget.onRefresh!,
        child: list,
      );
    }
    return list;
  }

  Widget _buildCard(AppointmentWithPatient item) {
    return ReceptionistAppointmentCard(
      item: item,
      onStatusChanged: widget.onStatusChanged,
    );
  }

  int _getNowIndex(List<AppointmentWithPatient> items) {
    if (!widget.state.isToday || items.isEmpty) return -1;
    final now = DateTime.now();
    for (int i = 0; i < items.length; i++) {
      if (now.isBefore(items[i].appointment.scheduledAt)) {
        return i;
      }
    }
    return items.length;
  }
}
