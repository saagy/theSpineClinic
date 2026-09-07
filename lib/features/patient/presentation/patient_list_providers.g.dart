// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_list_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the patient list with filters and pagination.

@ProviderFor(PatientList)
final patientListProvider = PatientListProvider._();

/// Manages the patient list with filters and pagination.
final class PatientListProvider
    extends $AsyncNotifierProvider<PatientList, List<Patient>> {
  /// Manages the patient list with filters and pagination.
  PatientListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'patientListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$patientListHash();

  @$internal
  @override
  PatientList create() => PatientList();
}

String _$patientListHash() => r'25f7bb9cd46626107dc38a91a08a7bfdde3b00a5';

/// Manages the patient list with filters and pagination.

abstract class _$PatientList extends $AsyncNotifier<List<Patient>> {
  FutureOr<List<Patient>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Patient>>, List<Patient>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Patient>>, List<Patient>>,
              AsyncValue<List<Patient>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
