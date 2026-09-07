import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/presentation/schedule_week.dart';

/// Modern week navigation header featuring month picker, Today jump, and week controls.
class ScheduleWeekHeader extends StatelessWidget {
  const ScheduleWeekHeader({
    super.key,
    required this.compact,
    required this.selected,
    required this.onPickDate,
    required this.onToday,
    required this.onPreviousWeek,
    required this.onNextWeek,
    this.showCancelled = false,
    this.onToggleCancelled,
  });

  final bool compact;
  final DateTime selected;
  final VoidCallback onPickDate;
  final VoidCallback onToday;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final bool showCancelled;
  final VoidCallback? onToggleCancelled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool isToday =
        ScheduleWeek.day(selected) == ScheduleWeek.day(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: onPickDate,
                borderRadius: BorderRadius.circular(AppSizes.r8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p8,
                    vertical: AppSizes.p6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          DateFormat('MMMM yyyy').format(selected),
                          style: AppTextStyles.bodyBold.copyWith(
                            color: cs.onSurface,
                            fontSize: 15.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSizes.p4),
                      Icon(
                        LucideIcons.chevron_down,
                        size: 16.0,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onToggleCancelled != null)
            InkWell(
              onTap: onToggleCancelled,
              borderRadius: BorderRadius.circular(AppSizes.r6),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p8,
                  vertical: AppSizes.p6,
                ),
                child: Text(
                  showCancelled
                      ? AppStrings.hideCancelled
                      : AppStrings.showCancelled,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: showCancelled ? cs.primary : cs.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ),
          const SizedBox(width: AppSizes.p4),
          if (compact)
            IconButton(
              onPressed: isToday ? null : onToday,
              tooltip: AppStrings.today,
              constraints: const BoxConstraints(minWidth: 36.0, minHeight: 36.0),
              icon: Icon(
                LucideIcons.calendar,
                size: 16.0,
                color: isToday ? cs.onSurfaceVariant.withAlpha(100) : cs.primary,
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: isToday ? null : onToday,
              icon: Icon(
                LucideIcons.calendar,
                size: 14.0,
                color: isToday ? cs.onSurfaceVariant.withAlpha(100) : cs.primary,
              ),
              label: Text(
                AppStrings.today,
                style: AppTextStyles.captionBold.copyWith(
                  color: isToday ? cs.onSurfaceVariant.withAlpha(100) : cs.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: 0),
                minimumSize: const Size(0, 30.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r6)),
                side: BorderSide(
                  color: cs.outlineVariant.withAlpha(120),
                  width: AppSizes.borderWidth,
                ),
              ),
            ),
          if (!compact) ...<Widget>[
            IconButton(
              onPressed: onPreviousWeek,
              tooltip: AppStrings.previousWeek,
              constraints: const BoxConstraints(minWidth: 36.0, minHeight: 36.0),
              icon: Icon(
                LucideIcons.chevron_left,
                size: 16.0,
                color: cs.onSurfaceVariant,
              ),
            ),
            IconButton(
              onPressed: onNextWeek,
              tooltip: AppStrings.nextWeek,
              constraints: const BoxConstraints(minWidth: 36.0, minHeight: 36.0),
              icon: Icon(
                LucideIcons.chevron_right,
                size: 16.0,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
