import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_appointments_state.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_medical_history.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_notes_list_state.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_history_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_notes_list_notifier.dart';
import 'workspace_data.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_with_patient.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';

class WorkspaceUser extends CurrentUser {
  WorkspaceUser(this.role);
  final String role;
  @override
  Future<Staff?> build() async => workspaceStaff(role);
}

class WorkspaceProgramData extends PatientProgramsNotifier {
  WorkspaceProgramData(this.empty);
  final bool empty;
  @override
  Future<List<PatientProgram>> build(String patientId) async => empty
      ? []
      : [
          ...workspacePrograms,
          workspacePrograms.first.copyWith(id: 'archived-program', status: ProgramStatus.archived),
        ];
}

class WorkspaceHistoryData extends PatientMedicalHistoryNotifier {
  WorkspaceHistoryData(this.empty);
  final bool empty;
  @override
  Future<PatientMedicalHistory?> build(String patientId) async => empty ? null : workspaceHistory;
}

class WorkspaceDocumentData extends PatientDocumentsNotifierNotifier {
  WorkspaceDocumentData(this.empty);
  final bool empty;
  @override
  Future<List<PatientDocument>> build(String patientId) async => empty ? [] : workspaceDocuments;
}

class WorkspaceAppointmentData extends PatientAppointments {
  @override
  PatientAppointmentsState build(String patientId) => PatientAppointmentsState(
    isLoading: false,
    appointments: [
      AppointmentWithPatient(
        patient: workspacePatient,
        doctorName: 'Dr. Mariam Khaled',
        appointment: Appointment(
          id: 'upcoming',
          patientId: patientId,
          type: AppointmentType.normalPtSession,
          scheduledAt: DateTime.now().add(const Duration(days: 1)),
          createdAt: DateTime(2026),
        ),
      ),
      AppointmentWithPatient(
        patient: workspacePatient,
        doctorName: 'Dr. Omar Salem',
        appointment: Appointment(
          id: 'past',
          patientId: patientId,
          type: AppointmentType.reassessment,
          status: AppointmentStatus.checkedIn,
          scheduledAt: DateTime(2026, 8, 12),
          createdAt: DateTime(2026),
        ),
      ),
    ],
  );
}

class WorkspaceNoteData extends PatientNotesList {
  @override
  PatientNotesListState build(String patientId) => PatientNotesListState(
    isLoading: false,
    notes: [
      PatientNote(
        id: 'note-fixture',
        patientId: patientId,
        createdBy: 'staff-fixture',
        noteText:
            'Patient reports improved tolerance to prolonged sitting. Reviewed home exercises and technique.',
        createdAt: DateTime(2026, 9, 6),
        updatedAt: DateTime(2026, 9, 6),
      ),
    ],
  );
}
