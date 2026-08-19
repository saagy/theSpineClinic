import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
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
    this.showCancelled = false,
    this.onToggleCancelled,
  });

  final bool compact;
  final DateTime selected;
  final VoidCallback onPickDate;
  final VoidCallback onToday;
  final bool showCancelled;
  final VoidCallback? onToggleCancelled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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
        if (onToggleCancelled != null)
          InkWell(
            onTap: onToggleCancelled,
            borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p8,
                vertical: AppSizes.p4,
              ),
              child: Text(
                showCancelled
                    ? AppStrings.hideCancelled
                    : AppStrings.showCancelled,
                style: AppTextStyles.captionBold.copyWith(
                  color: cs.primary,
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
      ],
    );
  }
}
