import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
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
class ReceptionistDayList extends StatelessWidget {
  /// Creates a [ReceptionistDayList].
  const ReceptionistDayList({
    super.key,
    required this.state,
    required this.searchQuery,
    this.onStatusChanged,
    this.onToggleCancelled,
    this.onRefresh,
  });

  final ReceptionistAppointmentsState state;
  final String searchQuery;
  final VoidCallback? onStatusChanged;
  final VoidCallback? onToggleCancelled;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allItems = state.itemsForSelectedDay;
    final items = _filter(allItems);

    if (items.isEmpty) {
      final emptyWidget = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSizes.p32),
        children: [
          ScheduleDateHeader(
            count: 0,
            showCancelled: state.showCancelled,
            onToggleCancelled: onToggleCancelled,
          ),
          const SizedBox(height: AppSizes.p48),
          Center(
            child: Text(
              searchQuery.isNotEmpty
                  ? AppStrings.noMatchingDoctorsFound // Reuse matching fallback
                  : AppStrings.noAppointmentsFound,
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );

      if (onRefresh != null) {
        return RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: onRefresh!,
          child: emptyWidget,
        );
      }
      return emptyWidget;
    }

    // Group items by patient ID for the selected day.
    final groupedItems = <String, List<AppointmentWithPatient>>{};
    for (final item in items) {
      final patientId = item.appointment.patientId;
      groupedItems.putIfAbsent(patientId, () => []).add(item);
    }

    // Convert to a list of _ScheduleRowItem while maintaining original sorting.
    final rowItems = <_ScheduleRowItem>[];
    final processedPatients = <String>{};
    for (final item in items) {
      final patientId = item.appointment.patientId;
      if (processedPatients.contains(patientId)) continue;
      processedPatients.add(patientId);
      final patientAppointments = groupedItems[patientId]!;
      rowItems.add(_ScheduleRowItem(
        patient: item.patient,
        appointments: patientAppointments,
      ));
    }

    final nowIndex = _getNowIndex(rowItems);
    final hasNow = nowIndex >= 0;
    final totalCount = rowItems.length + 1 + (hasNow ? 1 : 0);

    final list = ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSizes.p32),
      itemCount: totalCount,
      itemBuilder: (_, index) {
        if (index == 0) {
          return ScheduleDateHeader(
            count: items.length,
            showCancelled: state.showCancelled,
            onToggleCancelled: onToggleCancelled,
          );
        }

        if (hasNow && index - 1 == nowIndex) {
          return const ScheduleNowIndicator();
        }

        final cardIndex = hasNow && index - 1 > nowIndex ? index - 2 : index - 1;
        final rowItem = rowItems[cardIndex];

        if (rowItem.appointments.length == 1) {
          return ReceptionistAppointmentCard(
            item: rowItem.appointments.first,
            onStatusChanged: onStatusChanged,
          );
        } else {
          return ReceptionistGroupedAppointmentCard(
            patient: rowItem.patient,
            items: rowItem.appointments,
            onStatusChanged: onStatusChanged,
          );
        }
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: onRefresh!,
        child: list,
      );
    }
    return list;
  }

  List<AppointmentWithPatient> _filter(List<AppointmentWithPatient> items) {
    if (searchQuery.isEmpty) return items;
    final q = searchQuery.toLowerCase();
    return items.where((a) => a.patient.fullName.toLowerCase().contains(q)).toList();
  }

  /// Returns insertion index (0..items.length) for `_NowIndicator`.
  /// Returns `-1` if selected day is not today or items is empty.
  int _getNowIndex(List<_ScheduleRowItem> items) {
    if (!state.isToday || items.isEmpty) return -1;
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
