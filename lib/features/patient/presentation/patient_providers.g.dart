// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a singleton [PatientRepository] instance.

@ProviderFor(patientRepository)
final patientRepositoryProvider = PatientRepositoryProvider._();

/// Provides a singleton [PatientRepository] instance.

final class PatientRepositoryProvider
    extends
        $FunctionalProvider<
          PatientRepository,
          PatientRepository,
          PatientRepository
        >
    with $Provider<PatientRepository> {
  /// Provides a singleton [PatientRepository] instance.
  PatientRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'patientRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$patientRepositoryHash();

  @$internal
  @override
  $ProviderElement<PatientRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PatientRepository create(Ref ref) {
    return patientRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PatientRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PatientRepository>(value),
    );
  }
}

String _$patientRepositoryHash() => r'dea578c2e1f974146185f5c2d88d67a0cd2015ba';

/// Fetches a single patient record by its ID using the repository.

@ProviderFor(patientDetail)
final patientDetailProvider = PatientDetailFamily._();

/// Fetches a single patient record by its ID using the repository.

final class PatientDetailProvider
    extends $FunctionalProvider<AsyncValue<Patient>, Patient, FutureOr<Patient>>
    with $FutureModifier<Patient>, $FutureProvider<Patient> {
  /// Fetches a single patient record by its ID using the repository.
  PatientDetailProvider._({
    required PatientDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'patientDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientDetailHash();

  @override
  String toString() {
    return r'patientDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Patient> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Patient> create(Ref ref) {
    final argument = this.argument as String;
    return patientDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PatientDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientDetailHash() => r'71a0ab1caf56951c1bb942bff764e845f515379f';

/// Fetches a single patient record by its ID using the repository.

final class PatientDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Patient>, String> {
  PatientDetailFamily._()
    : super(
        retry: null,
        name: r'patientDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches a single patient record by its ID using the repository.

  PatientDetailProvider call(String id) =>
      PatientDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'patientDetailProvider';
}

/// Async notifier that manages patient search state.
///
/// Tracks the current query and clinic filter. When [search] is called,
/// the notifier sets loading → executes the repository query → sets
/// data or error. The Supabase RLS policies enforce role-scoped
/// filtering transparently.

@ProviderFor(PatientSearch)
final patientSearchProvider = PatientSearchProvider._();

/// Async notifier that manages patient search state.
///
/// Tracks the current query and clinic filter. When [search] is called,
/// the notifier sets loading → executes the repository query → sets
/// data or error. The Supabase RLS policies enforce role-scoped
/// filtering transparently.
final class PatientSearchProvider
    extends $AsyncNotifierProvider<PatientSearch, List<Patient>> {
  /// Async notifier that manages patient search state.
  ///
  /// Tracks the current query and clinic filter. When [search] is called,
  /// the notifier sets loading → executes the repository query → sets
  /// data or error. The Supabase RLS policies enforce role-scoped
  /// filtering transparently.
  PatientSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'patientSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$patientSearchHash();

  @$internal
  @override
  PatientSearch create() => PatientSearch();
}

String _$patientSearchHash() => r'acd4e3c13fd050ef6d1914ffe8b496065272529b';

/// Async notifier that manages patient search state.
///
/// Tracks the current query and clinic filter. When [search] is called,
/// the notifier sets loading → executes the repository query → sets
/// data or error. The Supabase RLS policies enforce role-scoped
/// filtering transparently.

abstract class _$PatientSearch extends $AsyncNotifier<List<Patient>> {
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

/// Fetches active doctors assigned to a patient.

@ProviderFor(patientAssignedDoctors)
final patientAssignedDoctorsProvider = PatientAssignedDoctorsFamily._();

/// Fetches active doctors assigned to a patient.

final class PatientAssignedDoctorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Staff>>,
          List<Staff>,
          FutureOr<List<Staff>>
        >
    with $FutureModifier<List<Staff>>, $FutureProvider<List<Staff>> {
  /// Fetches active doctors assigned to a patient.
  PatientAssignedDoctorsProvider._({
    required PatientAssignedDoctorsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'patientAssignedDoctorsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientAssignedDoctorsHash();

  @override
  String toString() {
    return r'patientAssignedDoctorsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Staff>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Staff>> create(Ref ref) {
    final argument = this.argument as String;
    return patientAssignedDoctors(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PatientAssignedDoctorsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientAssignedDoctorsHash() =>
    r'5190ae751d18cba8dc1073bd779ad8c363ca4200';

/// Fetches active doctors assigned to a patient.

final class PatientAssignedDoctorsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Staff>>, String> {
  PatientAssignedDoctorsFamily._()
    : super(
        retry: null,
        name: r'patientAssignedDoctorsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches active doctors assigned to a patient.

  PatientAssignedDoctorsProvider call(String patientId) =>
      PatientAssignedDoctorsProvider._(argument: patientId, from: this);

  @override
  String toString() => r'patientAssignedDoctorsProvider';
}
