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
  final List<String> doctorNames;

  const AppointmentWithPatient({
    required this.appointment,
    required this.patient,
    this.doctorName,
    this.doctorNames = const <String>[],
  });

  List<String> get allDoctorNames {
    if (doctorNames.isNotEmpty) return doctorNames;
    if (doctorName != null && doctorName!.trim().isNotEmpty) {
      return doctorName!
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  AppointmentWithPatient copyWith({
    Appointment? appointment,
    Patient? patient,
    String? doctorName,
    List<String>? doctorNames,
  }) {
    return AppointmentWithPatient(
      appointment: appointment ?? this.appointment,
      patient: patient ?? this.patient,
      doctorName: doctorName ?? this.doctorName,
      doctorNames: doctorNames ?? this.doctorNames,
    );
  }
}

/// Deterministic chronological comparator for [AppointmentWithPatient].
///
/// Compares by [scheduledAt] first.
/// Ties are broken by [createdAt] (booking order).
/// Any remaining ties are broken by [id] (UUID) to guarantee a 100% stable sort.
int compareAppointmentsChronologically(
  AppointmentWithPatient a,
  AppointmentWithPatient b, {
  bool ascending = true,
}) {
  final int timeComp = a.appointment.scheduledAt.compareTo(b.appointment.scheduledAt);
  if (timeComp != 0) return ascending ? timeComp : -timeComp;

  final int createdComp = a.appointment.createdAt.compareTo(b.appointment.createdAt);
  if (createdComp != 0) return ascending ? createdComp : -createdComp;

  final int idComp = a.appointment.id.compareTo(b.appointment.id);
  return ascending ? idComp : -idComp;
}

/// Deterministic chronological comparator for raw [Appointment] entities.
int compareRawAppointmentsChronologically(
  Appointment a,
  Appointment b, {
  bool ascending = true,
}) {
  final int timeComp = a.scheduledAt.compareTo(b.scheduledAt);
  if (timeComp != 0) return ascending ? timeComp : -timeComp;

  final int createdComp = a.createdAt.compareTo(b.createdAt);
  if (createdComp != 0) return ascending ? createdComp : -createdComp;

  final int idComp = a.id.compareTo(b.id);
  return ascending ? idComp : -idComp;
}

