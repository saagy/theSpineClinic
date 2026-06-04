/// Domain-layer contract for appointment data operations.
///
/// Implementations live in `lib/features/appointment/data/`.
/// Rule 4 — every method returns `Result<T>`, never a raw future.
library;

import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_doctor.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';

/// Defines the appointment data operations available to the application.
///
/// The contract enforces that all Supabase-level errors are normalised
/// into [AppException] subtypes before being wrapped in [Result].
abstract class AppointmentRepository {
  /// Fetches all active appointments for today, sorted by schedule time ascending.
  ///
  /// Today is calculated in UTC bounds from 00:00:00 to 23:59:59.
  Future<Result<List<Appointment>>> getAppointmentsForToday();

  /// Updates the status column of an appointment.
  ///
  /// Package deductions/refunds are handled automatically by the database trigger,
  /// so this method does not manually mutate patient balances.
  Future<Result<void>> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  );

  /// Queries all active doctors attached to a specific appointment.
  ///
  /// Active doctor assignments are those with `is_active = true`.
  Future<Result<List<AppointmentDoctor>>> getAppointmentDoctors(
    String appointmentId,
  );
}
