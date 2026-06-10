import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_doctor.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';

part 'add_visit_notes_controller.g.dart';

/// State shape for the add visit notes screen.
typedef AddVisitNotesState = ({
  Appointment appointment,
  Patient patient,
  PatientNote? note,
  bool isAuthorized,
});

/// Controller managing a single appointment's visit notes state and updates.
@riverpod
class AddVisitNotesController extends _$AddVisitNotesController {
  @override
  Future<AddVisitNotesState> build(String appointmentId) async {
    final AppointmentRepository repo = ref.read(appointmentRepositoryProvider);

    // 1. Fetch appointment
    final Result<Appointment> appointmentResult =
        await repo.getAppointmentById(appointmentId);
    final Appointment appointment = switch (appointmentResult) {
      Success<Appointment>(:final data) => data,
      Failure<Appointment>(:final exception) => throw exception,
    };

    // 2. Fetch patient
    final Patient patient =
        await ref.watch(patientDetailProvider(appointment.patientId).future);

    // 3. Check authorization (Rule 6)
    final Staff? currentUser = ref.watch(currentUserProvider).value;
    bool isAuthorized = false;

    if (currentUser != null) {
      if (currentUser.role == UserRole.superAdmin) {
        isAuthorized = true;
      } else if (currentUser.role == UserRole.doctor) {
        // Only doctor assigned to or covering the appointment is authorized
        final Result<List<AppointmentDoctor>> doctorsResult =
            await repo.getAppointmentDoctors(appointmentId);
        final List<AppointmentDoctor> activeDoctors = switch (doctorsResult) {
          Success<List<AppointmentDoctor>>(:final data) => data,
          Failure<List<AppointmentDoctor>>() => [],
        };

        isAuthorized =
            activeDoctors.any((doc) => doc.doctorId == currentUser.id);
      }
    }

    // 4. Fetch linked note
    final PatientNote? note = await ref.watch(appointmentNoteProvider(appointmentId).future);

    return (
      appointment: appointment,
      patient: patient,
      note: note,
      isAuthorized: isAuthorized,
    );
  }

  /// Updates notes column for the current appointment.
  Future<void> saveNotes(String notes) async {
    final AddVisitNotesState currentState = await future;
    if (!ref.mounted) return;
    if (!currentState.isAuthorized) {
      throw Exception('Access denied: Unauthorized role or assignment.');
    }

    // Save notes to patient_notes table
    await ref
        .read(appointmentNoteProvider(appointmentId).notifier)
        .saveNote(
          noteText: notes,
          patientId: currentState.appointment.patientId,
        );
    if (!ref.mounted) return;

    ref.invalidate(appointmentDetailControllerProvider(appointmentId));
    ref.invalidate(todayAppointmentsProvider);
    ref.invalidateSelf();
    await future;
  }

  /// Saves notes and transitions appointment status to completed.
  Future<void> completeAppointment(String notes) async {
    final AddVisitNotesState currentState = await future;
    if (!ref.mounted) return;
    if (!currentState.isAuthorized) {
      throw Exception('Access denied: Unauthorized role or assignment.');
    }

    // First save the current notes
    await ref
        .read(appointmentNoteProvider(appointmentId).notifier)
        .saveNote(
          noteText: notes,
          patientId: currentState.appointment.patientId,
        );
    if (!ref.mounted) return;

    final AppointmentRepository repo = ref.read(appointmentRepositoryProvider);
    // Then mark appointment as completed
    final Result<void> statusResult = await repo.updateAppointmentStatus(
      appointmentId,
      AppointmentStatus.completed,
    );
    if (!ref.mounted) return;

    switch (statusResult) {
      case Success<void>():
        ref.invalidate(appointmentDetailControllerProvider(appointmentId));
        ref.invalidate(todayAppointmentsProvider);
        ref.invalidateSelf();
        await future;
      case Failure<void>(:final exception):
        throw exception;
    }
  }
}
