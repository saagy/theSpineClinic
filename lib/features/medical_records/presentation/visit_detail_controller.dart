import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_doctor.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';

part 'visit_detail_controller.g.dart';

/// State shape for the visit detail screen.
typedef VisitDetailState = ({
  Appointment appointment,
  Patient patient,
  List<AppointmentDoctorDetail> activeDoctors,
  PatientNote? note,
  bool canEditNotes,
});

/// Controller managing a single completed visit's detail state.
@riverpod
class VisitDetailController extends _$VisitDetailController {
  @override
  Future<VisitDetailState> build(String appointmentId) async {
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

    // 3. Fetch active attending doctor assignments (is_active == true)
    final Result<List<AppointmentDoctor>> assignmentsResult =
        await repo.getAppointmentDoctors(appointmentId);
    final List<AppointmentDoctor> activeAssignments = switch (assignmentsResult) {
      Success<List<AppointmentDoctor>>(:final data) => data,
      Failure<List<AppointmentDoctor>>(:final exception) => throw exception,
    };

    // 4. Resolve staff profile info for each assignment concurrently
    final List<AppointmentDoctorDetail> activeDoctors =
        await Future.wait(activeAssignments.map(_resolveDetail));

    // 5. Fetch linked note from patient_notes
    final PatientNote? note = await ref.watch(appointmentNoteProvider(appointmentId).future);

    // 6. Evaluate notes editing access (Rule 6).
    // Super admins can always edit. Doctors can edit if they are the
    // attending doctor AND the appointment is checked-in or completed.
    final Staff? currentUser = ref.watch(currentUserProvider).value;
    bool canEditNotes = false;

    if (currentUser != null) {
      if (currentUser.role == UserRole.superAdmin) {
        canEditNotes = true;
      } else if (currentUser.role == UserRole.doctor) {
        final bool isAttendingDoctor =
            activeDoctors.any((d) => d.doctor.id == currentUser.id);
        final bool isCorrectStatus =
            appointment.status == AppointmentStatus.checkedIn ||
                appointment.status == AppointmentStatus.completed;

        canEditNotes = isAttendingDoctor && isCorrectStatus;
      }
    }

    return (
      appointment: appointment,
      patient: patient,
      activeDoctors: activeDoctors,
      note: note,
      canEditNotes: canEditNotes,
    );
  }

  Future<AppointmentDoctorDetail> _resolveDetail(
    AppointmentDoctor assignment,
  ) async {
    final Staff doctor =
        await ref.read(staffProfileProvider(assignment.doctorId).future);

    final Staff? replacedDoctor = assignment.replacedDoctorId != null
        ? await ref
            .read(staffProfileProvider(assignment.replacedDoctorId!).future)
        : null;

    return AppointmentDoctorDetail(
      assignment: assignment,
      doctor: doctor,
      replacedDoctor: replacedDoctor,
    );
  }
}
