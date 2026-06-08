// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [AppointmentRepository] backed by Supabase.

@ProviderFor(appointmentRepository)
final appointmentRepositoryProvider = AppointmentRepositoryProvider._();

/// Provides the singleton [AppointmentRepository] backed by Supabase.

final class AppointmentRepositoryProvider
    extends
        $FunctionalProvider<
          AppointmentRepository,
          AppointmentRepository,
          AppointmentRepository
        >
    with $Provider<AppointmentRepository> {
  /// Provides the singleton [AppointmentRepository] backed by Supabase.
  AppointmentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appointmentRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appointmentRepositoryHash();

  @$internal
  @override
  $ProviderElement<AppointmentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppointmentRepository create(Ref ref) {
    return appointmentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppointmentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppointmentRepository>(value),
    );
  }
}

String _$appointmentRepositoryHash() =>
    r'0641fa2189d2e481e455f8518a67a390f6c7a56c';

/// Reactive notifier holding today's schedule of appointments.
///
/// Uses [ref.invalidateSelf()] during reload to trigger Riverpod's built-in
/// stale-while-revalidate loop, preventing blank/loading screen flashes.

@ProviderFor(TodayAppointments)
final todayAppointmentsProvider = TodayAppointmentsProvider._();

/// Reactive notifier holding today's schedule of appointments.
///
/// Uses [ref.invalidateSelf()] during reload to trigger Riverpod's built-in
/// stale-while-revalidate loop, preventing blank/loading screen flashes.
final class TodayAppointmentsProvider
    extends $AsyncNotifierProvider<TodayAppointments, List<Appointment>> {
  /// Reactive notifier holding today's schedule of appointments.
  ///
  /// Uses [ref.invalidateSelf()] during reload to trigger Riverpod's built-in
  /// stale-while-revalidate loop, preventing blank/loading screen flashes.
  TodayAppointmentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayAppointmentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayAppointmentsHash();

  @$internal
  @override
  TodayAppointments create() => TodayAppointments();
}

String _$todayAppointmentsHash() => r'e7d83fa5162a53e293bfdacbe33afad3ceaa1aa0';

/// Reactive notifier holding today's schedule of appointments.
///
/// Uses [ref.invalidateSelf()] during reload to trigger Riverpod's built-in
/// stale-while-revalidate loop, preventing blank/loading screen flashes.

