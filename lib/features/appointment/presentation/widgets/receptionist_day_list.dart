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
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

/// Helper model for grouped list item row.
class _ScheduleRowItem {
  final Patient patient;
  final List<AppointmentWithPatient> appointments;

  _ScheduleRowItem({required this.patient, required this.appointments});
}

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
  late final ScrollController _scrollController;
  DateTime? _lastAutoScrolledDate;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _checkAutoScroll();
  }

  @override
  void didUpdateWidget(covariant ReceptionistDayList oldWidget) {
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
      final allItems = widget.state.itemsForSelectedDay;
      final items = _filter(allItems);
      final rowItems = _buildRowItems(items);
      final nowIndex = _getNowIndex(rowItems);

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

    final rowItems = _buildRowItems(items);
    final nowIndex = _getNowIndex(rowItems);
    final hasNow = nowIndex >= 0;
    final totalCount = rowItems.length + (hasNow ? 1 : 0);

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

  List<_ScheduleRowItem> _buildRowItems(List<AppointmentWithPatient> items) {
    final groupedItems = <String, List<AppointmentWithPatient>>{};
    for (final item in items) {
      final patientId = item.appointment.patientId;
      groupedItems.putIfAbsent(patientId, () => []).add(item);
    }

    final rowItems = <_ScheduleRowItem>[];
    final processedPatients = <String>{};
    for (final item in items) {
      final patientId = item.appointment.patientId;
      if (processedPatients.contains(patientId)) continue;
      processedPatients.add(patientId);
      rowItems.add(_ScheduleRowItem(
        patient: item.patient,
        appointments: groupedItems[patientId]!,
      ));
    }
    return rowItems;
  }

  List<AppointmentWithPatient> _filter(List<AppointmentWithPatient> items) {
    if (widget.searchQuery.isEmpty) return items;
    final q = widget.searchQuery.toLowerCase();
    return items
        .where((a) => a.patient.fullName.toLowerCase().contains(q))
        .toList();
  }

  int _getNowIndex(List<_ScheduleRowItem> items) {
    if (!widget.state.isToday || items.isEmpty) return -1;
    final now = DateTime.now();
    for (int i = 0; i < items.length; i++) {
      final earliest = items[i].appointments.first.appointment.scheduledAt;
      if (now.isBefore(earliest)) {
        return i;
      }
    }
    return items.length;
  }
}
