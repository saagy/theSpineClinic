/// Appointment list for a single day with now-indicator, time-sorted items,
/// and faded past/cancelled styling.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
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
    this.onRefresh,
  });

  final DoctorScheduleState state;
  final VoidCallback? onStatusChanged;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final items = state.itemsForSelectedDay;
    if (items.isEmpty) {
      return const Center(child: Text('No appointments'));
    }

    final list = ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSizes.p32),
      itemCount: items.length + 1,
      itemBuilder: (_, index) {
        if (index == 0) return _DateHeader(state: state, count: items.length);
        final item = items[index - 1];
        final showNow = _shouldShowNow(items, index - 1);
        return Column(
          children: [
            if (showNow) const _NowIndicator(),
            _buildCard(item),
          ],
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh!,
        child: list,
      );
    }
    return list;
  }

  Widget _buildCard(DoctorScheduleItem item) {
    final appt = item.appointment;
    final isPast = appt.scheduledAt.isBefore(DateTime.now());

    return ReceptionistAppointmentCard(
      item: AppointmentWithPatient(
        appointment: appt,
        patient: item.patient,
      ),
      faded: isPast,
      onStatusChanged: onStatusChanged,
    );
  }

  /// Returns `true` when the slot *after* [currentIndex] crosses from past to
  /// future — a "now" line should be drawn before that item.
  bool _shouldShowNow(List<DoctorScheduleItem> items, int currentIndex) {
    if (!state.isToday) return false;
    if (currentIndex == 0) return false;
    final prev = items[currentIndex - 1].appointment.scheduledAt;
    final curr = items[currentIndex].appointment.scheduledAt;
    final now = DateTime.now();
    return prev.isBefore(now) && !curr.isBefore(now);
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.state, required this.count});
  final DoctorScheduleState state;
  final int count;

  @override
  Widget build(BuildContext context) {
    final date = state.selectedDate ?? DateTime.now();
    final formatted = DateFormat('EEEE, MMM d').format(date);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p8),
      child: Text('$formatted  ·  $count appointment${count == 1 ? '' : 's'}',
          style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
    );
  }
}

/// Now indicator: red dot + current time + horizontal red line.
class _NowIndicator extends StatelessWidget {
  const _NowIndicator();

  /// Width matching [ReceptionistAppointmentCard._timeWidth] so the
  /// now time text sits in the same column as appointment times.
  static const double _timeWidth = 65;

  @override
  Widget build(BuildContext context) {
    final now = DateFormat('h:mm a').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
      child: Row(
        children: [
          const SizedBox(width: AppSizes.p16),
          SizedBox(
            width: _timeWidth,
            child: Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.error, shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSizes.p4),
                Flexible(
                  child: Text(now,
                      style: AppTextStyles.captionBold
                          .copyWith(color: AppColors.error),
                      maxLines: 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          const Expanded(
            child: Divider(color: AppColors.error, thickness: 1, height: 0),
          ),
        ],
      ),
    );
  }
}
