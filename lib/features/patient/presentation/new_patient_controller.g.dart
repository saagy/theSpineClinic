// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_patient_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier provider handling form submission states for NewPatientScreen.

@ProviderFor(NewPatientController)
final newPatientControllerProvider = NewPatientControllerProvider._();

/// Notifier provider handling form submission states for NewPatientScreen.
final class NewPatientControllerProvider
    extends $AsyncNotifierProvider<NewPatientController, void> {
  /// Notifier provider handling form submission states for NewPatientScreen.
  NewPatientControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newPatientControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newPatientControllerHash();

  @$internal
  @override
  NewPatientController create() => NewPatientController();
}

String _$newPatientControllerHash() =>
    r'd8f6f59a811742cddcdf4c7dd6c5780729b9b11e';

/// Notifier provider handling form submission states for NewPatientScreen.

abstract class _$NewPatientController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
