import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// One month of days for the range picker. The chosen days are filled, and
/// the days between them share a band so the period reads as one block.
class DateRangeMonthGrid extends StatelessWidget {
  const DateRangeMonthGrid({
    super.key,
    required this.month,
    required this.start,
    required this.end,
    required this.firstDate,
    required this.lastDate,
    required this.onDayTap,
  });
  final DateTime month;
  final DateTime? start;
  final DateTime? end;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final int firstWeekday = localizations.firstDayOfWeekIndex;
    final int offset = (DateTime(month.year, month.month).weekday % 7 - firstWeekday + 7) % 7;
    final int days = DateUtils.getDaysInMonth(month.year, month.month);
    final int rows = ((offset + days) / 7).ceil();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (int index = 0; index < 7; index++)
              Expanded(
                child: Center(
                  child: ExcludeSemantics(
                    child: Text(
                      localizations.narrowWeekdays[(firstWeekday + index) % 7],
                      style: AppTextStyles.captionMedium.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.p8),
        for (int row = 0; row < rows; row++)
          Row(
            children: [
              for (int column = 0; column < 7; column++)
                Expanded(child: _cell(context, row * 7 + column - offset + 1, days)),
            ],
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, int day, int days) {
    if (day < 1 || day > days) return const SizedBox(height: AppSizes.tappableMin);
    final colors = Theme.of(context).colorScheme;
    final DateTime date = DateTime(month.year, month.month, day);
    final bool enabled = !date.isBefore(firstDate) && !date.isAfter(lastDate);
    final bool isStart = DateUtils.isSameDay(date, start);
    final bool isEnd = DateUtils.isSameDay(date, end);
    final bool chosen = isStart || isEnd;
    final bool hasRange = start != null && end != null && !DateUtils.isSameDay(start, end);
    final bool between = hasRange && date.isAfter(start!) && date.isBefore(end!);
    final bool today = DateUtils.isSameDay(date, DateTime.now());
    final Color text = !enabled
        ? colors.onSurface.withValues(alpha: 0.38)
        : chosen
        ? colors.onPrimary
        : colors.onSurface;
    // The band runs edge to edge between the ends and stops at their centers.
    final Color band = colors.primaryContainer;
    return Semantics(
      button: enabled,
      selected: chosen || between,
      label: MaterialLocalizations.of(context).formatFullDate(date),
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? () => onDayTap(date) : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: AppSizes.tappableMin,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (between || (hasRange && chosen))
                Positioned.fill(
                  top: AppSizes.p4,
                  bottom: AppSizes.p4,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: ColoredBox(color: between || isEnd ? band : band.withAlpha(0))),
                      Expanded(child: ColoredBox(color: between || isStart ? band : band.withAlpha(0))),
                    ],
                  ),
                ),
              Container(
                width: AppSizes.tappableMin - AppSizes.p8,
                height: AppSizes.tappableMin - AppSizes.p8,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: chosen ? colors.primary : null,
                  border: today && !chosen
                      ? Border.all(color: colors.primary, width: AppSizes.borderWidth)
                      : null,
                ),
                child: Text('$day', style: AppTextStyles.bodyMedium.copyWith(color: text)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
