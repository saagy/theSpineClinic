/// The appointment list for a single day selected in the week strip.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_day_list_helpers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_grouped_appointment_card.dart';

/// The appointment list for a single day selected in the week strip.
class ReceptionistDayList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allItems = state.itemsForSelectedDay;
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
              searchQuery.isNotEmpty
                  ? AppStrings.noMatchingDoctorsFound
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

    final rowItems = buildScheduleRowItems(items);
    final nowIndex = getScheduleNowIndex(
      rowItems,
      isToday: state.isToday,
    );
    final hasNow = nowIndex >= 0;
    final totalCount = rowItems.length + (hasNow ? 1 : 0);

    final list = ListView.builder(
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
    return items
        .where((a) => a.patient.fullName.toLowerCase().contains(q))
        .toList();
  }
}
