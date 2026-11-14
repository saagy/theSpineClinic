import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_identity_line.dart';

void main() {
  test('the patient banner shows sex, age and date of birth that are known', () {
    final DateTime today = DateTime(2026, 11, 14);
    expect(
      patientIdentityLine(PatientPersonalDetails(gender: PatientGender.male, dateOfBirth: DateTime(1988, 11, 15)), today: today),
      'Male · 37 yrs · Nov 15, 1988',
    );
    expect(patientIdentityLine(PatientPersonalDetails(dateOfBirth: DateTime(2026, 11, 12)), today: today), 'Under 1 yr · Nov 12, 2026');
    expect(patientIdentityLine(const PatientPersonalDetails(), today: today), isNull);
  });
}
