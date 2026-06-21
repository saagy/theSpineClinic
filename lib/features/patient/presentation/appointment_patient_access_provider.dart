/// Riverpod provider that decides whether the current user may tap through
/// from `appointment_detail_header.dart` into `PatientDetailScreen`.
///
/// Access is granted when ANY of:
///   - current user is NOT a doctor (admin / receptionist always pass), OR
///   - patient is permanently assigned to the doctor (via `patient_doctors`), OR
///   - doctor has at least one active `appointment_doctors` row linking them
///     to ANY appointment for this patient whose `scheduled_at` falls inside
///     `[NOW - 1 day, NOW + 7 days]`.
///
/// Rule 26 — the provider awaits `currentUserProvider` before reading.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_appointment_access.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

part 'appointment_patient_access_provider.g.dart';

/// Evaluates doctor access for the patient pill on a given [appointment].
///
/// Returns a sealed [PatientAppointmentAccess] branch.
@riverpod
Future<PatientAppointmentAccess> appointmentPatientAccess(
  Ref ref,
  Appointment appointment,
) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return notAuthenticated();
  if (user.role != UserRole.doctor) return granted();

  final patientRepo = ref.read(patientRepositoryProvider);
  final apptRepo = ref.read(appointmentRepositoryProvider);

  // Path A — permanent assignment.
  final Result<bool> assignmentResult = await patientRepo
      .isDoctorAssignedOrCovering(patientId: appointment.patientId, doctorId: user.id);
  final bool permanentlyAssigned = assignmentResult.when(
    success: (value) => value,
    failure: (_) => false,
  );
  if (permanentlyAssigned) return granted();

  // Path B — any active appointment between this doctor and this patient
  // inside the access window [NOW - 1 day, NOW + 7 days].
  final Result<bool> recentResult = await apptRepo
      .hasDoctorRecentAppointmentWithPatient(
        patientId: appointment.patientId,
        doctorId: user.id,
      );
  final bool hasRecent = recentResult.when(
    success: (value) => value,
    failure: (_) => false,
  );
  if (hasRecent) return granted();

  return expired();
}
