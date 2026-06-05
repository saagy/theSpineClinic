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
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

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

/// Helper class representing doctor assignment details.
class AppointmentDoctorDetail {
  final AppointmentDoctor assignment;
  final Staff doctor;
  final Staff? replacedDoctor;

  AppointmentDoctorDetail({
    required this.assignment,
    required this.doctor,
    this.replacedDoctor,
  });
}

/// Family provider resolving all appointments for a patient.
@riverpod
Future<List<Appointment>> patientAppointments(Ref ref, String patientId) async {
  final AppointmentRepository repo = ref.read(appointmentRepositoryProvider);
  final Result<List<Appointment>> result =
      await repo.getAppointmentsForPatient(patientId);

  switch (result) {
    case Success<List<Appointment>>(:final data):
      return data;
    case Failure<List<Appointment>>(:final exception):
      throw exception;
  }
}

/// Family provider resolving the detailed doctor assignments for an appointment.
@riverpod
Future<List<AppointmentDoctorDetail>> appointmentDoctorsDetails(
  Ref ref,
  String appointmentId,
) async {
  final AppointmentRepository repo = ref.read(appointmentRepositoryProvider);
  final Result<List<AppointmentDoctor>> assignmentsResult =
      await repo.getAppointmentDoctors(appointmentId);

  final List<AppointmentDoctor> assignments = assignmentsResult.when(
    success: (data) => data,
    failure: (error) => throw error,
  );

  // Concurrently resolve all doctor and replaced doctor profile requests.
  final List<Future<AppointmentDoctorDetail>> detailFutures = assignments.map((assignment) async {
    final Future<Staff> doctorFuture = ref.read(staffProfileProvider(assignment.doctorId).future);
    final Future<Staff?> replacedDoctorFuture = assignment.replacedDoctorId != null
        ? ref.read(staffProfileProvider(assignment.replacedDoctorId!).future)
        : Future.value(null);

    final List<Object?> results = await Future.wait([doctorFuture, replacedDoctorFuture]);
    final Staff doctorResult = results[0] as Staff;
    final Staff? replacedDoctorResult = results[1] as Staff?;

    return AppointmentDoctorDetail(
      assignment: assignment,
      doctor: doctorResult,
      replacedDoctor: replacedDoctorResult,
    );
  }).toList();

  return Future.wait(detailFutures);
}

/// Family provider resolving the aggregate count of future scheduled appointments.
@riverpod
Future<int> futureScheduledAppointmentsCount(Ref ref, String patientId) async {
  final AppointmentRepository repo = ref.read(appointmentRepositoryProvider);
  final Result<int> result = await repo.getFutureScheduledAppointmentsCount(patientId);

  switch (result) {
    case Success<int>(:final data):
      return data;
    case Failure<int>(:final exception):
      throw exception;
  }
}

/// Family provider evaluating: Current Balance - Future Commitments.
@riverpod
Future<int> availablePackageBalance(Ref ref, String patientId) async {
  final patient = await ref.watch(patientDetailProvider(patientId).future);
  final futureCommitments = await ref.watch(futureScheduledAppointmentsCountProvider(patientId).future);
  return patient.packageBalance - futureCommitments;
}


