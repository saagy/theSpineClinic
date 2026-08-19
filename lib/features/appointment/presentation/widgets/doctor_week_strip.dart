/// Shared, pageable seven-day navigator for schedule screens.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/presentation/schedule_week.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/schedule_day_button.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/schedule_week_header.dart';

class DoctorWeekStrip extends StatefulWidget {
  const DoctorWeekStrip({
    super.key,
    required this.dayCounts,
    required this.selectedDate,
    required this.onDateSelected,
    this.showCancelled = false,
    this.onToggleCancelled,
  });

  final Map<DateTime, int> dayCounts;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool showCancelled;
  final VoidCallback? onToggleCancelled;

  @override
  State<DoctorWeekStrip> createState() => _DoctorWeekStripState();
}

class _DoctorWeekStripState extends State<DoctorWeekStrip> {
  static const int _centerPage = 10000;
  static const int _datePickerYearSpan = 20;
  late final PageController _controller;
  late DateTime _anchorWeek;
  int _page = _centerPage;

  DateTime get _selected =>
      ScheduleWeek.day(widget.selectedDate ?? DateTime.now());

  @override
  void initState() {
    super.initState();
    _anchorWeek = ScheduleWeek.start(_selected);
    _controller = PageController(initialPage: _centerPage);
  }

  @override
  void didUpdateWidget(covariant DoctorWeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final DateTime selectedWeek = ScheduleWeek.start(_selected);
    if (selectedWeek == _weekForPage(_page)) return;
    _anchorWeek = selectedWeek;
    _page = _centerPage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.hasClients) {
        _controller.jumpToPage(_centerPage);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _weekForPage(int page) => _anchorWeek.add(
    Duration(days: (page - _centerPage) * ScheduleWeek.span.inDays),
  );

  void _selectPage(int page) {
    _page = page;
    final int weekdayOffset = _selected
        .difference(ScheduleWeek.start(_selected))
        .inDays;
    widget.onDateSelected(
      _weekForPage(page).add(Duration(days: weekdayOffset)),
    );
  }

  void _moveWeek(int delta) {
    _controller.animateToPage(
      _page + delta,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(_selected.year - _datePickerYearSpan),
      lastDate: DateTime(_selected.year + _datePickerYearSpan, 12, 31),
      helpText: AppStrings.chooseDate,
    );
    if (picked != null) widget.onDateSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact =
            constraints.maxWidth < AppSizes.adaptiveModalBreakpoint;
        return Center(
          child: ConstrainedBox(
            key: const ValueKey<String>('schedule-week-navigator'),
            constraints: const BoxConstraints(
              maxWidth: AppSizes.scheduleNavigatorMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ScheduleWeekHeader(
                    compact: compact,
                    selected: _selected,
                    onPickDate: _pickDate,
                    onToday: () => widget.onDateSelected(DateTime.now()),
                    onPrevious: () => _moveWeek(-1),
                    onNext: () => _moveWeek(1),
                    showCancelled: widget.showCancelled,
                    onToggleCancelled: widget.onToggleCancelled,
                  ),
                  SizedBox(
                    height: AppSizes.scheduleWeekHeight,
                    child: PageView.builder(
                      controller: _controller,
                      onPageChanged: _selectPage,
                      itemBuilder: (BuildContext context, int page) {
                        final DateTime weekStart = _weekForPage(page);
                        return Row(
                          children: List<Widget>.generate(7, (int index) {
                            final DateTime date = weekStart.add(
                              Duration(days: index),
                            );
                            final DateTime normalized = ScheduleWeek.day(date);
                            return Expanded(
                              child: ScheduleDayButton(
                                date: date,
                                appointmentCount:
                                    widget.dayCounts[normalized] ?? 0,
                                selected: normalized == _selected,
                                today:
                                    normalized ==
                                    ScheduleWeek.day(DateTime.now()),
                                onPressed: () => widget.onDateSelected(date),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
