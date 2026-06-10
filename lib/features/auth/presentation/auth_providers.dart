/// Riverpod providers for the authentication feature.
///
/// Exposes:
/// - [authRepositoryProvider] — singleton [AuthRepository] instance.
/// - [currentUserProvider] — reactive [AsyncValue<Staff?>] notifier
///   that drives the router's redirect engine.
///
/// Rule 3 — all state via Riverpod, no setState.
/// Rule 4 — repository calls always return [Result<T>].
// ignore_for_file: avoid_print
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/auth/data/auth_repository_impl.dart';
import 'package:spine_clinic_app/features/auth/domain/auth_repository.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';

part 'auth_providers.g.dart';

/// Provides the singleton [AuthRepository] backed by Supabase.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    supabaseService: SupabaseService.instance,
  );
}

/// Reactive authentication state holding the current [Staff] profile.
///
/// - `AsyncData(null)` → no authenticated user (redirect to login).
/// - `AsyncData(Staff)` → active, authenticated staff member.
/// - `AsyncLoading` → session resolution in progress (show splash).
/// - `AsyncError` → auth or network failure.
///
/// The router subscribes to this provider's state transitions to
/// drive its redirect engine without recursive re-evaluation.
@Riverpod(keepAlive: true)
class CurrentUser extends _$CurrentUser {
  @override
  Future<Staff?> build() async {
    print('AUTH_PROVIDER: CurrentUser.build() started');
    final AuthRepository repo = ref.read(authRepositoryProvider);

    final isAuth = repo.isAuthenticated;
    print('AUTH_PROVIDER: isAuthenticated = $isAuth');
    if (!isAuth) {
      print('AUTH_PROVIDER: Not authenticated, returning null');
      return null;
    }

    print('AUTH_PROVIDER: Authenticated, fetching profile...');
    final Result<Staff?> result = await repo.getCurrentUserStaffProfile();
    print('AUTH_PROVIDER: Profile fetch completed');

    switch (result) {
      case Success<Staff?>(:final data):
        print('AUTH_PROVIDER: Profile fetch success: ${data?.fullName}');
        if (data != null && !data.isActive) {
          print('AUTH_PROVIDER: Account inactive, signing out...');
          await repo.signOut();
          return null;
        }
        return data;
      case Failure<Staff?>(:final exception):
        print('AUTH_PROVIDER: Profile fetch failure: $exception');
        throw exception;
    }
  }

  /// Authenticates and resolves the staff profile.
  ///
  /// If the resolved profile has `isActive == false`, the session is
  /// immediately cleared and an error state is emitted so the login
  /// screen can display the pending-approval banner.
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();

    final AuthRepository repo = ref.read(authRepositoryProvider);
    final Result<Staff> result =
        await repo.signInWithEmailAndPassword(email, password);

    switch (result) {
      case Success<Staff>(:final data):
        if (!data.isActive) {
          await repo.signOut();
          state = AsyncValue<Staff?>.error(
            const AuthException(
              code: 'auth/account-inactive',
              message: 'Account is pending admin approval.',
            ),
            StackTrace.current,
          );
          return;
        }
        state = AsyncValue<Staff?>.data(data);
      case Failure<Staff>(:final exception):
        state = AsyncValue<Staff?>.error(exception, StackTrace.current);
    }
  }

  /// Signs out and resets the state to unauthenticated.
  Future<void> logout() async {
    final AuthRepository repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const AsyncValue<Staff?>.data(null);
  }

  /// Clears any stale error state without changing the current data.
  ///
  /// Used before a new login attempt to prevent the UI from flashing
  /// a previous authentication error when correct credentials are entered.
  void clearError() {
    if (state.hasError) {
      state = const AsyncValue<Staff?>.data(null);
    }
  }
}

/// Family provider resolving staff profile by ID.
@riverpod
Future<Staff> staffProfile(Ref ref, String staffId) async {
  final AuthRepository repo = ref.read(authRepositoryProvider);
  final Result<Staff> result = await repo.getStaffProfile(staffId);
  switch (result) {
    case Success<Staff>(:final data):
      return data;
    case Failure<Staff>(:final exception):
      throw exception;
  }
}

