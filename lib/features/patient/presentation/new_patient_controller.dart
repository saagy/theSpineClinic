import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'document_upload_controller.dart';
import 'document_upload_state.dart';
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

/// Notifier provider handling form submission states for NewPatientScreen.
@Riverpod(keepAlive: true)
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
  /// retains unsuccessful files in the patient document upload controller.
  Future<Result<Patient>> createPatient({
    required String fullName,
    required String phoneNumber,
    required ClinicLocation clinic,
    required List<String> assignedDoctorIds,
    required List<PlatformFile> attachments,
    PatientPersonalDetails personalDetails = const PatientPersonalDetails(nationality: AppStrings.egyptianNationality),
  }) async {
    if (state.isLoading) {
      return const Result.failure(
        AuthException(
          code: 'mutation/in-flight',
          message: 'Patient registration is already in progress.',
          userMessageKey: 'mutation_unconfirmed',
        ),
      );
    }
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null ||
        !currentUser.isActive ||
        (!currentUser.isSeniorDoctor && currentUser.role != UserRole.receptionist)) {
      return const Result.failure(
        AuthException(
          code: 'auth/permission-denied',
          message: 'Patient registration is not permitted.',
          userMessageKey: 'error_permission_denied',
        ),
      );
    }
    state = const AsyncValue.loading();
    final patientRepo = ref.read(patientRepositoryProvider);

    final patient = Patient(
      id: '',
      fullName: fullName,
      phoneNumber: phoneNumber,
      clinic: clinic,
      personalDetails: personalDetails,
      sessionBalance: 0,
      tractionBalance: 0,
      createdBy: currentUser.id,
      createdAt: DateTime.now(),
    );

    final Result<Patient> result = await patientRepo.createPatient(patient, assignedDoctorIds);
    if (!ref.mounted) return result;

    final List<DocumentUploadItem> unfinished = [];
    if (result is Success<Patient> && attachments.isNotEmpty) {
      final createdPatient = result.data;
      final docRepo = ref.read(patientDocumentsRepositoryProvider);

      for (int i = 0; i < attachments.length; i++) {
        ref.read(indexedAttachmentStatusProvider(i).notifier).set(AttachmentStatus.uploading);
        final file = attachments[i];
        final bytes = file.bytes;
        if (bytes == null) {
          unfinished.add(
            DocumentUploadItem(
              fileName: file.name,
              bytes: null,
              status: DocumentUploadStatus.failed,
              error: const StorageException(
                code: 'storage/missing-bytes',
                message: 'Select the original file again.',
                userMessageKey: 'select_file_again',
              ),
            ),
          );
          ref.read(indexedAttachmentStatusProvider(i).notifier).set(AttachmentStatus.failed);
          continue;
        }
        final uploadResult = await docRepo.uploadDocument(
          patientId: createdPatient.id,
          fileName: file.name,
          fileBytes: bytes,
          uploadedBy: currentUser.id,
        );
        if (!ref.mounted) return result;
        if (uploadResult.isFailure) {
          unfinished.add(
            DocumentUploadItem(
              fileName: file.name,
              bytes: bytes,
              status: DocumentUploadStatus.failed,
              error: uploadResult.exceptionOrNull,
            ),
          );
        }
        ref
            .read(indexedAttachmentStatusProvider(i).notifier)
            .set(
              uploadResult is Success<PatientDocument>
                  ? AttachmentStatus.done
                  : AttachmentStatus.failed,
            );
      }
      ref
          .read(documentUploadControllerProvider(createdPatient.id).notifier)
          .retainFailures(unfinished);
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
