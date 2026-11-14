// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_visit_clash_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The patient's uncancelled visits from [args.from] on. Keyed by the first
/// booked day, not the whole series, so typing a session count never queries.

@ProviderFor(patientVisitsFrom)
final patientVisitsFromProvider = PatientVisitsFromFamily._();

/// The patient's uncancelled visits from [args.from] on. Keyed by the first
/// booked day, not the whole series, so typing a session count never queries.

final class PatientVisitsFromProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Appointment>>,
          List<Appointment>,
          FutureOr<List<Appointment>>
        >
    with
        $FutureModifier<List<Appointment>>,
        $FutureProvider<List<Appointment>> {
  /// The patient's uncancelled visits from [args.from] on. Keyed by the first
  /// booked day, not the whole series, so typing a session count never queries.
  PatientVisitsFromProvider._({
    required PatientVisitsFromFamily super.from,
    required ({DateTime from, String patientId}) super.argument,
  }) : super(
         retry: null,
         name: r'patientVisitsFromProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientVisitsFromHash();

  @override
  String toString() {
    return r'patientVisitsFromProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Appointment>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Appointment>> create(Ref ref) {
    final argument = this.argument as ({DateTime from, String patientId});
    return patientVisitsFrom(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PatientVisitsFromProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientVisitsFromHash() => r'a7f7d7e716af3d06989ba0604457c4b1190096fa';

/// The patient's uncancelled visits from [args.from] on. Keyed by the first
/// booked day, not the whole series, so typing a session count never queries.

final class PatientVisitsFromFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Appointment>>,
          ({DateTime from, String patientId})
        > {
  PatientVisitsFromFamily._()
    : super(
        retry: null,
        name: r'patientVisitsFromProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The patient's uncancelled visits from [args.from] on. Keyed by the first
  /// booked day, not the whole series, so typing a session count never queries.

  PatientVisitsFromProvider call(({DateTime from, String patientId}) args) =>
      PatientVisitsFromProvider._(argument: args, from: this);

  @override
  String toString() => r'patientVisitsFromProvider';
}
