// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [AdminRepository] instance.

@ProviderFor(adminRepository)
final adminRepositoryProvider = AdminRepositoryProvider._();

/// Provides the singleton [AdminRepository] instance.

final class AdminRepositoryProvider
    extends
        $FunctionalProvider<AdminRepository, AdminRepository, AdminRepository>
    with $Provider<AdminRepository> {
  /// Provides the singleton [AdminRepository] instance.
  AdminRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdminRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdminRepository create(Ref ref) {
    return adminRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminRepository>(value),
    );
  }
}

String _$adminRepositoryHash() => r'a381c03f2f5f7ed783b43e8eb0efe017475c0739';
