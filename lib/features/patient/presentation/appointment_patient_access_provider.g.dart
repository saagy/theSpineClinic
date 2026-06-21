// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_patient_access_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Evaluates doctor access for the patient pill on a given [appointment].
///
/// Returns a sealed [PatientAppointmentAccess] branch.

@ProviderFor(appointmentPatientAccess)
final appointmentPatientAccessProvider = AppointmentPatientAccessFamily._();

/// Evaluates doctor access for the patient pill on a given [appointment].
///
/// Returns a sealed [PatientAppointmentAccess] branch.

final class AppointmentPatientAccessProvider
    extends
        $FunctionalProvider<
          AsyncValue<PatientAppointmentAccess>,
          PatientAppointmentAccess,
          FutureOr<PatientAppointmentAccess>
        >
    with
        $FutureModifier<PatientAppointmentAccess>,
        $FutureProvider<PatientAppointmentAccess> {
  /// Evaluates doctor access for the patient pill on a given [appointment].
  ///
  /// Returns a sealed [PatientAppointmentAccess] branch.
  AppointmentPatientAccessProvider._({
    required AppointmentPatientAccessFamily super.from,
    required Appointment super.argument,
  }) : super(
         retry: null,
         name: r'appointmentPatientAccessProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$appointmentPatientAccessHash();

  @override
  String toString() {
    return r'appointmentPatientAccessProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PatientAppointmentAccess> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PatientAppointmentAccess> create(Ref ref) {
    final argument = this.argument as Appointment;
    return appointmentPatientAccess(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AppointmentPatientAccessProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$appointmentPatientAccessHash() =>
    r'5d8089044b116d8dfbc4040561583039ab82befa';

/// Evaluates doctor access for the patient pill on a given [appointment].
///
/// Returns a sealed [PatientAppointmentAccess] branch.

final class AppointmentPatientAccessFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<PatientAppointmentAccess>,
          Appointment
        > {
  AppointmentPatientAccessFamily._()
    : super(
        retry: null,
        name: r'appointmentPatientAccessProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Evaluates doctor access for the patient pill on a given [appointment].
  ///
  /// Returns a sealed [PatientAppointmentAccess] branch.

  AppointmentPatientAccessProvider call(Appointment appointment) =>
      AppointmentPatientAccessProvider._(argument: appointment, from: this);

  @override
  String toString() => r'appointmentPatientAccessProvider';
}
