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
import 'package:spine_clinic_app/features/patient/domain/patient_documents_repository.dart';

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

  /// Uploads a document and refreshes the document list on success.
  ///
  /// Upload state is **decoupled from list state**: this notifier does
  /// NOT flip the family's `AsyncValue` to loading or error for
  /// upload outcomes — that would replace the documents list with
  /// `ErrorView` / `SkeletonTileList` for transient failures. The
  /// upload's [Result] is returned untouched so the caller can surface
  /// it via [AppSnackbar] without disturbing the visible list.
  Future<Result<PatientDocument>> uploadDocument({
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    // Rule 6: Every write action must read currentUserProvider to check role and id.
    final Staff? currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      return const Result.failure(
        AuthException(
          code: 'auth/unauthorized',
          message: 'Must be logged in to upload documents.',
          userMessageKey: 'error_auth_generic',
        ),
      );
    }

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

    // Refresh the list on success only. Failures are surfaced to the
    // caller via the returned Result and rendered as a snackbar; the
    // list itself stays visible.
    await result.when(
      success: (PatientDocument newDoc) async {
        ref.invalidateSelf();
        await future;
      },
      failure: (AppException exception) async {/* no state mutation */},
    );

    return result;
  }

  /// Deletes a document and refreshes the list.
  ///
  /// Same decoupled-state pattern as [uploadDocument]: deletion is a
  /// write action whose outcome belongs to the caller, never to the
  /// family's list state.
  ///
  /// Authorization is enforced at the DB layer via the
  /// `patient_documents` DELETE RLS policy (any active staff member
  /// with read access to the patient row can delete its documents).
  /// The notifier only verifies a session exists.
  Future<Result<void>> deleteDocument(PatientDocument doc) async {
    // Rule 6: Check logged-in user session. Per-role authorization
    // is enforced by RLS at delete time.
    final Staff? currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      return const Result.failure(
        AuthException(
          code: 'auth/unauthorized',
          message: 'Must be logged in to delete documents.',
          userMessageKey: 'error_auth_generic',
        ),
      );
    }

    final PatientDocumentsRepository repo =
        ref.read(patientDocumentsRepositoryProvider);
    final Result<void> result = await repo.deleteDocument(
      documentId: doc.id,
    );
    if (!ref.mounted) return result;

    await result.when(
      success: (_) async {
        ref.invalidateSelf();
        await future;
      },
      failure: (AppException exception) async {/* no state mutation */},
    );

    return result;
  }
}
