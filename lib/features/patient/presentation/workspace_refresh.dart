import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart'
    as appointments;
import 'package:spine_clinic_app/features/medical_records/presentation/medical_history_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_notes_list_notifier.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';

Future<void> refreshPatientWorkspace(WidgetRef ref, String patientId) async {
  ref.invalidate(patientDetailProvider(patientId));
  ref.invalidate(patientAssignedDoctorsProvider(patientId));
  ref.invalidate(patientIsEmptyProvider(patientId));
  ref.invalidate(patientPaymentsProvider(patientId));
  ref.invalidate(patientMedicalHistoryProvider(patientId));
  ref.invalidate(patientProgramsProvider(patientId));
  ref.invalidate(patientDocumentsNotifierProvider(patientId));
  ref.invalidate(appointments.patientAppointmentsProvider(patientId));
  ref.invalidate(patientAppointmentsProvider(patientId));
  ref.invalidate(patientNotesListProvider(patientId));
  try {
    await ref.read(patientDetailProvider(patientId).future);
  } catch (_) {
    // The provider's error state renders the retry action in the workspace.
  }
}
