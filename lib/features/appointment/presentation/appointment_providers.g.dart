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

String _$todayAppointmentsHash() => r'66844ffcf2b367f26c2ebcaf4228b1be7eb1f5f7';

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
