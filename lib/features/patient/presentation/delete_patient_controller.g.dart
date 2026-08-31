// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_patient_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DeletePatientController)
final deletePatientControllerProvider = DeletePatientControllerProvider._();

final class DeletePatientControllerProvider
    extends $AsyncNotifierProvider<DeletePatientController, void> {
  DeletePatientControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletePatientControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletePatientControllerHash();

  @$internal
  @override
  DeletePatientController create() => DeletePatientController();
}

String _$deletePatientControllerHash() =>
    r'e9eb1906b62d42de6483d9e74f7dc8ab8db7292a';

abstract class _$DeletePatientController extends $AsyncNotifier<void> {
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
