// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_next_visit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller backing the patient detail's tappable Next-visit stat.

@ProviderFor(PatientNextVisitController)
final patientNextVisitControllerProvider =
    PatientNextVisitControllerProvider._();

/// Controller backing the patient detail's tappable Next-visit stat.
final class PatientNextVisitControllerProvider
    extends
        $NotifierProvider<PatientNextVisitController, PatientNextVisitState> {
  /// Controller backing the patient detail's tappable Next-visit stat.
  PatientNextVisitControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'patientNextVisitControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$patientNextVisitControllerHash();

  @$internal
  @override
  PatientNextVisitController create() => PatientNextVisitController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PatientNextVisitState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PatientNextVisitState>(value),
    );
  }
}

String _$patientNextVisitControllerHash() =>
    r'23c3de49b1dbe4d4b106d12d31181eccfa4553c5';

/// Controller backing the patient detail's tappable Next-visit stat.

abstract class _$PatientNextVisitController
    extends $Notifier<PatientNextVisitState> {
  PatientNextVisitState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PatientNextVisitState, PatientNextVisitState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PatientNextVisitState, PatientNextVisitState>,
              PatientNextVisitState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
