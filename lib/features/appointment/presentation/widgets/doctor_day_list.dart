/// Appointment list for a single day with now-indicator, time-sorted items,
/// and status-aware styling.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_day_list_helpers.dart';

/// The appointment list for a single day selected in the week strip.
class DoctorDayList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = state.itemsForSelectedDay;

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

      if (onRefresh != null) {
        return RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: onRefresh!,
          child: emptyWidget,
        );
      }
      return emptyWidget;
    }

    final nowIndex = getDoctorScheduleNowIndex(
      items,
      isToday: state.isToday,
    );
    final hasNow = nowIndex >= 0;
    final totalCount = items.length + (hasNow ? 1 : 0);

    final list = ListView.builder(
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

    if (onRefresh != null) {
      return RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: onRefresh!,
        child: list,
      );
    }
    return list;
  }

  Widget _buildCard(AppointmentWithPatient item) {
    return ReceptionistAppointmentCard(
      item: item,
      onStatusChanged: onStatusChanged,
    );
  }
}
