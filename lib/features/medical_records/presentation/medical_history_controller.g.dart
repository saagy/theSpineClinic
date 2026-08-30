// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_history_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller managing medical history mutations.

@ProviderFor(MedicalHistoryController)
final medicalHistoryControllerProvider = MedicalHistoryControllerProvider._();

/// Controller managing medical history mutations.
final class MedicalHistoryControllerProvider
    extends $NotifierProvider<MedicalHistoryController, AsyncValue<void>> {
  /// Controller managing medical history mutations.
  MedicalHistoryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'medicalHistoryControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$medicalHistoryControllerHash();

  @$internal
  @override
  MedicalHistoryController create() => MedicalHistoryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$medicalHistoryControllerHash() =>
    r'a7eec545452dd59ea67a531a74a6589c02fd5d30';

/// Controller managing medical history mutations.

abstract class _$MedicalHistoryController extends $Notifier<AsyncValue<void>> {
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
