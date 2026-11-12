/// Reference details for one staff member, from `public.staff_details`.
/// They are for reference only and never restrict bookings. Only active
/// super admins can read or change them.
class StaffDetails {
  StaffDetails({
    this.nationalId,
    this.birthDate,
    this.hireDate,
    Iterable<int> workingDays = const [],
    this.workStartMinutes,
    this.workEndMinutes,
  }) : workingDays = List.unmodifiable(workingDays.toSet().toList()..sort());

  static final StaffDetails empty = StaffDetails();

  factory StaffDetails.fromJson(Map<String, dynamic> json) => StaffDetails(
    nationalId: json['national_id'] as String?,
    birthDate: _day(json['birth_date']),
    hireDate: _day(json['hire_date']),
    workingDays: [for (final day in json['working_days'] as List? ?? const []) (day as num).toInt()],
    workStartMinutes: _minutes(json['work_starts_at']),
    workEndMinutes: _minutes(json['work_ends_at']),
  );

  /// Egyptian national ID: 14 digits.
  final String? nationalId;
  final DateTime? birthDate;
  final DateTime? hireDate;

  /// ISO weekdays, Monday = 1 ... Sunday = 7, sorted.
  final List<int> workingDays;

  /// Minutes after midnight; both are set or neither.
  final int? workStartMinutes;
  final int? workEndMinutes;

  /// The clinic week starts on Saturday.
  static const List<int> weekOrder = [6, 7, 1, 2, 3, 4, 5];

  bool get hasHours => workStartMinutes != null && workEndMinutes != null;

  bool get isEmpty =>
      nationalId == null &&
      birthDate == null &&
      hireDate == null &&
      workingDays.isEmpty &&
      !hasHours;

  /// Days in clinic-week order, Saturday first.
  List<int> get workingDaysInWeekOrder =>
      [for (final day in weekOrder) if (workingDays.contains(day)) day];

  Map<String, Object?> toJson() => {
    'national_id': nationalId ?? '',
    'birth_date': birthDate == null ? '' : _iso(birthDate!),
    'hire_date': hireDate == null ? '' : _iso(hireDate!),
    'working_days': workingDays,
    'work_starts_at': workStartMinutes == null ? '' : _clock(workStartMinutes!),
    'work_ends_at': workEndMinutes == null ? '' : _clock(workEndMinutes!),
  };

  static DateTime? _day(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final DateTime parsed = DateTime.parse(value);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static int? _minutes(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final List<String> parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
  static String _iso(DateTime day) => '${day.year.toString().padLeft(4, '0')}-${_two(day.month)}-${_two(day.day)}';
  static String _clock(int minutes) => '${_two(minutes ~/ 60)}:${_two(minutes % 60)}';

  @override
  bool operator ==(Object other) =>
      other is StaffDetails &&
      other.nationalId == nationalId &&
      other.birthDate == birthDate &&
      other.hireDate == hireDate &&
      _sameDays(other.workingDays, workingDays) &&
      other.workStartMinutes == workStartMinutes &&
      other.workEndMinutes == workEndMinutes;

  static bool _sameDays(List<int> a, List<int> b) =>
      a.length == b.length && [for (int i = 0; i < a.length; i++) a[i] == b[i]].every((same) => same);

  @override
  int get hashCode => Object.hash(
    nationalId, birthDate, hireDate, Object.hashAll(workingDays), workStartMinutes, workEndMinutes,
  );
}
