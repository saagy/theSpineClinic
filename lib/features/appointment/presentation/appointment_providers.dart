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
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

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
    final ClinicLocation clinic = ref.watch(activeBranchProvider);
    final AppointmentRepository repo = ref.read(appointmentRepositoryProvider);
    final Result<List<Appointment>> result = await repo.getAppointmentsForToday(clinic);

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

/// Family provider resolving the count of future scheduled appointments
/// of a specific bucket (PT or Traction). Assessments always return 0
/// because they have no balance impact.
@riverpod
Future<int> futureScheduledAppointmentsCountForType(
  Ref ref,
  ({String patientId, AppointmentType type}) args,
) async {
  final AppointmentRepository repo = ref.read(appointmentRepositoryProvider);
  final Result<int> result =
      await repo.getFutureScheduledAppointmentsCountForType(
    patientId: args.patientId,
    type: args.type,
  );

  return result.when(
    success: (data) => data,
    failure: (_) => 0,
  );
}

/// Family provider evaluating: Current Balance - Future Commitments for a
/// given appointment type's bucket.
///
/// Returns `null` when the appointment type is one of the assessments
/// (no balance impact at all), so callers can render a "paid separately"
/// surface instead of a numeric balance.
@riverpod
Future<int?> availableBalanceForType(Ref ref, ({String patientId, AppointmentType type}) args) async {
  if (!args.type.affectsPackageBalance) return null;
  final patient = await ref.watch(patientDetailProvider(args.patientId).future);
  final repo = ref.read(appointmentRepositoryProvider);
  final Result<int> commitmentsResult = await repo.getFutureScheduledAppointmentsCountForType(
    patientId: args.patientId,
    type: args.type,
  );
  final int futureCommitments = commitmentsResult.when(
    success: (data) => data,
    failure: (err) => 0,
  );
  final int baseline = switch (args.type) {
    AppointmentType.normalPtSession => patient.sessionBalance,
    AppointmentType.spinalTractionSession => patient.tractionBalance,
    AppointmentType.initialAssessment => 0,
    AppointmentType.reassessment => 0,
  };
  return baseline - futureCommitments;
}

/// Backwards-compatible alias while call sites migrate. Defaults to the
/// Normal PT bucket — new code should pass the appointment type explicitly.
@riverpod
Future<int> availablePackageBalance(Ref ref, String patientId) async {
  final int? value = await ref.watch(availableBalanceForTypeProvider((
    patientId: patientId,
    type: AppointmentType.normalPtSession,
  )).future);
  return value ?? 0;
}

/// Family provider resolving a single appointment by ID.
@riverpod
Future<Appointment> singleAppointment(Ref ref, String appointmentId) async {
  final repo = ref.watch(appointmentRepositoryProvider);
  final result = await repo.getAppointmentById(appointmentId);
  return result.when(
    success: (data) => data,
    failure: (err) => throw err,
  );
}


