/// 7-day horizontal week strip: Sat–Fri with date numbers, current-day
/// highlight, and appointment dots beneath days that have appointments.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A horizontal row of 7 day buttons (Sat–Fri) showing abbreviated day name,
/// date number, and an appointment dot when the day has appointments.
class DoctorWeekStrip extends StatelessWidget {
  /// Creates a [DoctorWeekStrip].
  const DoctorWeekStrip({
    super.key,
    required this.dayCounts,
    required this.selectedDate,
    required this.onDateSelected,
  });

  /// Map of day index (0=Sat, 6=Fri) to non-cancelled appointment count.
  final Map<int, int> dayCounts;

  /// The currently selected date.
  final DateTime? selectedDate;

  /// Called when the user taps a day.
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    // Week starts on Saturday: (weekday + 1) % 7 gives 0 for Saturday.
    final weekStart = now.subtract(Duration(days: (now.weekday + 1) % 7));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
      child: SizedBox(
        height: 72,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
          itemCount: 7,
          itemBuilder: (_, i) {
            final date = weekStart.add(Duration(days: i));
            final isSelected = selectedDate != null &&
                date.year == selectedDate!.year &&
                date.month == selectedDate!.month &&
                date.day == selectedDate!.day;
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            final hasApps = (dayCounts[i] ?? 0) > 0;

            final Color backgroundColor;
            final Border? border;
            final Color textColor;
            final Color subtextColor;

            if (isSelected) {
              backgroundColor = colorScheme.primary;
              border = null;
              textColor = colorScheme.onPrimary;
              subtextColor = colorScheme.onPrimary;
            } else if (isToday) {
              backgroundColor = colorScheme.primaryContainer.withValues(alpha: 0.3);
              border = Border.all(color: colorScheme.primary, width: 1.5);
              textColor = colorScheme.primary;
              subtextColor = colorScheme.primary;
            } else {
              backgroundColor = colorScheme.surface.withAlpha(0);
              border = null;
              textColor = colorScheme.onSurface;
              subtextColor = colorScheme.onSurfaceVariant;
            }

            return GestureDetector(
              onTap: () => onDateSelected(date),
              child: Container(
                width: 48,
                margin: const EdgeInsets.symmetric(horizontal: AppSizes.p4),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: border,
                  borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('E').format(date).substring(0, 2),
                      style: AppTextStyles.captionMedium.copyWith(
                        color: subtextColor,
                        fontWeight: isToday ? FontWeight.bold : null,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p2),
                    Text(
                      date.day.toString(),
                      style: AppTextStyles.bodyBold.copyWith(
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p4),
                    if (hasApps)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : (isToday ? colorScheme.primary : colorScheme.error),
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(width: 4, height: 4),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
