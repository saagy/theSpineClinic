import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// One weekly shift at one branch, from `public.staff_shifts`.
class StaffShift {
  const StaffShift({
    required this.branch,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
  });

  /// Null for a branch this version of the app does not know.
  static StaffShift? tryFromJson(Map<String, dynamic> json) {
    final ClinicLocation? branch = ClinicLocation.fromDbValue(json['branch'] as String?);
    if (branch == null) return null;
    return StaffShift(
      branch: branch,
      weekday: (json['weekday'] as num).toInt(),
      startMinutes: _minutes(json['starts_at'] as String),
      endMinutes: _minutes(json['ends_at'] as String),
    );
  }

  final ClinicLocation branch;

  /// ISO weekday: Monday = 1 ... Sunday = 7.
  final int weekday;

  /// Minutes after midnight; the end is after the start.
  final int startMinutes;
  final int endMinutes;

  /// The clinic week starts on Saturday.
  static const List<int> weekOrder = [6, 7, 1, 2, 3, 4, 5];

  /// Whether [minute] (after midnight) falls inside the shift. The end
  /// minute itself is outside, so back-to-back shifts never both cover it.
  bool covers(int minute) => minute >= startMinutes && minute < endMinutes;

  bool overlaps(StaffShift other) =>
      other.weekday == weekday &&
      other.startMinutes < endMinutes &&
      startMinutes < other.endMinutes;

  StaffShift copyWith({ClinicLocation? branch, int? weekday, int? startMinutes, int? endMinutes}) =>
      StaffShift(
        branch: branch ?? this.branch,
        weekday: weekday ?? this.weekday,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
      );

  Map<String, Object> toJson() => {
    'branch': branch.dbValue,
    'weekday': weekday,
    'starts_at': _clock(startMinutes),
    'ends_at': _clock(endMinutes),
  };

  /// Clinic-week order (Saturday first), then by start time.
  static int compare(StaffShift a, StaffShift b) {
    final int day = weekOrder.indexOf(a.weekday).compareTo(weekOrder.indexOf(b.weekday));
    return day != 0 ? day : a.startMinutes.compareTo(b.startMinutes);
  }

  static int _minutes(String value) {
    final List<String> parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
  static String _clock(int minutes) => '${_two(minutes ~/ 60)}:${_two(minutes % 60)}';

  @override
  bool operator ==(Object other) =>
      other is StaffShift &&
      other.branch == branch &&
      other.weekday == weekday &&
      other.startMinutes == startMinutes &&
      other.endMinutes == endMinutes;

  @override
  int get hashCode => Object.hash(branch, weekday, startMinutes, endMinutes);
}
