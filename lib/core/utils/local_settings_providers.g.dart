// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_settings_providers.dart';

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

/// Exposes the local settings persistence backend.

@ProviderFor(localSettingsService)
final localSettingsServiceProvider = LocalSettingsServiceProvider._();

/// Exposes the local settings persistence backend.

final class LocalSettingsServiceProvider
    extends
        $FunctionalProvider<
          LocalSettingsService,
          LocalSettingsService,
          LocalSettingsService
        >
    with $Provider<LocalSettingsService> {
  /// Exposes the local settings persistence backend.
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
