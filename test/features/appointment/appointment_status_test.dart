import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';

void main() {
  test('appointment status exposes only the active workflow states', () {
    expect(AppointmentStatus.values.map((status) => status.dbValue), <String>[
      'scheduled',
      'checked_in',
      'cancelled',
    ]);
  });
}
