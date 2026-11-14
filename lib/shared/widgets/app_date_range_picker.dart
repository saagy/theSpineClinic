import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/shared/widgets/date_range_month_grid.dart';

/// Asks for a period as two days. It looks like the single-day calendar, but
/// the From and To boxes on top show which day the next tap sets, so it is
/// clear that two days are expected. Returns null when dismissed.
Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialDateRange,
  String? helpText,
}) => showDialog<DateTimeRange>(
  context: context,
  builder: (_) => _DateRangeDialog(
    firstDate: DateUtils.dateOnly(firstDate),
    lastDate: DateUtils.dateOnly(lastDate),
    initial: initialDateRange,
    help: helpText,
  ),
);

class _DateRangeDialog extends StatefulWidget {
  const _DateRangeDialog({
    required this.firstDate,
    required this.lastDate,
    this.initial,
    this.help,
  });
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? initial;
  final String? help;

  @override
  State<_DateRangeDialog> createState() => _DateRangeDialogState();
}

class _DateRangeDialogState extends State<_DateRangeDialog> {
  late DateTime? _start = widget.initial == null ? null : DateUtils.dateOnly(widget.initial!.start);
  late DateTime? _end = widget.initial == null ? null : DateUtils.dateOnly(widget.initial!.end);
  late DateTime _month = _clampMonth(_start ?? DateTime.now());
  bool _pickingEnd = false;

  DateTime _clampMonth(DateTime day) {
    final DateTime date = day.isBefore(widget.firstDate)
        ? widget.firstDate
        : day.isAfter(widget.lastDate)
        ? widget.lastDate
        : day;
    return DateTime(date.year, date.month);
  }

  void _tap(DateTime day) => setState(() {
    if (_pickingEnd && _start != null && !day.isBefore(_start!)) {
      _end = day;
      return;
    }
    // A day before the start, or any tap while choosing From, restarts.
    _start = day;
    if (_end != null && _end!.isBefore(day)) _end = null;
    _pickingEnd = true;
  });

  void _move(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool canGoBack = _month.isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));
    final bool canGoNext = _month.isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));
    const Size minimum = Size(AppSizes.tappableMin, AppSizes.tappableMin);
    return AlertDialog(
      backgroundColor: colors.surface,
      surfaceTintColor: colors.surface.withAlpha(0),
      scrollable: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r16)),
      ),
      insetPadding: const EdgeInsets.all(AppSizes.p16),
      titlePadding: const EdgeInsets.fromLTRB(AppSizes.p24, AppSizes.p24, AppSizes.p24, 0),
      contentPadding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p16, AppSizes.p16, AppSizes.p8),
      actionsPadding: const EdgeInsets.fromLTRB(AppSizes.p24, 0, AppSizes.p24, AppSizes.p16),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.dateRangeTitle,
            style: AppTextStyles.headingSmall.copyWith(color: colors.onSurface),
          ),
          if (widget.help != null)
            Text(widget.help!, style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
      content: SizedBox(
        width: AppSizes.dateRangeDialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
              child: Row(
                children: [
                  Expanded(child: _endBox(AppStrings.dateRangeFrom, _start, !_pickingEnd, false)),
                  const SizedBox(width: AppSizes.p8),
                  Expanded(child: _endBox(AppStrings.dateRangeTo, _end, _pickingEnd, true)),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
                  onPressed: canGoBack ? () => _move(-1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    MaterialLocalizations.of(context).formatMonthYear(_month),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyBold.copyWith(color: colors.onSurface),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                  onPressed: canGoNext ? () => _move(1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            DateRangeMonthGrid(
              month: _month,
              start: _start,
              end: _end,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              onDayTap: _tap,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(minimumSize: minimum),
          child: const Text(AppStrings.cancel, style: AppTextStyles.button),
        ),
        FilledButton(
          onPressed: _start == null
              ? null
              : () => Navigator.of(context).pop(DateTimeRange(start: _start!, end: _end ?? _start!)),
          style: FilledButton.styleFrom(
            minimumSize: minimum,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
          ),
          child: const Text(AppStrings.apply, style: AppTextStyles.button),
        ),
      ],
    );
  }

  /// One end of the period. The outlined box is the one the next tap sets.
  Widget _endBox(String label, DateTime? value, bool active, bool isEnd) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: active,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.r8),
        onTap: () => setState(() {
          _pickingEnd = isEnd && _start != null;
          final DateTime? shown = isEnd ? _end : _start;
          if (shown != null) _month = _clampMonth(shown);
        }),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p8),
          decoration: BoxDecoration(
            color: active ? colors.primaryContainer : null,
            borderRadius: BorderRadius.circular(AppSizes.r8),
            border: Border.all(
              color: active ? colors.primary : colors.outlineVariant,
              width: active ? AppSizes.strokeWidthThin : AppSizes.borderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.captionMedium.copyWith(color: colors.onSurfaceVariant)),
              Text(
                value == null ? AppStrings.dateRangeChoose : Formatters.formatDateMedium(value),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: value == null ? colors.onSurfaceVariant : colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
