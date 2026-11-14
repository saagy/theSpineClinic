import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_shift.dart';

/// One person's branches and weekly shifts, as the staff editor saves them.
class StaffSchedule {
  StaffSchedule({Iterable<ClinicLocation> branches = const [], Iterable<StaffShift> shifts = const []})
    : branches = List.unmodifiable(
        ClinicLocation.values.where(branches.toSet().contains),
      ),
      shifts = List.unmodifiable(shifts.toList()..sort(StaffShift.compare));

  static final StaffSchedule empty = StaffSchedule();

  /// In [ClinicLocation.values] order.
  final List<ClinicLocation> branches;

  /// In clinic-week order, then by start time.
  final List<StaffShift> shifts;

  bool get isEmpty => branches.isEmpty && shifts.isEmpty;

  List<StaffShift> shiftsOn(int weekday) =>
      [for (final shift in shifts) if (shift.weekday == weekday) shift];

  /// Branches change; shifts at a removed branch go with it.
  StaffSchedule withBranches(Iterable<ClinicLocation> next) {
    final Set<ClinicLocation> kept = next.toSet();
    return StaffSchedule(
      branches: kept,
      shifts: shifts.where((shift) => kept.contains(shift.branch)),
    );
  }

  StaffSchedule withShifts(Iterable<StaffShift> next) => StaffSchedule(branches: branches, shifts: next);

  /// Keys added to the staff account payload.
  Map<String, Object> toJson() => {
    'branches': [for (final branch in branches) branch.dbValue],
    'shifts': [for (final shift in shifts) shift.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is StaffSchedule && _same(other.branches, branches) && _same(other.shifts, shifts);

  static bool _same<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(branches), Object.hashAll(shifts));
}

/// Every staff member's branches and shifts, keyed by staff ID.
class StaffAssignments {
  const StaffAssignments({this.branches = const {}, this.shifts = const {}});

  static const StaffAssignments none = StaffAssignments();

  final Map<String, List<ClinicLocation>> branches;
  final Map<String, List<StaffShift>> shifts;

  List<ClinicLocation> branchesOf(String staffId) => branches[staffId] ?? const [];
  List<StaffShift> shiftsOf(String staffId) => shifts[staffId] ?? const [];
  bool hasBranches(String staffId) => branchesOf(staffId).isNotEmpty;

  /// Whether [staffId] belongs at [branch]. People with no branches yet count
  /// as everywhere, so nobody disappears from a picker before being assigned.
  bool worksAt(String staffId, ClinicLocation branch) {
    final List<ClinicLocation> mine = branchesOf(staffId);
    return mine.isEmpty || mine.contains(branch);
  }

  StaffSchedule scheduleOf(String staffId) =>
      StaffSchedule(branches: branchesOf(staffId), shifts: shiftsOf(staffId));
}

/// Why a booking falls outside a doctor's usual schedule.
sealed class ScheduleMismatch {
  const ScheduleMismatch();
}

/// No shift at all on that weekday.
class NotScheduledThatDay extends ScheduleMismatch {
  const NotScheduledThatDay(this.weekday);
  final int weekday;
}

/// Working that day, but only at other branches.
class WorksElsewhereThatDay extends ScheduleMismatch {
  const WorksElsewhereThatDay(this.weekday, this.branches);
  final int weekday;
  final List<ClinicLocation> branches;
}

/// At this branch that day, but not at that time.
class OutsideShiftHours extends ScheduleMismatch {
  const OutsideShiftHours(this.shifts);
  final List<StaffShift> shifts;
}

/// The mismatch between [shifts] and a visit at [branch] starting at
/// [start] (clinic local time), or null when it fits or there is no schedule
/// to compare with. Schedules never block a booking; this only explains.
ScheduleMismatch? scheduleMismatch(List<StaffShift> shifts, ClinicLocation branch, DateTime start) {
  if (shifts.isEmpty) return null;
  final List<StaffShift> sameDay = [for (final s in shifts) if (s.weekday == start.weekday) s];
  if (sameDay.isEmpty) return NotScheduledThatDay(start.weekday);
  final List<StaffShift> here = [for (final s in sameDay) if (s.branch == branch) s];
  if (here.isEmpty) {
    return WorksElsewhereThatDay(start.weekday, {for (final s in sameDay) s.branch}.toList());
  }
  final int minute = start.hour * 60 + start.minute;
  return here.any((s) => s.covers(minute)) ? null : OutsideShiftHours(here);
}
