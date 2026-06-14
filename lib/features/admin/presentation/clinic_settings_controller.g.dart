// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinic_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller managing update mutations for the clinic settings packages.

@ProviderFor(ClinicSettingsAction)
final clinicSettingsActionProvider = ClinicSettingsActionProvider._();

/// Controller managing update mutations for the clinic settings packages.
final class ClinicSettingsActionProvider
    extends $NotifierProvider<ClinicSettingsAction, AsyncValue<void>> {
  /// Controller managing update mutations for the clinic settings packages.
  ClinicSettingsActionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clinicSettingsActionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clinicSettingsActionHash();

  @$internal
  @override
  ClinicSettingsAction create() => ClinicSettingsAction();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$clinicSettingsActionHash() =>
    r'08c5a92255bf826c523a63214f62db97836c7b3f';

/// Controller managing update mutations for the clinic settings packages.

abstract class _$ClinicSettingsAction extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
