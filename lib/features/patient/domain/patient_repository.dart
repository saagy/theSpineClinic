/// Domain-layer contract for patient data operations.
///
/// Implementations live in `lib/features/patient/data/`.
/// Rule 4 — every method returns `Result<T>`, never a raw future.
library;

import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

/// Defines the patient data operations available to the application.
///
/// The contract enforces that all Supabase-level errors are normalised
/// into [AppException] subtypes before being wrapped in [Result].
abstract class PatientRepository {
  /// Searches patients by name or phone number with optional clinic filter.
  ///
  /// The Supabase RLS policies enforce role-scoped visibility:
  /// doctors only see their assigned or replacement-covered patients;
  /// admins and receptionists see all patients.
  ///
  /// Results are ordered by `full_name` ascending and capped at 50.
  Future<Result<List<Patient>>> searchPatients({
    required String query,
    ClinicLocation? clinic,
  });

  /// Fetches a single patient record by its unique ID.
  Future<Result<Patient>> getPatientById(String id);

  /// Creates a new patient and assigns the given doctors.
  ///
  /// Inserts the patient row, retrieves the generated UUID, then
  /// inserts junction rows into `patient_doctors` for each doctor ID.
  Future<Result<Patient>> createPatient(
    Patient patient,
    List<String> assignedDoctorIds,
  );

  /// Updates core patient demographics (name, phone, program, clinic).
  Future<Result<void>> updatePatient(Patient patient);

  /// Syncs the patient-doctor assignments by diffing old vs new IDs.
  ///
  /// Deletes removed doctors and inserts newly assigned doctors
  /// into the `patient_doctors` junction table.
  Future<Result<void>> updatePatientDoctors(
    String patientId,
    List<String> currentDoctorIds,
  );

  /// Fetches all active/approved staff members with the role of doctor.
  Future<Result<List<Staff>>> getActiveDoctors();

  /// Fetches patients permanently assigned to the given doctor.
  Future<Result<List<Patient>>> getAssignedPatients({
    required String doctorId,
    String? query,
  });

  /// Fetches patients accessible today via active doctor replacements for the covering doctor.
  Future<Result<List<Patient>>> getReplacementPatients({
    required String doctorId,
    String? query,
  });

  /// Fetches active replacements for the given covering doctor today.
  Future<Result<List<Staff>>> getActiveReplacementsForDoctor({
    required String doctorId,
  });

  /// Fetches a mapping of patient ID to the absent doctor's name for coverage display.
  Future<Result<Map<String, String>>> getPatientReplacementMapping({
    required List<String> absentDoctorIds,
  });
}

