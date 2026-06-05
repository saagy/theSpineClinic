/// Domain-layer contract for doctor replacement data operations.
///
/// Implementations live in `lib/features/replacements/data/`.
/// Rule 4 — every method returns `Result<T>`, never a raw future.
library;

import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

/// A lightweight view model pairing an appointment with its patient name.
class AffectedAppointmentItem {
  /// The appointment record for the absent doctor on the target date.
  final Appointment appointment;

  /// The patient's full name for display purposes.
  final String patientName;

  /// The patient model associated with the appointment.
  final Patient patient;

  /// Creates an [AffectedAppointmentItem].
  const AffectedAppointmentItem({
    required this.appointment,
    required this.patientName,
    required this.patient,
  });
}

/// Defines the replacement data operations available to the application.
///
/// The contract enforces that all Supabase-level errors are normalised
/// into [AppException] subtypes before being wrapped in [Result].
abstract class ReplacementRepository {
  /// Creates a new doctor replacement record.
  ///
  /// Returns the new row's UUID on success.
  Future<Result<String>> createReplacement({
    required String absentDoctorId,
    required String coveringDoctorId,
    required DateTime date,
    required String initiatedBy,
  });

  /// Fetches all active appointments for the absent doctor on the
  /// specified date, paired with patient names for checklist display.
  Future<Result<List<AffectedAppointmentItem>>>
      getAffectedAppointments({
    required String absentDoctorId,
    required DateTime date,
  });

  /// Performs the bulk swap for a list of appointment IDs:
  ///   1. Sets the absent doctor's `appointment_doctors` row to
  ///      `is_active = false`.
  ///   2. Inserts a new `appointment_doctors` row for the covering
  ///      doctor with `is_replacement = true`.
  ///
  /// Returns the count of successfully swapped appointments.
  Future<Result<int>> applyBulkSwap({
    required List<String> appointmentIds,
    required String absentDoctorId,
    required String coveringDoctorId,
    required String addedBy,
  });

  /// Checks whether a replacement already exists for the given doctor
  /// and date combination.
  Future<Result<bool>> replacementExists({
    required String absentDoctorId,
    required DateTime date,
  });

  /// Deletes an existing replacement for the given doctor and date
  /// so it can be re-created cleanly.
  Future<Result<void>> deleteExistingReplacement({
    required String absentDoctorId,
    required DateTime date,
  });
}
