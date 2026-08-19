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
    required this.onPrevious,
    required this.onNext,
    this.showCancelled = false,
    this.onToggleCancelled,
  });

  final bool compact;
  final DateTime selected;
  final VoidCallback onPickDate;
  final VoidCallback onToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
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
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.p4),
            child: Tooltip(
              message: showCancelled
                  ? AppStrings.hideCancelled
                  : AppStrings.showCancelled,
              child: InkWell(
                onTap: onToggleCancelled,
                borderRadius:
                    const BorderRadius.all(Radius.circular(AppSizes.r12)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p8,
                    vertical: AppSizes.p4,
                  ),
                  decoration: BoxDecoration(
                    color: showCancelled ? cs.primaryContainer : cs.surface,
                    borderRadius:
                        const BorderRadius.all(Radius.circular(AppSizes.r12)),
                    border: Border.all(
                      color: showCancelled ? cs.primary : cs.outline,
                      width: AppSizes.borderWidth,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        showCancelled
                            ? Icons.cancel
                            : Icons.cancel_outlined,
                        size: 14,
                        color: showCancelled
                            ? cs.primary
                            : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSizes.p4),
                      Text(
                        AppStrings.cancelled,
                        style: AppTextStyles.captionMedium.copyWith(
                          color: showCancelled
                              ? cs.primary
                              : cs.onSurfaceVariant,
                          fontWeight: showCancelled
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
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
