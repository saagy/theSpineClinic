/// Clean guidance chip summarizing a recurring-booking pattern.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Displays a compact summary of the recurring-booking configuration.
class RecurrenceGuide extends StatelessWidget {
  /// Creates a [RecurrenceGuide].
  const RecurrenceGuide({
    super.key,
    required this.startDate,
    required this.selectedWeekdays,
    required this.totalSessions,
    required this.slots,
  });

  /// The first scheduled date in the recurrence.
  final DateTime startDate;

  /// Weekdays selected for recurrence (1 = Monday, 7 = Sunday).
  final Set<int> selectedWeekdays;

  /// Total number of sessions across the recurrence.
  final int totalSessions;

  /// The full list of computed slot dates.
  final List<DateTime> slots;

  static const List<String> _dayLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final first = slots.isNotEmpty
        ? DateFormat('MMM d').format(slots.first)
        : '—';
    final cnt = totalSessions > 0
        ? '$totalSessions session${totalSessions == 1 ? '' : 's'}'
        : '… sessions';
    final days = selectedWeekdays.map((d) => _dayLabels[d - 1]).join(', ');
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p12,
        AppSizes.p8,
        AppSizes.p12,
        AppSizes.p8,
      ),
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(80),
        borderRadius:
            const BorderRadius.all(Radius.circular(AppSizes.r8)),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.caption.copyWith(
            color: cs.onSurfaceVariant,
          ),
          children: [
            TextSpan(
              text: cnt,
              style: AppTextStyles.captionBold.copyWith(
                color: cs.primary,
              ),
            ),
            const TextSpan(text: ' starting '),
            TextSpan(
              text: first,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const TextSpan(text: ' on '),
            TextSpan(
              text: days,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
