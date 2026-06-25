/// Repository interface for patient document operations.
///
/// Wraps all async returns in [Result] to satisfy Rule 4.
///
/// Storage model: each upload writes a single object to
/// `patient-documents/{patientId}/{timestamp}_{fileName}`. The optional
/// `thumbnail_url` column is preserved on the table for
/// forward-compatibility with future server-side compression.
library;

import 'dart:typed_data';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';

/// Repository interface defining document operations.
abstract class PatientDocumentsRepository {
  /// Fetches all documents associated with a specific patient, newest first.
  Future<Result<List<PatientDocument>>> fetchDocuments(String patientId);

  /// Uploads a byte payload to storage and saves a record row in database.
  ///
  /// Bytes pass through unchanged — no client-side compression. The
  /// `thumbnail_url` column is intentionally left `null`; a future
  /// server-side job (Edge Function or Storage Transform) can populate
  /// it without any client change.
  ///
  /// Callers MUST supply [fileBytes]. Web builds have no filesystem
  /// path, and mobile pickers always populate [bytes] alongside any
  /// path they expose.
  Future<Result<PatientDocument>> uploadDocument({
    required String patientId,
    required String fileName,
    required Uint8List fileBytes,
    required String uploadedBy,
  });

  /// Downloads raw bytes for a stored document. No client cache —
  /// every call hits Supabase Storage.
  Future<Result<Uint8List>> downloadDocumentBytes({
    required String fileUrl,
    required String fileName,
  });

  /// Deletes a document row and its single linked storage object.
  /// DB row deletion happens first; if it succeeds but the blob
  /// removal fails, the orphan blob is silently tolerated and is
  /// swept up by [deletePatientStorageFolder] during a later patient
  /// deletion.
  Future<Result<void>> deleteDocument({required String documentId});

  /// Lists all objects under the `{patientId}/` folder and removes
  /// them in paginated batches. No-op when the folder is empty.
  ///
  /// Used as a safety-net cleanup during patient deletion to sweep
  /// up orphaned blobs from failed uploads.
  Future<Result<void>> deletePatientStorageFolder(String patientId);
}
