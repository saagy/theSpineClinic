/// Riverpod providers for the appointment feature.
///
/// Exposes:
/// - [appointmentRepositoryProvider] — singleton [AppointmentRepository] instance.
/// - [todayAppointmentsProvider] — reactive [AsyncValue<List<Appointment>>] notifier.
/// - [appointmentDoctorsProvider] — family [FutureProvider] returning [List<AppointmentDoctor>].
///
/// Rule 3 — all state via Riverpod, no setState.
/// Rule 4 — repository calls always return [Result<T>].
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/appointment/data/appointment_repository_impl.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_doctor.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';

part 'appointment_providers.g.dart';

/// Provides the singleton [AppointmentRepository] backed by Supabase.
@Riverpod(keepAlive: true)
AppointmentRepository appointmentRepository(Ref ref) {
  return AppointmentRepositoryImpl(
    supabaseService: SupabaseService.instance,
  );
}

/// Reactive notifier holding today's schedule of appointments.
///
/// Uses [ref.invalidateSelf()] during reload to trigger Riverpod's built-in
/// stale-while-revalidate loop, preventing blank/loading screen flashes.
@riverpod
class TodayAppointments extends _$TodayAppointments {
  @override
  Future<List<Appointment>> build() async {
    final AppointmentRepository repo = ref.read(appointmentRepositoryProvider);
    final Result<List<Appointment>> result = await repo.getAppointmentsForToday();

    switch (result) {
      case Success<List<Appointment>>(:final data):
        return data;
      case Failure<List<Appointment>>(:final exception):
        throw exception;
    }
  }

  /// Refreshes today's appointment list.
  Future<void> refreshSchedule() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Family provider that resolves active doctor assignments for a specific appointment.
@riverpod
Future<List<AppointmentDoctor>> appointmentDoctors(Ref ref, String appointmentId) async {
  final AppointmentRepository repo = ref.read(appointmentRepositoryProvider);
  final Result<List<AppointmentDoctor>> result =
      await repo.getAppointmentDoctors(appointmentId);

  switch (result) {
    case Success<List<AppointmentDoctor>>(:final data):
      return data;
    case Failure<List<AppointmentDoctor>>(:final exception):
      throw exception;
  }
}
