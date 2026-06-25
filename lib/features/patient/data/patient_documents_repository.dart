/// Supabase-backed implementation of [PatientDocumentsRepository].
///
/// Communicates directly with Supabase Storage and the
/// `public.patient_documents` table. Wraps all async returns in
/// [Result] to satisfy Rule 4.
///
/// Storage model: each upload writes a single object to
/// `patient-documents/{patientId}/{timestamp}_{fileName}`. Bytes pass
/// through unchanged — no client-side compression.
library;

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/data/patient_storage_cleanup.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_documents_repository.dart';

/// Supabase-backed implementation of [PatientDocumentsRepository].
class PatientDocumentsRepositoryImpl implements PatientDocumentsRepository {
  /// Creates a [PatientDocumentsRepositoryImpl].
  PatientDocumentsRepositoryImpl();

  SupabaseClient get _client => Supabase.instance.client;

  static const String _bucket = 'patient-documents';
  static const int _maxBytes = 10 * 1024 * 1024;
  static const Duration _uploadTimeout = Duration(seconds: 30);

  @override
  Future<Result<List<PatientDocument>>> fetchDocuments(String patientId) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('patient_documents')
          .select()
          .eq('patient_id', patientId)
          .order('uploaded_at', ascending: false);
      return Result.success(rows.map(PatientDocument.fromJson).toList());
    } on PostgrestException catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<PatientDocument>> uploadDocument({
    required String patientId,
    required String fileName,
    required Uint8List fileBytes,
    required String uploadedBy,
  }) =>
      _uploadImpl(
        patientId: patientId,
        fileName: fileName,
        fileBytes: fileBytes,
        uploadedBy: uploadedBy,
      ).timeout(
        _uploadTimeout,
        onTimeout: () => const Result.failure(
          StorageException(
            code: 'storage/upload-timeout',
            message: 'Upload exceeded 30 seconds and was cancelled.',
            userMessageKey: 'error_unknown',
          ),
        ),
      );

  Future<Result<PatientDocument>> _uploadImpl({
    required String patientId,
    required String fileName,
    required Uint8List fileBytes,
    required String uploadedBy,
  }) async {
    try {
      if (fileBytes.length > _maxBytes) {
        return const Result.failure(
          StorageException(
            code: 'storage/file-too-large',
            message: 'File exceeds the 10 MB limit.',
            userMessageKey: 'error_doc_file_too_large',
          ),
        );
      }

      final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String storagePath = '$patientId/${stamp}_$fileName';
      await _client.storage
          .from(_bucket)
          .uploadBinary(storagePath, fileBytes);

      final String fileUrl =
          _client.storage.from(_bucket).getPublicUrl(storagePath);

      final Map<String, dynamic> row = await _client
          .from('patient_documents')
          .insert({
            'patient_id': patientId,
            'file_url': fileUrl,
            'thumbnail_url': null,
            'file_name': fileName,
            'uploaded_by': uploadedBy,
          })
          .select()
          .single();

      return Result.success(PatientDocument.fromJson(row));
    } on StorageException catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    } on PostgrestException catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      return Result.failure(UnknownException(message: e.toString()));
    }
  }

  @override
  Future<Result<Uint8List>> downloadDocumentBytes({
    required String fileUrl,
    required String fileName,
  }) async {
    try {
      final String? storagePath = _storagePathFromUrl(fileUrl);
      if (storagePath == null || storagePath.isEmpty) {
        return const Result.failure(
          DatabaseException(
            code: 'db/invalid-path',
            message: 'Invalid storage path extracted from file URL.',
            userMessageKey: 'error_database_record_not_found',
          ),
        );
      }
      final Uint8List bytes =
          await _client.storage.from(_bucket).download(storagePath);
      return Result.success(bytes);
    } on StorageException catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<void>> deleteDocument({required String documentId}) async {
    try {
      final Map<String, dynamic>? row = await _client
          .from('patient_documents')
          .select('file_url, thumbnail_url')
          .eq('id', documentId)
          .maybeSingle();

      // DB row FIRST. If this fails (e.g. RLS denies) no storage
      // object is touched — the original bug is "blob gone, row
      // remains, broken UI"; this ordering prevents it.
      await _client.from('patient_documents').delete().eq('id', documentId);

      // Storage sweep is best-effort. The DB row is the source of
      // truth for the UI; a transient blob-removal failure leaves
      // an orphan that is reaped by [deletePatientStorageFolder]
      // when the patient is later deleted.
      if (row != null) {
        final List<String> paths = <String>[];
        final String? main = _storagePathFromUrl(row['file_url'] as String?);
        if (main != null && main.isNotEmpty) paths.add(main);
        final String? thumb =
            _storagePathFromUrl(row['thumbnail_url'] as String?);
        if (thumb != null && thumb.isNotEmpty) paths.add(thumb);
        if (paths.isNotEmpty) {
          // Storage sweep is best-effort. The DB row is the source
          // of truth for the UI; a transient blob-removal failure
          // leaves an orphan that is reaped by [deletePatient] ->
          // [deletePatientStorageFolder] when the patient is
          // later deleted. Swallow with try/catch (returning the
          // empty list silences the analyzer).
          try {
            await _client.storage.from(_bucket).remove(paths);
            // ignore: unused_result
          } on StorageException {
            // Orphan tolerated; see comment above.
          }
        }
      }
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<void>> deletePatientStorageFolder(String patientId) =>
      deletePatientStorageFolderImpl(patientId);

  /// Extracts the relative storage path from a public URL.
  ///
  /// Works for any URL prefix (`object/public/...`,
  /// `object/sign/...`, `rendition/...`, etc.).
  static String? _storagePathFromUrl(String? url) {
    if (url == null) return null;
    const String key = 'patient-documents/';
    final int idx = url.indexOf(key);
    if (idx == -1) return null;
    return Uri.decodeComponent(url.substring(idx + key.length));
  }
}
