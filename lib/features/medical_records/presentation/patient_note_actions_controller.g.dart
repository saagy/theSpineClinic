// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_note_actions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Patient-scoped note mutations survive closing the editor or changing tabs.

@ProviderFor(PatientNoteActionsController)
final patientNoteActionsControllerProvider =
    PatientNoteActionsControllerProvider._();

/// Patient-scoped note mutations survive closing the editor or changing tabs.
final class PatientNoteActionsControllerProvider
    extends $NotifierProvider<PatientNoteActionsController, void> {
  /// Patient-scoped note mutations survive closing the editor or changing tabs.
  PatientNoteActionsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'patientNoteActionsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$patientNoteActionsControllerHash();

  @$internal
  @override
  PatientNoteActionsController create() => PatientNoteActionsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$patientNoteActionsControllerHash() =>
    r'eff3a0060e4a5f70b3c9a88e604e10be8432e2c4';

/// Patient-scoped note mutations survive closing the editor or changing tabs.

abstract class _$PatientNoteActionsController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
