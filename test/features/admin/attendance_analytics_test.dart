import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_appointment_staff.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 7, 13, 12);

  test('past non-cancelled appointments are attendance eligible', () {
    expect(
      isAttendanceEligible(<String, dynamic>{
        'scheduled_at': DateTime.utc(2026, 7, 13, 10).toIso8601String(),
        'status': 'scheduled',
      }, now),
      isTrue,
    );
  });

  test('future and cancelled appointments are not attendance eligible', () {
    expect(
      isAttendanceEligible(<String, dynamic>{
        'scheduled_at': DateTime.utc(2026, 7, 13, 14).toIso8601String(),
        'status': 'scheduled',
      }, now),
      isFalse,
    );
    expect(
      isAttendanceEligible(<String, dynamic>{
        'scheduled_at': DateTime.utc(2026, 7, 13, 10).toIso8601String(),
        'status': 'cancelled',
      }, now),
      isFalse,
    );
  });
}
