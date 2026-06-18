// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Exposes the global, pre-initialized [SharedPreferences] instance.

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// Exposes the global, pre-initialized [SharedPreferences] instance.

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferences,
          SharedPreferences,
          SharedPreferences
        >
    with $Provider<SharedPreferences> {
  /// Exposes the global, pre-initialized [SharedPreferences] instance.
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferences create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'd8a123f8131dddc25218cf0b7e15eff43b58543c';

/// Exposes the [LocalSettingsService] backend.

@ProviderFor(localSettingsService)
final localSettingsServiceProvider = LocalSettingsServiceProvider._();

/// Exposes the [LocalSettingsService] backend.

final class LocalSettingsServiceProvider
    extends
        $FunctionalProvider<
          LocalSettingsService,
          LocalSettingsService,
          LocalSettingsService
        >
    with $Provider<LocalSettingsService> {
  /// Exposes the [LocalSettingsService] backend.
  LocalSettingsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localSettingsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localSettingsServiceHash();

  @$internal
  @override
  $ProviderElement<LocalSettingsService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalSettingsService create(Ref ref) {
    return localSettingsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalSettingsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalSettingsService>(value),
    );
  }
}

String _$localSettingsServiceHash() =>
    r'42964dd9bd7854d025bc96114ab5b3e98a23b617';

/// Active branch state notifier. Synchronously exposes choices and persists updates.

@ProviderFor(ActiveBranch)
final activeBranchProvider = ActiveBranchProvider._();

/// Active branch state notifier. Synchronously exposes choices and persists updates.
final class ActiveBranchProvider
    extends $NotifierProvider<ActiveBranch, ClinicLocation> {
  /// Active branch state notifier. Synchronously exposes choices and persists updates.
  ActiveBranchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeBranchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeBranchHash();

  @$internal
  @override
  ActiveBranch create() => ActiveBranch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClinicLocation value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClinicLocation>(value),
    );
  }
}

String _$activeBranchHash() => r'40a969281b1bbc38fdbb161a4ea16abd4c4f77f4';

/// Active branch state notifier. Synchronously exposes choices and persists updates.

abstract class _$ActiveBranch extends $Notifier<ClinicLocation> {
  ClinicLocation build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ClinicLocation, ClinicLocation>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClinicLocation, ClinicLocation>,
              ClinicLocation,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
