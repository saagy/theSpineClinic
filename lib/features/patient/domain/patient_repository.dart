/// Domain-layer contract for patient data operations.
///
/// Implementations live in `lib/features/patient/data/`.
/// Rule 4 — every method returns `Result<T>`, never a raw future.
library;

import 'package:spine_clinic_app/core/errors/result.dart';
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
}
