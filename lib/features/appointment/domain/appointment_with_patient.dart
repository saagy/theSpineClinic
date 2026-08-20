import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_doctor.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

/// Helper domain model wrapping a doctor's active appointment assignment.
class DoctorScheduleItem {
  final Appointment appointment;
  final AppointmentDoctor appointmentDoctor;
  final Patient patient;

  const DoctorScheduleItem({
    required this.appointment,
    required this.appointmentDoctor,
    required this.patient,
  });
}

/// Lightweight wrapper combining an appointment with its patient for list views.
class AppointmentWithPatient {
  final Appointment appointment;
  final Patient patient;
  final String? doctorName;

  const AppointmentWithPatient({
    required this.appointment,
    required this.patient,
    this.doctorName,
  });
}
