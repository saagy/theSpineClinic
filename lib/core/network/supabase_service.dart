/// Singleton wrapper around the Supabase client.
///
/// Every database or auth call in the application flows through this
/// service. It catches all raw Supabase exceptions and rethrows them
/// as typed [AppException] subtypes so that no upstream code ever
/// handles raw SDK errors directly.
///
/// Repositories call this service and wrap the result in [Result<T>].
library;

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart'
    as app_errors;

/// Provides safe access to Supabase auth, database, and storage.
///
/// Obtain the singleton via [SupabaseService.instance] after
/// [Supabase.initialize] has been called in `main.dart`.
class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  /// The underlying Supabase client.
  ///
  /// Private — all external access goes through typed helper methods
  /// that guarantee error normalisation.
  SupabaseClient get _client => Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Auth helpers
  // ---------------------------------------------------------------------------

  /// The current auth session, or `null` when signed out.
  Session? get currentSession => _client.auth.currentSession;

  /// The current authenticated user's ID, or `null` when signed out.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Whether a valid session currently exists.
  bool get isAuthenticated => currentSession != null;

  /// Signs in with email and password.
  ///
  /// Throws [app_errors.AuthException] on failure.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on Exception catch (error) {
      throw app_errors.AppException.fromSupabaseException(error);
    }
  }

  /// Creates a new auth user with email and password.
  ///
  /// Used during doctor self-registration (Section 8 of AGENT_CONTEXT).
  /// Throws [app_errors.AuthException] on failure.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email,
        password: password,
      );
    } on Exception catch (error) {
      throw app_errors.AppException.fromSupabaseException(error);
    }
  }

  /// Signs out the current user and clears the local session.
  ///
  /// Throws [app_errors.AuthException] on failure.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on Exception catch (error) {
      throw app_errors.AppException.fromSupabaseException(error);
    }
  }

  // ---------------------------------------------------------------------------
  // Database helpers
  // ---------------------------------------------------------------------------

  /// Returns a typed query builder for [table].
  ///
  /// Callers chain `.select()`, `.insert()`, etc. on the result.
  /// Use [guardQuery] for operations that need automatic error
  /// normalisation at execution time.
  SupabaseQueryBuilder from(String table) => _client.from(table);

  /// Executes a database RPC function.
  Future<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
  }) async {
    return _client.rpc(fn, params: params);
  }

  /// Executes an arbitrary async Supabase operation and normalises
  /// any thrown exception into an [app_errors.AppException].
  ///
  /// Usage in a repository:
  /// ```dart
  /// final data = await _service.guardQuery(
  ///   () => _service.from('patients').select().eq('id', id).single(),
  /// );
  /// return Result.success(Patient.fromJson(data));
  /// ```
  Future<T> guardQuery<T>(Future<T> Function() query) async {
    try {
      return await query();
    } on PostgrestException catch (error) {
      throw app_errors.AppException.fromSupabaseException(error);
    } on AuthException catch (error) {
      throw app_errors.AppException.fromSupabaseException(error);
    } on SocketException catch (error) {
      throw app_errors.AppException.fromSupabaseException(error);
    } on Exception catch (error) {
      throw app_errors.AppException.fromSupabaseException(error);
    }
  }

  // ---------------------------------------------------------------------------
  // Storage helpers
  // ---------------------------------------------------------------------------

  /// Returns a reference to the given storage [bucket].
  ///
  /// Used by the patient documents feature to upload and retrieve
  /// files from Supabase Storage.
  StorageFileApi storage(String bucket) => _client.storage.from(bucket);

  // ---------------------------------------------------------------------------
  // Realtime (placeholder for future use)
  // ---------------------------------------------------------------------------

  /// Subscribes to realtime changes on [table].
  ///
  /// Returns the channel so callers can unsubscribe when disposing.
  RealtimeChannel realtimeChannel(String table) =>
      _client.channel('public:$table');

  // ---------------------------------------------------------------------------
  // Admin helpers (requires service_role key — server-side only)
  // ---------------------------------------------------------------------------

  /// Provides direct access to the admin auth API.
  ///
  /// Used exclusively for the doctor rejection flow (Section 8):
  /// deleting a Supabase Auth user after rejecting their registration.
  ///
  /// **WARNING**: This requires initialisation with the service_role key,
  /// which must never be shipped in client bundles. Guard usage behind
  /// a super_admin role check.
  GoTrueAdminApi get adminAuth => _client.auth.admin;

  // ---------------------------------------------------------------------------
  // Patient Notes helpers
  // ---------------------------------------------------------------------------

  /// Fetches notes for a patient by [patientId] ordered by created_at DESC.
  Future<List<Map<String, dynamic>>> getPatientNotes(String patientId) async {
    return guardQuery(() => _client
        .from('patient_notes')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false));
  }

  /// Inserts a new patient note.
  Future<Map<String, dynamic>> insertPatientNote(
    Map<String, dynamic> note,
  ) async {
    return guardQuery(() => _client
        .from('patient_notes')
        .insert(note)
        .select()
        .single());
  }

  /// Fetches a note linked to a specific appointment.
  Future<Map<String, dynamic>?> getNoteByAppointmentId(
    String appointmentId,
  ) async {
    return guardQuery(() async {
      final List<Map<String, dynamic>> rows = await _client
          .from('patient_notes')
          .select()
          .eq('appointment_id', appointmentId)
          .limit(1);
      return rows.isEmpty ? null : rows.first;
    });
  }
}
