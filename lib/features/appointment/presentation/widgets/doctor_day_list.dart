/// Appointment list for a single day with now-indicator, time-sorted items,
/// and status-aware styling.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';

/// The appointment list for a single day selected in the week strip.
class DoctorDayList extends StatelessWidget {
  /// Creates a [DoctorDayList].
  const DoctorDayList({
    super.key,
    required this.state,
    this.onStatusChanged,
    this.onToggleCancelled,
    this.onRefresh,
  });

  final DoctorScheduleState state;
  final VoidCallback? onStatusChanged;
  final VoidCallback? onToggleCancelled;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = state.itemsForSelectedDay;

    if (items.isEmpty) {
      final emptyWidget = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSizes.p32),
        children: [
          _DateHeader(
            state: state,
            count: 0,
            onToggleCancelled: onToggleCancelled,
          ),
          const SizedBox(height: AppSizes.p48),
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

    final nowIndex = _getNowIndex(items);
    final hasNow = nowIndex >= 0;
    final totalCount = items.length + 1 + (hasNow ? 1 : 0);

    final list = ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSizes.p32),
      itemCount: totalCount,
      itemBuilder: (_, index) {
        if (index == 0) {
          return _DateHeader(
            state: state,
            count: items.length,
            onToggleCancelled: onToggleCancelled,
          );
        }

        if (hasNow && index - 1 == nowIndex) {
          return const _NowIndicator();
        }

        final cardIndex = hasNow && index - 1 > nowIndex ? index - 2 : index - 1;
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

  Widget _buildCard(DoctorScheduleItem item) {
    final appt = item.appointment;

    return ReceptionistAppointmentCard(
      item: AppointmentWithPatient(
        appointment: appt,
        patient: item.patient,
      ),
      onStatusChanged: onStatusChanged,
    );
  }

  /// Returns insertion index (0..items.length) for `_NowIndicator`.
  /// Returns `-1` if selected day is not today or items is empty.
  int _getNowIndex(List<DoctorScheduleItem> items) {
    if (!state.isToday || items.isEmpty) return -1;
    final now = DateTime.now();
    for (int i = 0; i < items.length; i++) {
      if (now.isBefore(items[i].appointment.scheduledAt)) {
        return i;
      }
    }
    return items.length;
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.state,
    required this.count,
    required this.onToggleCancelled,
  });

  final DoctorScheduleState state;
  final int count;
  final VoidCallback? onToggleCancelled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = state.selectedDate ?? DateTime.now();
    final formatted = DateFormat('EEEE, MMM d').format(date);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Text(formatted, style: AppTextStyles.captionBold.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                if (state.isToday) ...[
                  const SizedBox(width: AppSizes.p8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p6, vertical: AppSizes.p2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSizes.r4),
                    ),
                    child: Text(
                      AppStrings.today.toUpperCase(),
                      style: AppTextStyles.captionBold.copyWith(color: theme.colorScheme.primary, fontSize: 10),
                    ),
                  ),
                ],
                Text('  ·  $count appointment${count == 1 ? '' : 's'}',
                    style: AppTextStyles.captionBold.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (onToggleCancelled != null)
            InkWell(
              onTap: onToggleCancelled,
              borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
                child: Text(
                  state.showCancelled ? AppStrings.hideCancelled : AppStrings.showCancelled,
                  style: AppTextStyles.captionBold.copyWith(color: theme.colorScheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Now indicator: red dot + current time + horizontal red line.
class _NowIndicator extends StatelessWidget {
  const _NowIndicator();
  static const double _timeWidth = 65;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final now = DateFormat('h:mm a').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
      child: Row(
        children: [
          const SizedBox(width: AppSizes.p16),
          SizedBox(
            width: _timeWidth,
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: errorColor, shape: BoxShape.circle)),
                const SizedBox(width: AppSizes.p4),
                Flexible(
                  child: Text(now, style: AppTextStyles.captionBold.copyWith(color: errorColor), maxLines: 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          Expanded(child: Divider(color: errorColor, thickness: 1, height: 0)),
        ],
      ),
    );
  }
}
