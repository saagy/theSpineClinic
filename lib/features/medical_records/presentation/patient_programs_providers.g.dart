// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_programs_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a singleton instance of [ProgramRepository].

@ProviderFor(programRepository)
final programRepositoryProvider = ProgramRepositoryProvider._();

/// Provides a singleton instance of [ProgramRepository].

final class ProgramRepositoryProvider
    extends
        $FunctionalProvider<
          ProgramRepository,
          ProgramRepository,
          ProgramRepository
        >
    with $Provider<ProgramRepository> {
  /// Provides a singleton instance of [ProgramRepository].
  ProgramRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'programRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$programRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProgramRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProgramRepository create(Ref ref) {
    return programRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgramRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgramRepository>(value),
    );
  }
}

String _$programRepositoryHash() => r'b8f4a433b27bc9a665e8b4895704e5f086e8797e';

/// Manages and caches the list of rehabilitation programs for a patient.

@ProviderFor(PatientProgramsNotifier)
final patientProgramsProvider = PatientProgramsNotifierFamily._();

/// Manages and caches the list of rehabilitation programs for a patient.
final class PatientProgramsNotifierProvider
    extends
        $AsyncNotifierProvider<PatientProgramsNotifier, List<PatientProgram>> {
  /// Manages and caches the list of rehabilitation programs for a patient.
  PatientProgramsNotifierProvider._({
    required PatientProgramsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'patientProgramsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientProgramsNotifierHash();

  @override
  String toString() {
    return r'patientProgramsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PatientProgramsNotifier create() => PatientProgramsNotifier();

  @override
  bool operator ==(Object other) {
    return other is PatientProgramsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientProgramsNotifierHash() =>
    r'a75856a736f3e2263a617ac408adfe50db20fc38';

/// Manages and caches the list of rehabilitation programs for a patient.

final class PatientProgramsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PatientProgramsNotifier,
          AsyncValue<List<PatientProgram>>,
          List<PatientProgram>,
          FutureOr<List<PatientProgram>>,
          String
        > {
  PatientProgramsNotifierFamily._()
    : super(
        retry: null,
        name: r'patientProgramsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Manages and caches the list of rehabilitation programs for a patient.

  PatientProgramsNotifierProvider call(String patientId) =>
      PatientProgramsNotifierProvider._(argument: patientId, from: this);

  @override
  String toString() => r'patientProgramsProvider';
}

/// Manages and caches the list of rehabilitation programs for a patient.

abstract class _$PatientProgramsNotifier
    extends $AsyncNotifier<List<PatientProgram>> {
  late final _$args = ref.$arg as String;
  String get patientId => _$args;

  FutureOr<List<PatientProgram>> build(String patientId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<PatientProgram>>, List<PatientProgram>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<PatientProgram>>,
                List<PatientProgram>
              >,
              AsyncValue<List<PatientProgram>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Fetches a single program detail by [programId].

@ProviderFor(programDetail)
final programDetailProvider = ProgramDetailFamily._();

/// Fetches a single program detail by [programId].

final class ProgramDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<PatientProgram?>,
          PatientProgram?,
          FutureOr<PatientProgram?>
        >
    with $FutureModifier<PatientProgram?>, $FutureProvider<PatientProgram?> {
  /// Fetches a single program detail by [programId].
  ProgramDetailProvider._({
    required ProgramDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'programDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$programDetailHash();

  @override
  String toString() {
    return r'programDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PatientProgram?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PatientProgram?> create(Ref ref) {
    final argument = this.argument as String;
    return programDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$programDetailHash() => r'8f611eccd3d0360bf1f3045d2a151a80a7e72d7c';

/// Fetches a single program detail by [programId].

final class ProgramDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PatientProgram?>, String> {
  ProgramDetailFamily._()
    : super(
        retry: null,
        name: r'programDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches a single program detail by [programId].

  ProgramDetailProvider call(String programId) =>
      ProgramDetailProvider._(argument: programId, from: this);

  @override
  String toString() => r'programDetailProvider';
}
