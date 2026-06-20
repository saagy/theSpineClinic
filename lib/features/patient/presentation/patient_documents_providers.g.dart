// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_documents_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a singleton [PatientDocumentsRepository] instance.

@ProviderFor(patientDocumentsRepository)
final patientDocumentsRepositoryProvider =
    PatientDocumentsRepositoryProvider._();

/// Provides a singleton [PatientDocumentsRepository] instance.

final class PatientDocumentsRepositoryProvider
    extends
        $FunctionalProvider<
          PatientDocumentsRepository,
          PatientDocumentsRepository,
          PatientDocumentsRepository
        >
    with $Provider<PatientDocumentsRepository> {
  /// Provides a singleton [PatientDocumentsRepository] instance.
  PatientDocumentsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'patientDocumentsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$patientDocumentsRepositoryHash();

  @$internal
  @override
  $ProviderElement<PatientDocumentsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PatientDocumentsRepository create(Ref ref) {
    return patientDocumentsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PatientDocumentsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PatientDocumentsRepository>(value),
    );
  }
}

String _$patientDocumentsRepositoryHash() =>
    r'0d30f3e2d4dc9f3b1d98161cf7bf1203e05999f7';

/// Family AsyncNotifier managing the document list state for a patient.

@ProviderFor(PatientDocumentsNotifierNotifier)
final patientDocumentsNotifierProvider =
    PatientDocumentsNotifierNotifierFamily._();

/// Family AsyncNotifier managing the document list state for a patient.
final class PatientDocumentsNotifierNotifierProvider
    extends
        $AsyncNotifierProvider<
          PatientDocumentsNotifierNotifier,
          List<PatientDocument>
        > {
  /// Family AsyncNotifier managing the document list state for a patient.
  PatientDocumentsNotifierNotifierProvider._({
    required PatientDocumentsNotifierNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'patientDocumentsNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientDocumentsNotifierNotifierHash();

  @override
  String toString() {
    return r'patientDocumentsNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PatientDocumentsNotifierNotifier create() =>
      PatientDocumentsNotifierNotifier();

  @override
  bool operator ==(Object other) {
    return other is PatientDocumentsNotifierNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientDocumentsNotifierNotifierHash() =>
    r'd86c4715118cd2a3d123f61077774e25acc59c41';

/// Family AsyncNotifier managing the document list state for a patient.

final class PatientDocumentsNotifierNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PatientDocumentsNotifierNotifier,
          AsyncValue<List<PatientDocument>>,
          List<PatientDocument>,
          FutureOr<List<PatientDocument>>,
          String
        > {
  PatientDocumentsNotifierNotifierFamily._()
    : super(
        retry: null,
        name: r'patientDocumentsNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Family AsyncNotifier managing the document list state for a patient.

  PatientDocumentsNotifierNotifierProvider call(String patientId) =>
      PatientDocumentsNotifierNotifierProvider._(
        argument: patientId,
        from: this,
      );

  @override
  String toString() => r'patientDocumentsNotifierProvider';
}

/// Family AsyncNotifier managing the document list state for a patient.

abstract class _$PatientDocumentsNotifierNotifier
    extends $AsyncNotifier<List<PatientDocument>> {
  late final _$args = ref.$arg as String;
  String get patientId => _$args;

  FutureOr<List<PatientDocument>> build(String patientId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<PatientDocument>>, List<PatientDocument>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<PatientDocument>>,
                List<PatientDocument>
              >,
              AsyncValue<List<PatientDocument>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
