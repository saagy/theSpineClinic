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

String _$currentUserHash() => r'5d55231c7cad5febd44846a5c7718111d9e1c20c';

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

/// Family provider resolving staff profile by ID.

@ProviderFor(staffProfile)
final staffProfileProvider = StaffProfileFamily._();

/// Family provider resolving staff profile by ID.

final class StaffProfileProvider
    extends $FunctionalProvider<AsyncValue<Staff>, Staff, FutureOr<Staff>>
    with $FutureModifier<Staff>, $FutureProvider<Staff> {
  /// Family provider resolving staff profile by ID.
  StaffProfileProvider._({
    required StaffProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'staffProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$staffProfileHash();

  @override
  String toString() {
    return r'staffProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Staff> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Staff> create(Ref ref) {
    final argument = this.argument as String;
    return staffProfile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StaffProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$staffProfileHash() => r'efb956b6d6ae798dce5798b6daaa9774892826ce';

/// Family provider resolving staff profile by ID.

final class StaffProfileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Staff>, String> {
  StaffProfileFamily._()
    : super(
        retry: null,
        name: r'staffProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Family provider resolving staff profile by ID.

  StaffProfileProvider call(String staffId) =>
      StaffProfileProvider._(argument: staffId, from: this);

  @override
  String toString() => r'staffProfileProvider';
}
