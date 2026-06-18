/// Data-layer implementation of [AuthRepository] backed by Supabase.
///
/// All raw Supabase exceptions are caught and normalised into
/// [AppException] subtypes before wrapping in [Result].
///
/// Rule 2 — no Supabase calls inside widgets; all access here.
/// Rule 4 — every method returns `Result<T>`.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, UserAttributes;
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/auth/domain/auth_repository.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';

/// Supabase-backed [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  /// Creates an [AuthRepositoryImpl].
  AuthRepositoryImpl({required SupabaseService supabaseService})
      : _service = supabaseService;

  final SupabaseService _service;

  /// Table name constant — avoids magic strings in queries.
  static const String _staffTable = 'staff';

  @override
  bool get isAuthenticated => _service.isAuthenticated;

  @override
  Future<Result<Staff>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      await _service.signInWithEmail(email: email, password: password);

      final String? userId = _service.currentUserId;
      if (userId == null) {
        return const Result.failure(
          AuthException(
            code: 'auth/no-user-after-sign-in',
            message: 'Sign-in succeeded but no user ID was returned.',
          ),
        );
      }

      final Map<String, dynamic> row = await _service.guardQuery(
        () => _service
            .from(_staffTable)
            .select()
            .eq('user_id', userId)
            .single(),
      );

      return Result.success(Staff.fromJson(row));
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _service.signOut();
      return const Result.success(null);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<Staff?>> getCurrentUserStaffProfile() async {
    try {
      final String? userId = _service.currentUserId;
      if (userId == null) {
        return const Result.success(null);
      }

      final List<Map<String, dynamic>> rows = await _service.guardQuery(
        () => _service
            .from(_staffTable)
            .select()
            .eq('user_id', userId),
      );

      if (rows.isEmpty) {
        return const Result.success(null);
      }

      return Result.success(Staff.fromJson(rows.first));
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<void>> registerDoctor({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      debugPrint('REGISTER: Starting signup for $email');
      final response = await _service.signUpWithEmail(
        email: email,
        password: password,
      );

      final String? userId = response.user?.id;
      debugPrint('REGISTER: signUp returned userId=$userId');
      debugPrint(
        'REGISTER: session exists=${response.session != null}',
      );

      if (userId == null) {
        return const Result.failure(
          AuthException(
            code: 'auth/registration-failed',
            message: 'Sign-up succeeded but no user ID was returned.',
          ),
        );
      }

      // Verify we have an active session before inserting into staff.
      // Without a session the RLS INSERT policy (requires `authenticated`
      // role) will reject the request with HTTP 401.
      if (!_service.isAuthenticated) {
        debugPrint(
          'REGISTER: No session after signUp — email confirmation '
          'may be enabled in Supabase. Cannot insert staff row.',
        );
        return const Result.failure(
          AuthException(
            code: 'auth/no-session-after-signup',
            message:
                'Registration created but email confirmation is required. '
                'Please ask your administrator to disable email confirmation '
                'in the Supabase Dashboard, or confirm your email first.',
            userMessageKey: 'error_auth_email_not_confirmed',
          ),
        );
      }

      debugPrint('REGISTER: Inserting staff row for $userId');
      await _service.guardQuery(
        () => _service.from(_staffTable).insert({
          'user_id': userId,
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'role': 'doctor',
          'is_active': false,
        }),
      );

      debugPrint('REGISTER: Staff row inserted, signing out');
      // Clear the session — doctor must NOT be logged in after registration.
      await _service.signOut();

      debugPrint('REGISTER: Registration complete');
      return const Result.success(null);
    } on AppException catch (error) {
      debugPrint('REGISTER: AppException — ${error.code}: ${error.message}');
      return Result.failure(error);
    } on Exception catch (error) {
      debugPrint('REGISTER: Exception — $error');
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<Staff>> getStaffProfile(String staffId) async {
    try {
      final Map<String, dynamic> row = await _service.guardQuery(
        () => _service
            .from(_staffTable)
            .select()
            .eq('id', staffId)
            .single(),
      );
      return Result.success(Staff.fromJson(row));
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<void>> updateStaffProfile({
    required Staff staff,
    String? newPassword,
  }) async {
    try {
      await _service.guardQuery(
        () => _service.from(_staffTable).update({
          'full_name': staff.fullName,
          'email': staff.email,
          'phone': staff.phone,
          'branch': staff.branch?.dbValue,
        }).eq('id', staff.id),
      );

      if (newPassword != null && newPassword.isNotEmpty) {
        // Self password change — use Supabase Auth API directly.
        // The RPC requires super_admin; the Auth API lets any
        // authenticated user change their own password.
        if (staff.userId == _service.currentUserId) {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(password: newPassword),
          );
        } else {
          // Admin-initiated password change for another user — uses RPC.
          await _service.guardQuery(
            () => _service.rpc('update_user_password', params: {
              'target_user_id': staff.userId,
              'new_password': newPassword,
            }),
          );
        }
      }

      return const Result.success(null);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }
}

