/// Riverpod controller for the AppointmentDetailScreen.
///
/// Manages composite state: [Appointment] + [Patient] + doctor assignments
/// (active and inactive). Exposes mutation methods for status transitions.
///
/// Rule 3 — all state via Riverpod, no setState.
/// Rule 4 — repository calls always return [Result<T>].
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_doctor.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_provider.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

part 'appointment_detail_controller.g.dart';

/// Composite state shape for the appointment detail screen.
typedef AppointmentDetailState = ({
  Appointment appointment,
  Patient patient,
  List<AppointmentDoctorDetail> activeDoctors,
  List<AppointmentDoctorDetail> inactiveDoctors,
});

/// Controller managing a single appointment's detail view and mutations.
@riverpod
class AppointmentDetailController extends _$AppointmentDetailController {
  @override
  Future<AppointmentDetailState> build(String appointmentId) async {
    final AppointmentRepository repo = ref.read(appointmentRepositoryProvider);

    // 1. Fetch appointment
    final Result<Appointment> appointmentResult = await repo.getAppointmentById(
      appointmentId,
    );
    final Appointment appointment = switch (appointmentResult) {
      Success<Appointment>(:final data) => data,
      Failure<Appointment>(:final exception) => throw exception,
    };

    // 2. Fetch patient
    final Patient patient = await ref.watch(
      patientDetailProvider(appointment.patientId).future,
    );

    // 3. Fetch ALL doctor assignments (active + inactive)
    final Result<List<AppointmentDoctor>> allDoctorsResult = await repo
        .getAllAppointmentDoctors(appointmentId);
    final List<AppointmentDoctor> allAssignments = switch (allDoctorsResult) {
      Success<List<AppointmentDoctor>>(:final data) => data,
      Failure<List<AppointmentDoctor>>(:final exception) => throw exception,
    };

    // 4. Resolve staff profiles for each assignment concurrently
    final List<AppointmentDoctorDetail> details = await Future.wait(
      allAssignments.map(_resolveDetail),
    );

    // 5. Split into active / inactive lists
    final List<AppointmentDoctorDetail> active = details
        .where((d) => d.assignment.isActive)
        .toList();
    final List<AppointmentDoctorDetail> inactive = details
        .where((d) => !d.assignment.isActive)
        .toList();

    // 6. Enforce doctor-level access control
    final Staff? user = ref.watch(currentUserProvider).value;
    if (user != null && user.role == UserRole.doctor) {
      final bool isDoctorOnAppointment =
          active.any((d) => d.doctor.id == user.id);
      if (!isDoctorOnAppointment) {
        final List<Staff> patientDoctors = await ref.watch(
          patientAssignedDoctorsProvider(appointment.patientId).future,
        );
        final bool isDoctorOnPatient =
            patientDoctors.any((d) => d.id == user.id);
        if (!isDoctorOnPatient) {
          throw const DatabaseException(
            code: 'db/permission-denied',
            message: 'Doctor is not assigned to this patient or appointment',
            userMessageKey: 'error_database_permission_denied',
          );
        }
      }
    }

    return (
      appointment: appointment,
      patient: patient,
      activeDoctors: active,
      inactiveDoctors: inactive,
    );
  }

  /// Resolves a single [AppointmentDoctor] into a fully-hydrated detail.
  Future<AppointmentDoctorDetail> _resolveDetail(
    AppointmentDoctor assignment,
  ) async {
    final Staff doctor = await ref.read(
      staffProfileProvider(assignment.doctorId).future,
    );

    return AppointmentDoctorDetail(assignment: assignment, doctor: doctor);
  }

  /// Transitions appointment status to [AppointmentStatus.checkedIn].
  Future<void> checkIn() => _updateStatus(AppointmentStatus.checkedIn);

  /// Transitions appointment status to [AppointmentStatus.cancelled].
  Future<void> cancel() => _updateStatus(AppointmentStatus.cancelled);

  /// Transitions appointment status back to [AppointmentStatus.scheduled].
  Future<void> revertToScheduled() =>
      _updateStatus(AppointmentStatus.scheduled);

  Future<void> _updateStatus(AppointmentStatus newStatus) async {
    await _assertCanModify();
    final AppointmentRepository repo = ref.read(appointmentRepositoryProvider);
    final Result<void> result = await repo.updateAppointmentStatus(
      appointmentId,
      newStatus,
    );
    if (!ref.mounted) return;
    switch (result) {
      case Success<void>():
        _invalidateCaches();
        ref.invalidateSelf();
        await future;
      case Failure<void>(:final exception):
        throw exception;
    }
  }

  Future<void> _assertCanModify() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      throw const DatabaseException(
        code: 'db/unauthorized',
        message: 'User is not authenticated',
        userMessageKey: 'error_auth_generic',
      );
    }
    if (user.role == UserRole.doctor) {
      final current = state.value;
      if (current == null) return;
      final bool isDoctorOnAppointment =
          current.activeDoctors.any((d) => d.doctor.id == user.id);
      if (!isDoctorOnAppointment) {
        final List<Staff> patientDoctors = await ref.read(
          patientAssignedDoctorsProvider(current.appointment.patientId).future,
        );
        if (!patientDoctors.any((d) => d.id == user.id)) {
          throw const DatabaseException(
            code: 'db/permission-denied',
            message: 'Doctor is not assigned to this patient or appointment',
            userMessageKey: 'error_database_permission_denied',
          );
        }
      }
    }
  }

  void _invalidateCaches() {
    final patientId = state.value?.appointment.patientId;
    ref.invalidate(todayAppointmentsProvider);
    ref.read(allAppointmentsProvider.notifier).refresh();
    if (patientId != null) {
      ref.invalidate(patientAppointmentsProvider(patientId));
      ref.invalidate(patientDetailProvider(patientId));
      ref.invalidate(futureScheduledAppointmentsCountProvider(patientId));
      ref.invalidate(availablePackageBalanceProvider(patientId));
    }
    ref.invalidate(doctorScheduleProvider);
    ref.invalidate(patientListProvider);

    // Refresh the receptionist dashboard queues immediately
    ref.read(receptionistAppointmentsProvider.notifier).loadToday();
    ref.read(bookingWorkboardProvider.notifier).refresh();
  }
}
