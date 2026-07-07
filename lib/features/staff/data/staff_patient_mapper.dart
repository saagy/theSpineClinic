import 'package:spine_clinic_app/core/utils/patient_helpers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

Patient buildPatientWithLastVisit(Map<String, dynamic> row) {
  final patient = Patient.fromJson(row);
  final appointments = row['appointments'];
  if (appointments is! List) return patient;
  final rows = appointments.whereType<Map<String, dynamic>>().toList();
  return patient.copyWith(
    lastAppointmentDate: computeLastAppointmentDate(rows),
  );
}
