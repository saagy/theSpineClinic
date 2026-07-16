import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/presentation/schedule_week.dart';

class ScheduleWeekHeader extends StatelessWidget {
  const ScheduleWeekHeader({
    super.key,
    required this.compact,
    required this.selected,
    required this.onPickDate,
    required this.onToday,
    required this.onPrevious,
    required this.onNext,
  });

  final bool compact;
  final DateTime selected;
  final VoidCallback onPickDate;
  final VoidCallback onToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final bool isToday =
        ScheduleWeek.day(selected) == ScheduleWeek.day(DateTime.now());
    return Row(
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Tooltip(
              message: AppStrings.jumpToDate,
              child: TextButton.icon(
                onPressed: onPickDate,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(
                  DateFormat('MMMM yyyy').format(selected),
                  style: AppTextStyles.headingSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        if (compact)
          IconButton(
            onPressed: isToday ? null : onToday,
            tooltip: AppStrings.today,
            icon: const Icon(Icons.today_rounded),
          )
        else
          TextButton.icon(
            onPressed: isToday ? null : onToday,
            icon: const Icon(Icons.today_rounded),
            label: const Text(AppStrings.today),
          ),
        IconButton(
          onPressed: onPrevious,
          tooltip: AppStrings.previousWeek,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: AppStrings.nextWeek,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
