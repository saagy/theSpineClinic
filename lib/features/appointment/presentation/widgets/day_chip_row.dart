/// Three-chip day picker for the doctor replacement flow.
///
/// Quick options for "Today" and "Tomorrow", plus a "Pick a day" chip that
/// opens [showDatePicker] for any future day. Past dates are prevented via
/// `firstDate: today`. The chosen day is reported to the parent through
/// [onChanged].
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/filter_chip.dart';

/// Internal classification of the currently selected day relative to today.
enum _DayOption { today, tomorrow, custom }

/// A horizontal pill-chip row used to pick a future day.
class DayChipRow extends StatefulWidget {
  const DayChipRow({
    super.key,
    required this.initialDate,
    required this.onChanged,
  });

  /// The day to mark as selected on first render. If earlier than today it
  /// is clamped to today.
  final DateTime initialDate;

  /// Called whenever the user changes the selected day. The emitted value is
  /// always at midnight (date-only).
  final ValueChanged<DateTime> onChanged;

  @override
  State<DayChipRow> createState() => _DayChipRowState();
}

class _DayChipRowState extends State<DayChipRow> {
  late final DateTime _today = DateUtils.dateOnly(DateTime.now());
  late final DateTime _tomorrow = _today.add(const Duration(days: 1));
  late DateTime _selected =
      DateUtils.dateOnly(_normalize(widget.initialDate));
  late _DayOption _option = _classify(_selected);

  DateTime _normalize(DateTime date) {
    final DateTime only = DateUtils.dateOnly(date);
    return only.isBefore(_today) ? _today : only;
  }

  _DayOption _classify(DateTime date) {
    if (date.isAtSameMomentAs(_today)) return _DayOption.today;
    if (date.isAtSameMomentAs(_tomorrow)) return _DayOption.tomorrow;
    return _DayOption.custom;
  }

  void _select(_DayOption next) {
    setState(() {
      _option = next;
      if (next == _DayOption.today) {
        _selected = _today;
      } else if (next == _DayOption.tomorrow) {
        _selected = _tomorrow;
      }
    });
    widget.onChanged(_selected);
  }

  Future<void> _pickCustom() async {
    final DateTime initial = _selected.isBefore(_today) ? _today : _selected;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _today,
      lastDate: _today.add(const Duration(days: 365)),
      helpText: AppStrings.pickADay,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selected = DateUtils.dateOnly(picked);
      _option = _classify(_selected);
    });
    widget.onChanged(_selected);
  }

  String _customLabel() => DateFormat('EEE, MMM d').format(_selected);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.p8,
      runSpacing: AppSizes.p8,
      children: [
        AppFilterChip(
          label: AppStrings.dayToday,
          variant: AppFilterChipVariant.filled,
          isActive: _option == _DayOption.today,
          onTap: () => _select(_DayOption.today),
        ),
        AppFilterChip(
          label: AppStrings.dayTomorrow,
          variant: AppFilterChipVariant.filled,
          isActive: _option == _DayOption.tomorrow,
          onTap: () => _select(_DayOption.tomorrow),
        ),
        AppFilterChip(
          label: _option == _DayOption.custom
              ? _customLabel()
              : AppStrings.pickADay,
          variant: AppFilterChipVariant.filled,
          isActive: _option == _DayOption.custom,
          onTap: _pickCustom,
        ),
      ],
    );
  }
}
