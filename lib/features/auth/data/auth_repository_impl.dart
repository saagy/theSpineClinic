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
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

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
    // Track whether auth sign-in succeeded so we can clean up the session
    // if the staff lookup fails (e.g. account is inactive).
    bool authSucceeded = false;
    try {
      await _service.signInWithEmail(email: email, password: password);
      authSucceeded = true;

      final String? userId = _service.currentUserId;
      if (userId == null) {
        return const Result.failure(
          AuthException(
            code: 'auth/no-user-after-sign-in',
            message: 'Sign-in succeeded but no user ID was returned.',
          ),
        );
      }

      // Only return the staff profile if the account is active.
      // Inactive / pending-approval accounts receive a clear error
      // and their auth session is discarded below.
      final Map<String, dynamic> row = await _service.guardQuery(
        () => _service
            .from(_staffTable)
            .select()
            .eq('user_id', userId)
            .eq('is_active', true)
            .single(),
      );

      return Result.success(Staff.fromJson(row));
    } on AppException catch (error) {
      // If the auth call created a session but the staff lookup failed
      // (inactive account, missing profile, etc.), discard the session
      // so the user cannot use the token directly.
      if (authSucceeded) {
        try {
          await _service.signOut();
        } catch (_) {
          // Best-effort — the session is short-lived regardless.
        }
      }
      return Result.failure(error);
    } on Exception catch (error) {
      if (authSucceeded) {
        try {
          await _service.signOut();
        } catch (_) {}
      }
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
            .eq('user_id', userId)
            .eq('is_active', true),
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
  Future<Result<void>> registerStaff({
    required UserRole role,
    required String fullName,
    required String email,
    required String phone,
    required String password,
    ClinicLocation? branch,
  }) async {
    try {
      debugPrint('REGISTER: Starting atomic registration for $email as ${role.dbValue}');
      await _service.guardQuery(
        () => _service.rpc(
          'register_doctor_application',
          params: {
            'p_email': email,
            'p_password': password,
            'p_full_name': fullName,
            'p_phone': phone,
            'p_role': role.dbValue,
            'p_branch': branch?.dbValue,
          },
        ),
      );
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

      await _service.guardQuery(
        () => _service.from(_staffTable).update({
          'full_name': staff.fullName,
          'email': staff.email,
          'phone': staff.phone,
          'branch': staff.branch?.dbValue,
        }).eq('id', staff.id),
      );

      return const Result.success(null);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }
}

