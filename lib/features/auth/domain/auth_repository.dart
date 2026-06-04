/// Domain-layer contract for authentication operations.
///
/// Implementations live in `lib/features/auth/data/`.
/// Rule 4 — every method returns `Result<T>`, never a raw future.
library;

import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';

/// Defines the authentication operations available to the application.
///
/// The contract enforces that all Supabase-level errors are normalised
/// into [AppException] subtypes before being wrapped in [Result].
abstract class AuthRepository {
  /// Authenticates with email / password and resolves the staff profile.
  ///
  /// Returns the matching `public.staff` row for the authenticated user.
  Future<Result<Staff>> signInWithEmailAndPassword(
    String email,
    String password,
  );

  /// Clears the current Supabase session.
  Future<Result<void>> signOut();

  /// Resolves the staff profile for the currently authenticated user.
  ///
  /// Returns `null` inside [Result] when no session exists or when no
  /// matching `public.staff` row is found for `auth.uid()`.
  Future<Result<Staff?>> getCurrentUserStaffProfile();

  /// Registers a new doctor: creates a Supabase Auth user AND inserts
  /// a `public.staff` row with `role = 'doctor'` and `is_active = false`.
  ///
  /// The session is cleared immediately after — the user is NOT left
  /// logged in (AGENT_CONTEXT §8).
  Future<Result<void>> registerDoctor({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });
}
