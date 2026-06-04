// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [AuthRepository] backed by Supabase.

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

/// Provides the singleton [AuthRepository] backed by Supabase.

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// Provides the singleton [AuthRepository] backed by Supabase.
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'6ed94a3fa1de96f53f498a4824c553502b81a173';

/// Reactive authentication state holding the current [Staff] profile.
///
/// - `AsyncData(null)` → no authenticated user (redirect to login).
/// - `AsyncData(Staff)` → active, authenticated staff member.
/// - `AsyncLoading` → session resolution in progress (show splash).
/// - `AsyncError` → auth or network failure.
///
/// The router subscribes to this provider's state transitions to
/// drive its redirect engine without recursive re-evaluation.

@ProviderFor(CurrentUser)
final currentUserProvider = CurrentUserProvider._();

/// Reactive authentication state holding the current [Staff] profile.
///
/// - `AsyncData(null)` → no authenticated user (redirect to login).
/// - `AsyncData(Staff)` → active, authenticated staff member.
/// - `AsyncLoading` → session resolution in progress (show splash).
/// - `AsyncError` → auth or network failure.
///
/// The router subscribes to this provider's state transitions to
/// drive its redirect engine without recursive re-evaluation.
final class CurrentUserProvider
    extends $AsyncNotifierProvider<CurrentUser, Staff?> {
  /// Reactive authentication state holding the current [Staff] profile.
  ///
  /// - `AsyncData(null)` → no authenticated user (redirect to login).
  /// - `AsyncData(Staff)` → active, authenticated staff member.
  /// - `AsyncLoading` → session resolution in progress (show splash).
  /// - `AsyncError` → auth or network failure.
  ///
  /// The router subscribes to this provider's state transitions to
  /// drive its redirect engine without recursive re-evaluation.
  CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  CurrentUser create() => CurrentUser();
}

String _$currentUserHash() => r'fcbe777f8b6e1aaf2354c0e40b424b4160e9aa15';

/// Reactive authentication state holding the current [Staff] profile.
///
/// - `AsyncData(null)` → no authenticated user (redirect to login).
/// - `AsyncData(Staff)` → active, authenticated staff member.
/// - `AsyncLoading` → session resolution in progress (show splash).
/// - `AsyncError` → auth or network failure.
///
/// The router subscribes to this provider's state transitions to
/// drive its redirect engine without recursive re-evaluation.

abstract class _$CurrentUser extends $AsyncNotifier<Staff?> {
  FutureOr<Staff?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Staff?>, Staff?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Staff?>, Staff?>,
              AsyncValue<Staff?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
