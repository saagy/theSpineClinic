/// Domain-layer contract for appointment data operations.
///
/// Implementations live in `lib/features/appointment/data/`.
/// Rule 4 — every method returns `Result<T>`, never a raw future.
library;

import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_doctor.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';

import 'package:spine_clinic_app/features/patient/domain/patient.dart';

import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Defines the appointment data operations available to the application.
///
/// The contract enforces that all Supabase-level errors are normalised
/// into [AppException] subtypes before being wrapped in [Result].
abstract class AppointmentRepository {
  /// Fetches all active appointments for today, sorted by schedule time ascending.
  ///
  /// Today is calculated in UTC bounds from 00:00:00 to 23:59:59.
  Future<Result<List<Appointment>>> getAppointmentsForToday(ClinicLocation clinic);

  /// Updates the status column of an appointment.
  ///
  /// Package deductions/refunds are handled automatically by the database trigger,
  /// so this method does not manually mutate patient balances.
  Future<Result<void>> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  );

  /// Updates the notes column of an appointment.
  Future<Result<void>> updateAppointmentNotes(
    String appointmentId,
    String notes,
  );

  /// Queries all active doctors attached to a specific appointment.
  ///
  /// Active doctor assignments are those with `is_active = true`.
  Future<Result<List<AppointmentDoctor>>> getAppointmentDoctors(
    String appointmentId,
  );

  /// Creates a new appointment and returns its assigned ID.
  Future<Result<String>> createAppointment(Appointment appointment);

  /// Attaches a doctor to an appointment.
  Future<Result<void>> createAppointmentDoctor(AppointmentDoctor appointmentDoctor);

  /// Resolves the list of active doctors assigned to a patient.
  Future<Result<List<Staff>>> getAssignedDoctors(String patientId);

  /// Resolves the list of all appointments for a patient.
  Future<Result<List<Appointment>>> getAppointmentsForPatient(String patientId);

  /// Resolves the aggregate count of all future scheduled appointments for a patient.
  Future<Result<int>> getFutureScheduledAppointmentsCount(String patientId);

  /// Fetches a single appointment by its unique ID.
  Future<Result<Appointment>> getAppointmentById(String appointmentId);

  /// Fetches all appointment doctor records (active and inactive) for an appointment.
  ///
  /// Unlike [getAppointmentDoctors], this includes `is_active = false` rows
  /// required for the audit trail in the detail screen.
  Future<Result<List<AppointmentDoctor>>> getAllAppointmentDoctors(
    String appointmentId,
  );

  /// Fetches the active schedule (appointments where the doctor is active).
  Future<Result<List<DoctorScheduleItem>>> getDoctorSchedule(String doctorId);
}

/// Helper domain model wrapping a doctor's active appointment assignment
/// along with patient and covering details.
class DoctorScheduleItem {
  final Appointment appointment;
  final AppointmentDoctor appointmentDoctor;
  final Patient patient;
  final Staff? replacedDoctor;

  const DoctorScheduleItem({
    required this.appointment,
    required this.appointmentDoctor,
    required this.patient,
    this.replacedDoctor,
  });
}
