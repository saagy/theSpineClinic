import 'package:file_picker/file_picker.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

part 'new_patient_controller.g.dart';

/// Per-attachment upload status surfaced to the form so it can render
/// real-time progress chips.
enum AttachmentStatus { idle, uploading, done, failed }

/// Provides a fine-grained status for each picked attachment during
/// the [NewPatientController]'s submit loop. Index‑keyed family so
/// the form renders status per row.
@riverpod
class IndexedAttachmentStatus extends _$IndexedAttachmentStatus {
  @override
  AttachmentStatus build(int index) => AttachmentStatus.idle;

  void set(AttachmentStatus value) => state = value;
}

/// Value object returned to the form after patient creation completes.
///
/// Carries the newly created [patient] (always present unless the DB
/// call itself failed) and the per‑file upload outcomes so the form
/// can show partial‑failure feedback when `attachmentResults` contains
/// one or more failures.
@immutable
class CreatePatientOutcome {
  const CreatePatientOutcome({
    required this.patient,
    required this.attachmentResults,
  });

  final Patient patient;
  final List<Result<PatientDocument>> attachmentResults;

  /// `true` when every attachment uploaded without error.
  bool get allAttachmentsSucceeded =>
      attachmentResults.every((r) => r is Success<PatientDocument>);

  bool get anyAttachmentFailed =>
      attachmentResults.any((r) => r is Failure<PatientDocument>);
}

/// Notifier provider handling form submission states for NewPatientScreen.
@riverpod
class NewPatientController extends _$NewPatientController {
  @override
  FutureOr<void> build() {
    // Initial state is idle (AsyncData(null))
  }

  /// Registers a new patient, assigns doctors, and uploads attachments.
  ///
  /// The patient row is created atomically via the SQL RPC
  /// `create_patient_with_doctors` — it either succeeds (patient exists)
  /// or fails (everything rolled back). Attachments are best‑effort
  /// after the patient is committed. Partial failures DO NOT roll back
  /// the patient row; the form navigates to the patient detail page and
  /// shows a snackbar listing how many files did not upload.
  Future<Result<Patient>> createPatient({
    required String fullName,
    required String phoneNumber,
    required String? program,
    required ClinicLocation clinic,
    required List<String> assignedDoctorIds,
    required List<PlatformFile> attachments,
  }) async {
    state = const AsyncValue.loading();
    final patientRepo = ref.read(patientRepositoryProvider);
    final currentUser = ref.read(currentUserProvider).value;

    final patient = Patient(
      id: '',
      fullName: fullName,
      phoneNumber: phoneNumber,
      program: program?.trim().isEmpty == true ? null : program,
      clinic: clinic,
      sessionBalance: 0,
      tractionBalance: 0,
      createdBy: currentUser?.id,
      createdAt: DateTime.now(),
    );

    final Result<Patient> result =
        await patientRepo.createPatient(patient, assignedDoctorIds);
    if (!ref.mounted) return result;

    final List<Result<PatientDocument>> attachmentResults = [];
    if (result is Success<Patient> && attachments.isNotEmpty) {
      final createdPatient = result.data;
      final docRepo = ref.read(patientDocumentsRepositoryProvider);

      for (int i = 0; i < attachments.length; i++) {
        ref.read(indexedAttachmentStatusProvider(i).notifier)
            .set(AttachmentStatus.uploading);
        final file = attachments[i];
        final bytes = file.bytes;
        if (bytes == null) {
          ref.read(indexedAttachmentStatusProvider(i).notifier)
              .set(AttachmentStatus.failed);
          continue;
        }
        final uploadResult = await docRepo.uploadDocument(
          patientId: createdPatient.id,
          fileName: file.name,
          fileBytes: bytes,
          uploadedBy: currentUser?.id ?? '',
        );
        attachmentResults.add(uploadResult);
        if (!ref.mounted) return result;
        ref.read(indexedAttachmentStatusProvider(i).notifier).set(
              uploadResult is Success<PatientDocument>
                  ? AttachmentStatus.done
                  : AttachmentStatus.failed,
            );
      }
    }

    if (!ref.mounted) return result;
    state = result.when(
      success: (createdPatient) {
        ref.invalidate(patientSearchProvider);
        return const AsyncValue.data(null);
      },
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );

    return result;
  }
}
