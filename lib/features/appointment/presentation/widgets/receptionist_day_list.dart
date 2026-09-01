import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/schedule_density_controller.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_day_list_helpers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_grouped_appointment_card.dart';

/// The appointment list for a single day selected in the week strip.
class ReceptionistDayList extends ConsumerStatefulWidget {
  /// Creates a [ReceptionistDayList].
  const ReceptionistDayList({
    super.key,
    required this.state,
    required this.searchQuery,
    this.onStatusChanged,
    this.onRefresh,
  });

  final ReceptionistAppointmentsState state;
  final String searchQuery;
  final VoidCallback? onStatusChanged;
  final Future<void> Function()? onRefresh;

  @override
  ConsumerState<ReceptionistDayList> createState() =>
      _ReceptionistDayListState();
}

class _ReceptionistDayListState extends ConsumerState<ReceptionistDayList> {
  final GlobalKey _nowIndicatorKey = GlobalKey();
  DateTime? _lastAutoScrolledDate;

  @override
  void initState() {
    super.initState();
    _checkAutoScroll();
  }

  @override
  void didUpdateWidget(covariant ReceptionistDayList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedDate != widget.state.selectedDate) {
      _lastAutoScrolledDate = null;
      _checkAutoScroll();
    } else if (oldWidget.state.itemsForSelectedDay.isEmpty &&
        widget.state.itemsForSelectedDay.isNotEmpty) {
      _checkAutoScroll();
    }
  }

  void _checkAutoScroll() {
    if (!widget.state.isToday || widget.searchQuery.isNotEmpty) return;
    if (_lastAutoScrolledDate == widget.state.selectedDate) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = PrimaryScrollController.maybeOf(context);
      if (controller == null || !controller.hasClients) return;

      final allItems = widget.state.itemsForSelectedDay;
      final items = _filter(allItems);
      if (items.isEmpty) return;

      final rowItems = buildScheduleRowItems(items);
      final nowIndex = getScheduleNowIndex(
        rowItems,
        isToday: widget.state.isToday,
      );
      if (nowIndex < 0) return;

      final isCompact = ref.read(scheduleCompactControllerProvider);
      final double target = estimateScheduleScrollOffset(
        rowItems: rowItems,
        nowIndex: nowIndex,
        isCompact: isCompact,
      );

      if (target > 0) {
        controller.jumpTo(target);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final nowContext = _nowIndicatorKey.currentContext;
        if (nowContext != null) {
          Scrollable.ensureVisible(
            nowContext,
            alignment: 0.08,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });

      _lastAutoScrolledDate = widget.state.selectedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allItems = widget.state.itemsForSelectedDay;
    final items = _filter(allItems);

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
              widget.searchQuery.isNotEmpty
                  ? AppStrings.noMatchingDoctorsFound
                  : AppStrings.noAppointmentsFound,
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

    final rowItems = buildScheduleRowItems(items);
    final nowIndex = getScheduleNowIndex(
      rowItems,
      isToday: widget.state.isToday,
    );
    final hasNow = nowIndex >= 0;
    final totalCount = rowItems.length + (hasNow ? 1 : 0);

    final list = ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, AppSizes.p8, 0, AppSizes.p32),
      itemCount: totalCount,
      itemBuilder: (_, index) {
        if (hasNow && index == nowIndex) {
          return ScheduleNowIndicator(key: _nowIndicatorKey);
        }

        final cardIndex = hasNow && index > nowIndex ? index - 1 : index;
        final rowItem = rowItems[cardIndex];

        if (rowItem.appointments.length == 1) {
          return ReceptionistAppointmentCard(
            item: rowItem.appointments.first,
            onStatusChanged: widget.onStatusChanged,
          );
        } else {
          return ReceptionistGroupedAppointmentCard(
            patient: rowItem.patient,
            items: rowItem.appointments,
            onStatusChanged: widget.onStatusChanged,
          );
        }
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

  List<AppointmentWithPatient> _filter(List<AppointmentWithPatient> items) {
    if (widget.searchQuery.isEmpty) return items;
    final q = widget.searchQuery.toLowerCase();
    return items
        .where((a) => a.patient.fullName.toLowerCase().contains(q))
        .toList();
  }
}
