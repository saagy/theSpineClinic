// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_history_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a singleton instance of [MedicalHistoryRepository].

@ProviderFor(medicalHistoryRepository)
final medicalHistoryRepositoryProvider = MedicalHistoryRepositoryProvider._();

/// Provides a singleton instance of [MedicalHistoryRepository].

final class MedicalHistoryRepositoryProvider
    extends
        $FunctionalProvider<
          MedicalHistoryRepository,
          MedicalHistoryRepository,
          MedicalHistoryRepository
        >
    with $Provider<MedicalHistoryRepository> {
  /// Provides a singleton instance of [MedicalHistoryRepository].
  MedicalHistoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'medicalHistoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$medicalHistoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<MedicalHistoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MedicalHistoryRepository create(Ref ref) {
    return medicalHistoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MedicalHistoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MedicalHistoryRepository>(value),
    );
  }
}

String _$medicalHistoryRepositoryHash() =>
    r'ccc3f6ccc46465e085f62d209befea836b8e71a4';

/// Fetches and reactively manages medical history for a specific patient.

@ProviderFor(PatientMedicalHistoryNotifier)
final patientMedicalHistoryProvider = PatientMedicalHistoryNotifierFamily._();

/// Fetches and reactively manages medical history for a specific patient.
final class PatientMedicalHistoryNotifierProvider
    extends
        $AsyncNotifierProvider<
          PatientMedicalHistoryNotifier,
          PatientMedicalHistory?
        > {
  /// Fetches and reactively manages medical history for a specific patient.
  PatientMedicalHistoryNotifierProvider._({
    required PatientMedicalHistoryNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'patientMedicalHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientMedicalHistoryNotifierHash();

  @override
  String toString() {
    return r'patientMedicalHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PatientMedicalHistoryNotifier create() => PatientMedicalHistoryNotifier();

  @override
  bool operator ==(Object other) {
    return other is PatientMedicalHistoryNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientMedicalHistoryNotifierHash() =>
    r'ef9f3ce95c0af1611c50d847fb7cf2ffdc684275';

/// Fetches and reactively manages medical history for a specific patient.

final class PatientMedicalHistoryNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PatientMedicalHistoryNotifier,
          AsyncValue<PatientMedicalHistory?>,
          PatientMedicalHistory?,
          FutureOr<PatientMedicalHistory?>,
          String
        > {
  PatientMedicalHistoryNotifierFamily._()
    : super(
        retry: null,
        name: r'patientMedicalHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches and reactively manages medical history for a specific patient.

  PatientMedicalHistoryNotifierProvider call(String patientId) =>
      PatientMedicalHistoryNotifierProvider._(argument: patientId, from: this);

  @override
  String toString() => r'patientMedicalHistoryProvider';
}

/// Fetches and reactively manages medical history for a specific patient.

abstract class _$PatientMedicalHistoryNotifier
    extends $AsyncNotifier<PatientMedicalHistory?> {
  late final _$args = ref.$arg as String;
  String get patientId => _$args;

  FutureOr<PatientMedicalHistory?> build(String patientId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<PatientMedicalHistory?>, PatientMedicalHistory?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PatientMedicalHistory?>,
                PatientMedicalHistory?
              >,
              AsyncValue<PatientMedicalHistory?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
