import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_assignments.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_shift.dart';

const _s = AppStrings.staffSchedule;
const _d = AppStrings.staffDetails;

/// A time of day in the device's 12/24-hour format.
String formatClock(BuildContext context, int minutes) =>
    MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));

String formatShiftHours(BuildContext context, StaffShift shift) =>
    _s.hours(formatClock(context, shift.startMinutes), formatClock(context, shift.endMinutes));

/// `Tagamoa · 10:00 AM – 2:00 PM`.
String formatShift(BuildContext context, StaffShift shift) => _s.shiftLabel(
  shift.branch.displayLabel,
  formatClock(context, shift.startMinutes),
  formatClock(context, shift.endMinutes),
);

/// Branch names joined for a sentence: `Tagamoa and Madinaty`.
String joinBranches(Iterable<ClinicLocation> branches) {
  final List<String> names = [for (final b in branches) b.displayLabel];
  if (names.length <= 1) return names.join();
  return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}

/// One plain sentence explaining a [ScheduleMismatch] for [name].
String describeMismatch(BuildContext context, String name, ScheduleMismatch mismatch) => switch (mismatch) {
  NotScheduledThatDay(:final weekday) => _s.notScheduledOn(name, _d.weekdayLong(weekday)),
  WorksElsewhereThatDay(:final weekday, :final branches) =>
    _s.worksElsewhereOn(name, _d.weekdayLong(weekday), joinBranches(branches)),
  OutsideShiftHours(:final shifts) =>
    _s.outsideHours(name, shifts.map((s) => formatShiftHours(context, s)).join(', ')),
};