abstract class _$TodayAppointments extends $AsyncNotifier<List<Appointment>> {
  FutureOr<List<Appointment>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<Appointment>>, List<Appointment>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Appointment>>, List<Appointment>>,
              AsyncValue<List<Appointment>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Family provider that resolves active doctor assignments for a specific appointment.

@ProviderFor(appointmentDoctors)
final appointmentDoctorsProvider = AppointmentDoctorsFamily._();

/// Family provider that resolves active doctor assignments for a specific appointment.

final class AppointmentDoctorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppointmentDoctor>>,
          List<AppointmentDoctor>,
          FutureOr<List<AppointmentDoctor>>
        >
    with
        $FutureModifier<List<AppointmentDoctor>>,
        $FutureProvider<List<AppointmentDoctor>> {
  /// Family provider that resolves active doctor assignments for a specific appointment.
  AppointmentDoctorsProvider._({
    required AppointmentDoctorsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'appointmentDoctorsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$appointmentDoctorsHash();

  @override
  String toString() {
    return r'appointmentDoctorsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AppointmentDoctor>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AppointmentDoctor>> create(Ref ref) {
    final argument = this.argument as String;
    return appointmentDoctors(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AppointmentDoctorsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$appointmentDoctorsHash() =>
    r'89bec8a0fe25b322059f6d44dcd5f013b4a5f660';

/// Family provider that resolves active doctor assignments for a specific appointment.

final class AppointmentDoctorsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AppointmentDoctor>>, String> {
  AppointmentDoctorsFamily._()
    : super(
        retry: null,
        name: r'appointmentDoctorsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Family provider that resolves active doctor assignments for a specific appointment.

  AppointmentDoctorsProvider call(String appointmentId) =>
      AppointmentDoctorsProvider._(argument: appointmentId, from: this);

  @override
  String toString() => r'appointmentDoctorsProvider';
}

/// Family provider resolving all appointments for a patient.

@ProviderFor(patientAppointments)
final patientAppointmentsProvider = PatientAppointmentsFamily._();

/// Family provider resolving all appointments for a patient.

final class PatientAppointmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Appointment>>,
          List<Appointment>,
          FutureOr<List<Appointment>>
        >
    with
        $FutureModifier<List<Appointment>>,
        $FutureProvider<List<Appointment>> {
  /// Family provider resolving all appointments for a patient.
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
  $FutureProviderElement<List<Appointment>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Appointment>> create(Ref ref) {
    final argument = this.argument as String;
    return patientAppointments(ref, argument);
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
    r'770290a2281f08372de04d9eaf9db6a9d5f3bbff';

/// Family provider resolving all appointments for a patient.

final class PatientAppointmentsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Appointment>>, String> {
  PatientAppointmentsFamily._()
    : super(
        retry: null,
        name: r'patientAppointmentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Family provider resolving all appointments for a patient.

  PatientAppointmentsProvider call(String patientId) =>
      PatientAppointmentsProvider._(argument: patientId, from: this);

  @override
  String toString() => r'patientAppointmentsProvider';
}

/// Family provider resolving the detailed doctor assignments for an appointment.

@ProviderFor(appointmentDoctorsDetails)
final appointmentDoctorsDetailsProvider = AppointmentDoctorsDetailsFamily._();

/// Family provider resolving the detailed doctor assignments for an appointment.

final class AppointmentDoctorsDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppointmentDoctorDetail>>,
          List<AppointmentDoctorDetail>,
          FutureOr<List<AppointmentDoctorDetail>>
        >
    with
        $FutureModifier<List<AppointmentDoctorDetail>>,
        $FutureProvider<List<AppointmentDoctorDetail>> {
  /// Family provider resolving the detailed doctor assignments for an appointment.
  AppointmentDoctorsDetailsProvider._({
    required AppointmentDoctorsDetailsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'appointmentDoctorsDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$appointmentDoctorsDetailsHash();

  @override
  String toString() {
    return r'appointmentDoctorsDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AppointmentDoctorDetail>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AppointmentDoctorDetail>> create(Ref ref) {
    final argument = this.argument as String;
    return appointmentDoctorsDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AppointmentDoctorsDetailsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$appointmentDoctorsDetailsHash() =>
    r'7dd664f217aa97fb872082e870da3401a41e8da3';

/// Family provider resolving the detailed doctor assignments for an appointment.

final class AppointmentDoctorsDetailsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<AppointmentDoctorDetail>>,
          String
        > {
  AppointmentDoctorsDetailsFamily._()
    : super(
        retry: null,
        name: r'appointmentDoctorsDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Family provider resolving the detailed doctor assignments for an appointment.

  AppointmentDoctorsDetailsProvider call(String appointmentId) =>
      AppointmentDoctorsDetailsProvider._(argument: appointmentId, from: this);

  @override
  String toString() => r'appointmentDoctorsDetailsProvider';
}

/// Family provider resolving the aggregate count of future scheduled appointments.

@ProviderFor(futureScheduledAppointmentsCount)
final futureScheduledAppointmentsCountProvider =
    FutureScheduledAppointmentsCountFamily._();

/// Family provider resolving the aggregate count of future scheduled appointments.

final class FutureScheduledAppointmentsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Family provider resolving the aggregate count of future scheduled appointments.
  FutureScheduledAppointmentsCountProvider._({
    required FutureScheduledAppointmentsCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'futureScheduledAppointmentsCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$futureScheduledAppointmentsCountHash();

  @override
  String toString() {
    return r'futureScheduledAppointmentsCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return futureScheduledAppointmentsCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FutureScheduledAppointmentsCountProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$futureScheduledAppointmentsCountHash() =>
    r'f4aeb3c28cef55359edc2857dcfe13f203cdab55';

/// Family provider resolving the aggregate count of future scheduled appointments.

final class FutureScheduledAppointmentsCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  FutureScheduledAppointmentsCountFamily._()
    : super(
        retry: null,
        name: r'futureScheduledAppointmentsCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Family provider resolving the aggregate count of future scheduled appointments.

  FutureScheduledAppointmentsCountProvider call(String patientId) =>
      FutureScheduledAppointmentsCountProvider._(
        argument: patientId,
        from: this,
      );

  @override
  String toString() => r'futureScheduledAppointmentsCountProvider';
}

/// Family provider evaluating: Current Balance - Future Commitments.

@ProviderFor(availablePackageBalance)
final availablePackageBalanceProvider = AvailablePackageBalanceFamily._();

/// Family provider evaluating: Current Balance - Future Commitments.

final class AvailablePackageBalanceProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Family provider evaluating: Current Balance - Future Commitments.
  AvailablePackageBalanceProvider._({
    required AvailablePackageBalanceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'availablePackageBalanceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$availablePackageBalanceHash();

  @override
  String toString() {
    return r'availablePackageBalanceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return availablePackageBalance(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AvailablePackageBalanceProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$availablePackageBalanceHash() =>
    r'e2e9f5582516666254a19a08be00f5f74fa82218';

/// Family provider evaluating: Current Balance - Future Commitments.

final class AvailablePackageBalanceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  AvailablePackageBalanceFamily._()
    : super(
        retry: null,
        name: r'availablePackageBalanceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Family provider evaluating: Current Balance - Future Commitments.

  AvailablePackageBalanceProvider call(String patientId) =>
      AvailablePackageBalanceProvider._(argument: patientId, from: this);

  @override
  String toString() => r'availablePackageBalanceProvider';
}

/// Family provider resolving a single appointment by ID.

@ProviderFor(singleAppointment)
final singleAppointmentProvider = SingleAppointmentFamily._();

/// Family provider resolving a single appointment by ID.

final class SingleAppointmentProvider
    extends
        $FunctionalProvider<
          AsyncValue<Appointment>,
          Appointment,
          FutureOr<Appointment>
        >
    with $FutureModifier<Appointment>, $FutureProvider<Appointment> {
  /// Family provider resolving a single appointment by ID.
  SingleAppointmentProvider._({
    required SingleAppointmentFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'singleAppointmentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$singleAppointmentHash();

  @override
  String toString() {
    return r'singleAppointmentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Appointment> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Appointment> create(Ref ref) {
    final argument = this.argument as String;
    return singleAppointment(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SingleAppointmentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$singleAppointmentHash() => r'61a1712054d080aed7c5d37c59df9ca7aa20ca46';

/// Family provider resolving a single appointment by ID.

final class SingleAppointmentFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Appointment>, String> {
  SingleAppointmentFamily._()
    : super(
        retry: null,
        name: r'singleAppointmentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Family provider resolving a single appointment by ID.

  SingleAppointmentProvider call(String appointmentId) =>
      SingleAppointmentProvider._(argument: appointmentId, from: this);

  @override
  String toString() => r'singleAppointmentProvider';
}
