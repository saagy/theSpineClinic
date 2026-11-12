import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_details.dart';

const _t = AppStrings.staffDetails;

/// Working days and hours in one line, such as `Sat–Thu · 9:00 AM – 5:00 PM`.
/// Three or more days in a row (Saturday first) read as a range. Null when
/// neither is recorded.
String? staffScheduleLabel(BuildContext context, StaffDetails? details) {
  if (details == null) return null;
  final List<int> days = details.workingDaysInWeekOrder;
  final List<String> parts = [];
  if (days.length == StaffDetails.weekOrder.length) {
    parts.add(_t.everyDay);
  } else if (days.isNotEmpty) {
    final List<String> runs = [];
    int start = 0;
    for (int index = 1; index <= days.length; index++) {
      final bool continues = index < days.length &&
          StaffDetails.weekOrder.indexOf(days[index]) ==
              StaffDetails.weekOrder.indexOf(days[index - 1]) + 1;
      if (continues) continue;
      final List<int> run = days.sublist(start, index);
      runs.add(run.length >= 3
          ? _t.dayRange(_t.weekday(run.first), _t.weekday(run.last))
          : run.map(_t.weekday).join(', '));
      start = index;
    }
    parts.add(runs.join(', '));
  }
  if (details.hasHours) {
    String clock(int minutes) => MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    parts.add(_t.hours(clock(details.workStartMinutes!), clock(details.workEndMinutes!)));
  }
  return parts.isEmpty ? null : parts.join(' · ');
}
