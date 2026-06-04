/// Data-layer implementation of [AuthRepository] backed by Supabase.
///
/// All raw Supabase exceptions are caught and normalised into
/// [AppException] subtypes before wrapping in [Result].
///
/// Rule 2 — no Supabase calls inside widgets; all access here.
/// Rule 4 — every method returns `Result<T>`.
library;

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
      final response = await _service.signUpWithEmail(
        email: email,
        password: password,
      );

      final String? userId = response.user?.id;
      if (userId == null) {
        return const Result.failure(
          AuthException(
            code: 'auth/registration-failed',
            message: 'Sign-up succeeded but no user ID was returned.',
          ),
        );
      }

      await _service.guardQuery(
        () => _service.from(_staffTable).insert({
          'user_id': userId,
          'full_name': fullName,
          'email': email,
          'role': 'doctor',
          'is_active': false,
        }),
      );

      // Clear the session — doctor must NOT be logged in after registration.
      await _service.signOut();

      return const Result.success(null);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }
}
