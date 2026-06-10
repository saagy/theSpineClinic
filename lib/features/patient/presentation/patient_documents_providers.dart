/// Riverpod providers for the patient documents feature.
///
/// Exposes:
/// - [patientDocumentsRepositoryProvider] — repository access.
/// - [PatientDocumentsNotifierNotifier] — family AsyncNotifier managing documents list state.
///
/// Rule 3 — all state via Riverpod.
/// Rule 5 & 6 — read currentUserProvider role/id for write actions.
library;

import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/data/patient_documents_repository.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';

part 'patient_documents_providers.g.dart';

/// Provides a singleton [PatientDocumentsRepository] instance.
@Riverpod(keepAlive: true)
PatientDocumentsRepository patientDocumentsRepository(Ref ref) {
  return PatientDocumentsRepositoryImpl();
}

/// Family AsyncNotifier managing the document list state for a patient.
@riverpod
class PatientDocumentsNotifierNotifier
    extends _$PatientDocumentsNotifierNotifier {
  @override
  FutureOr<List<PatientDocument>> build(String patientId) async {
    final PatientDocumentsRepository repo =
        ref.watch(patientDocumentsRepositoryProvider);
    final Result<List<PatientDocument>> result =
        await repo.fetchDocuments(patientId);

    return result.when(
      success: (List<PatientDocument> data) => data,
      failure: (AppException exception) => throw exception,
    );
  }

  /// Uploads a document and refreshes the document list.
  Future<Result<PatientDocument>> uploadDocument({
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    // Rule 6: Every write action must read currentUserProvider to check role and id
    final Staff? currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      final exception = const AuthException(
        code: 'auth/unauthorized',
        message: 'Must be logged in to upload documents.',
        userMessageKey: 'error_auth_generic',
      );
      return Result.failure(exception);
    }

    state = const AsyncValue.loading();

    final PatientDocumentsRepository repo =
        ref.read(patientDocumentsRepositoryProvider);
    final Result<PatientDocument> result = await repo.uploadDocument(
      patientId: patientId,
      fileName: fileName,
      filePath: filePath,
      fileBytes: fileBytes,
      uploadedBy: currentUser.id,
    );
    if (!ref.mounted) return result;

    await result.when(
      success: (PatientDocument newDoc) async {
        ref.invalidateSelf();
        await future;
      },
      failure: (AppException exception) async {
        state = AsyncValue.error(exception, StackTrace.current);
      },
    );

    return result;
  }

  /// Deletes a document and refreshes the list.
  Future<Result<void>> deleteDocument(PatientDocument doc) async {
    // Rule 6: Check logged-in user session
    final Staff? currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      final exception = const AuthException(
        code: 'auth/unauthorized',
        message: 'Must be logged in to delete documents.',
        userMessageKey: 'error_auth_generic',
      );
      return Result.failure(exception);
    }

    state = const AsyncValue.loading();

    // Extract storage path from fileUrl
    final String key = 'patient-documents/';
    final int index = doc.fileUrl.indexOf(key);
    final String storagePath = index != -1
        ? Uri.decodeComponent(doc.fileUrl.substring(index + key.length))
        : '';

    final PatientDocumentsRepository repo =
        ref.read(patientDocumentsRepositoryProvider);
    final Result<void> result = await repo.deleteDocument(
      documentId: doc.id,
      storagePath: storagePath,
    );
    if (!ref.mounted) return result;

    await result.when(
      success: (_) async {
        ref.invalidateSelf();
        await future;
      },
      failure: (AppException exception) async {
        state = AsyncValue.error(exception, StackTrace.current);
      },
    );

    return result;
  }
}
