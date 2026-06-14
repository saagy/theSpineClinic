// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_list_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the patient list with filters and pagination.
///
/// Search debounce is handled by [AppSearchBar]; call [searchNow] directly.

@ProviderFor(PatientList)
final patientListProvider = PatientListProvider._();

/// Manages the patient list with filters and pagination.
///
/// Search debounce is handled by [AppSearchBar]; call [searchNow] directly.
final class PatientListProvider
    extends $AsyncNotifierProvider<PatientList, List<Patient>> {
  /// Manages the patient list with filters and pagination.
  ///
  /// Search debounce is handled by [AppSearchBar]; call [searchNow] directly.
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

String _$patientListHash() => r'a19c6a22b0d4aba72e834aa6c7e2a044e4155c95';

/// Manages the patient list with filters and pagination.
///
/// Search debounce is handled by [AppSearchBar]; call [searchNow] directly.

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
