/// Employment details for one staff member, from `public.staff_details`.
/// Super admins read and change them; head receptionists read them for
/// colleagues who share a branch. Working days and hours live in
/// `StaffSchedule` (per branch) instead.
class StaffDetails {
  StaffDetails({this.nationalId, this.birthDate, this.hireDate, this.updatedAt, this.updatedById});

  static final StaffDetails empty = StaffDetails();

  factory StaffDetails.fromJson(Map<String, dynamic> json) => StaffDetails(
    nationalId: json['national_id'] as String?,
    birthDate: _day(json['birth_date']),
    hireDate: _day(json['hire_date']),
    updatedAt: json['updated_at'] is String ? DateTime.parse(json['updated_at'] as String).toLocal() : null,
    updatedById: json['updated_by'] as String?,
  );

  /// Egyptian national ID: 14 digits.
  final String? nationalId;
  final DateTime? birthDate;
  final DateTime? hireDate;

  /// When and by whom the details were last saved; not compared or sent.
  final DateTime? updatedAt;
  final String? updatedById;

  bool get isEmpty => nationalId == null && birthDate == null && hireDate == null;

  Map<String, Object?> toJson() => {
    'national_id': nationalId ?? '',
    'birth_date': birthDate == null ? '' : _iso(birthDate!),
    'hire_date': hireDate == null ? '' : _iso(hireDate!),
  };

  static DateTime? _day(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final DateTime parsed = DateTime.parse(value);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
  static String _iso(DateTime day) => '${day.year.toString().padLeft(4, '0')}-${_two(day.month)}-${_two(day.day)}';

  @override
  bool operator ==(Object other) =>
      other is StaffDetails &&
      other.nationalId == nationalId &&
      other.birthDate == birthDate &&
      other.hireDate == hireDate;

  @override
  int get hashCode => Object.hash(nationalId, birthDate, hireDate);
}
