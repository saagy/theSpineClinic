// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_patient_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod presentation controller coordinating patient updates.
///
/// Inherits AsyncNotifier to represent transaction lifecycle: loading, success, error.

@ProviderFor(EditPatientController)
final editPatientControllerProvider = EditPatientControllerProvider._();

/// Riverpod presentation controller coordinating patient updates.
///
/// Inherits AsyncNotifier to represent transaction lifecycle: loading, success, error.
final class EditPatientControllerProvider
    extends $AsyncNotifierProvider<EditPatientController, void> {
  /// Riverpod presentation controller coordinating patient updates.
  ///
  /// Inherits AsyncNotifier to represent transaction lifecycle: loading, success, error.
  EditPatientControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editPatientControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editPatientControllerHash();

  @$internal
  @override
  EditPatientController create() => EditPatientController();
}

String _$editPatientControllerHash() =>
    r'782a0587da171f0dc6f4689e63547ac33c6ac9db';

/// Riverpod presentation controller coordinating patient updates.
///
/// Inherits AsyncNotifier to represent transaction lifecycle: loading, success, error.

abstract class _$EditPatientController extends $AsyncNotifier<void> {
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
