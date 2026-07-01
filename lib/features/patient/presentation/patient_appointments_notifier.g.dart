// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_appointments_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PatientAppointments)
final patientAppointmentsProvider = PatientAppointmentsFamily._();

final class PatientAppointmentsProvider
    extends $NotifierProvider<PatientAppointments, PatientAppointmentsState> {
  PatientAppointmentsProvider._({
    required PatientAppointmentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'patientAppointmentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientAppointmentsHash();

  @override
  String toString() {
    return r'patientAppointmentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PatientAppointments create() => PatientAppointments();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PatientAppointmentsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PatientAppointmentsState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PatientAppointmentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientAppointmentsHash() =>
    r'b5742837064c77ec25a6dc41eae88cacc09e7bed';

final class PatientAppointmentsFamily extends $Family
    with
        $ClassFamilyOverride<
          PatientAppointments,
          PatientAppointmentsState,
          PatientAppointmentsState,
          PatientAppointmentsState,
          String
        > {
  PatientAppointmentsFamily._()
    : super(
        retry: null,
        name: r'patientAppointmentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PatientAppointmentsProvider call(String patientId) =>
      PatientAppointmentsProvider._(argument: patientId, from: this);

  @override
  String toString() => r'patientAppointmentsProvider';
}

abstract class _$PatientAppointments
    extends $Notifier<PatientAppointmentsState> {
  late final _$args = ref.$arg as String;
  String get patientId => _$args;

  PatientAppointmentsState build(String patientId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<PatientAppointmentsState, PatientAppointmentsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PatientAppointmentsState, PatientAppointmentsState>,
              PatientAppointmentsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
