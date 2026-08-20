/// Helper widgets and utilities for appointment day lists: now indicator,
/// row item model, and grouping builders.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

/// Helper model for grouped list item row in schedule views.
class ScheduleRowItem {
  const ScheduleRowItem({required this.patient, required this.appointments});

  final Patient patient;
  final List<AppointmentWithPatient> appointments;
}

/// Groups appointment items by patient while maintaining chronological order.
List<ScheduleRowItem> buildScheduleRowItems(
  List<AppointmentWithPatient> items,
) {
  final groupedItems = <String, List<AppointmentWithPatient>>{};
  for (final item in items) {
    final patientId = item.appointment.patientId;
    groupedItems.putIfAbsent(patientId, () => []).add(item);
  }

  final rowItems = <ScheduleRowItem>[];
  final processedPatients = <String>{};
  for (final item in items) {
    final patientId = item.appointment.patientId;
    if (processedPatients.contains(patientId)) continue;
    processedPatients.add(patientId);
    rowItems.add(
      ScheduleRowItem(
        patient: item.patient,
        appointments: groupedItems[patientId]!,
      ),
    );
  }
  return rowItems;
}

/// Returns insertion index (0..items.length) for `ScheduleNowIndicator`.
/// Returns `-1` if selected day is not today or items is empty.
int getScheduleNowIndex(
  List<ScheduleRowItem> items, {
  required bool isToday,
}) {
  if (!isToday || items.isEmpty) return -1;
  final now = DateTime.now();
  for (int i = 0; i < items.length; i++) {
    final earliest = items[i].appointments.first.appointment.scheduledAt;
    if (now.isBefore(earliest)) {
      return i;
    }
  }
  return items.length;
}

/// Now indicator: red dot + current time + horizontal red line.
class ScheduleNowIndicator extends StatelessWidget {
  const ScheduleNowIndicator({super.key});
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
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: errorColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSizes.p4),
                Flexible(
                  child: Text(
                    now,
                    style: AppTextStyles.captionBold.copyWith(
                      color: errorColor,
                    ),
                    maxLines: 1,
                  ),
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
