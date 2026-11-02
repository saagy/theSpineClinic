import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_repository.dart';
import 'package:spine_clinic_app/features/patient/presentation/document_upload_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/new_patient_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import '../../fixtures/workspace_data.dart';
import '../../fixtures/workspace_document_repository.dart';

class _Reception extends CurrentUser {
  @override
  Future<Staff?> build() async => workspaceStaff('reception');
}

class _Patients implements PatientRepository {
  int creates = 0;
  @override
  Future<Result<Patient>> createPatient(Patient patient, List<String> doctors) async {
    creates++;
    return Result.success(workspacePatient);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Documents extends WorkspaceDocumentRepository {
  bool fail = true;
  int uploads = 0;
  @override
  Future<Result<List<PatientDocument>>> fetchDocuments(String patientId) async =>
      const Result.success([]);
  @override
  Future<Result<PatientDocument>> uploadDocument({
    required String patientId,
    required String fileName,
    required Uint8List fileBytes,
    required String uploadedBy,
    String? programId,
  }) async {
    uploads++;
    if (fail) {
      return const Result.failure(
        NetworkException(
          code: 'mutation/unconfirmed',
          message: 'Lost upload response',
          userMessageKey: 'mutation_unconfirmed',
        ),
      );
    }
    return Result.success(workspaceDocuments.first);
  }
}

void main() {
  test('patient remains saved and unfinished attachments transfer to document retry', () async {
    final patients = _Patients();
    final documents = _Documents();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(_Reception.new),
        patientRepositoryProvider.overrideWithValue(patients),
        patientDocumentsRepositoryProvider.overrideWithValue(documents),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    final result = await container
        .read(newPatientControllerProvider.notifier)
        .createPatient(
          fullName: workspacePatient.fullName,
          phoneNumber: workspacePatient.phoneNumber,
          clinic: workspacePatient.clinic,
          assignedDoctorIds: [],
          attachments: [
            PlatformFile(name: 'scan.pdf', size: 1, bytes: Uint8List.fromList([1])),
          ],
        );
    expect(result.isSuccess, true);
    final uploads = documentUploadControllerProvider(workspacePatient.id);
    expect(container.read(uploads).hasFailures, true);
    expect(container.read(uploads).files.single.bytes, isNotNull);
    documents.fail = false;
    await container.read(uploads.notifier).retry();
    expect(container.read(uploads).hasFailures, false);
    expect(patients.creates, 1);
    expect(documents.uploads, 2);
  });
}
