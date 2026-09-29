import 'patient_document_upload.dart';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/patient/data/patient_document_cache.dart';
import 'package:spine_clinic_app/features/patient/data/patient_document_storage.dart';
import 'package:spine_clinic_app/features/patient/data/patient_storage_cleanup.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_documents_repository.dart';

/// Cloudflare R2-backed patient document metadata and storage operations.
class PatientDocumentsRepositoryImpl implements PatientDocumentsRepository {
  PatientDocumentsRepositoryImpl({
    required SupabaseService supabaseService,
    PatientDocumentCache? cache,
  }) : _service = supabaseService,
       _cache = cache ?? PatientDocumentCache();

  final SupabaseService _service;
  final PatientDocumentCache _cache;

  @override
  Future<Result<List<PatientDocument>>> fetchDocuments(String patientId) async {
    try {
      final List<Map<String, dynamic>> rows = await _service
          .from('patient_documents')
          .select()
          .eq('patient_id', patientId)
          .order('uploaded_at', ascending: false);
      return Result.success(rows.map(PatientDocument.fromJson).toList());
    } on PostgrestException catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<PatientDocument>> uploadDocument({
    required String patientId,
    required String fileName,
    required Uint8List fileBytes,
    required String uploadedBy,
    String? programId,
  }) => PatientDocumentUpload(_service, _cache).upload(
    patientId: patientId,
    fileName: fileName,
    fileBytes: fileBytes,
    uploadedBy: uploadedBy,
    programId: programId,
  );

  @override
  Future<Result<Uint8List>> downloadDocumentBytes({
    required String fileUrl,
    required String fileName,
  }) async {
    try {
      final String? objectKey = patientDocumentStoragePath(fileUrl);
      if (objectKey == null || !isPatientDocumentStoragePath(objectKey)) {
        return const Result.failure(
          DatabaseException(
            code: 'db/invalid-path',
            message: 'Invalid storage path extracted from file URL.',
            userMessageKey: 'error_doc_link_incomplete',
          ),
        );
      }

      final Uint8List? cachedBytes = _cache.get(objectKey);
      if (cachedBytes != null) {
        return Result.success(cachedBytes);
      }

      // Legacy fallback: check if already in Supabase Storage
      final bool isLegacySupabase =
          fileUrl.contains('supabase.co/storage') ||
          fileUrl.contains('/storage/v1/object');
      if (isLegacySupabase) {
        try {
          final Uint8List bytes = await _service
              .storage('patient-documents')
              .download(objectKey);
          _cache.put(objectKey, bytes);
          return Result.success(bytes);
        } catch (_) {}
      }

      final FunctionResponse fnRes = await _service.invokeFunction(
        'document-storage',
        body: {'action': 'get-download-url', 'objectKey': objectKey},
      );
      final data = fnRes.data as Map<String, dynamic>;
      final String downloadUrl = data['downloadUrl'] as String;

      final http.Response getRes = await http.get(Uri.parse(downloadUrl));
      if (getRes.statusCode >= 200 && getRes.statusCode < 300) {
        _cache.put(objectKey, getRes.bodyBytes);
        return Result.success(getRes.bodyBytes);
      }

      // If R2 returns 404/403, attempt Supabase Storage fallback
      try {
        final Uint8List bytes = await _service
            .storage('patient-documents')
            .download(objectKey);
        _cache.put(objectKey, bytes);
        return Result.success(bytes);
      } catch (_) {
        throw StorageException(
          code: 'storage/download-failed',
          message: 'Download failed with HTTP ${getRes.statusCode}',
          userMessageKey: 'error_unknown',
        );
      }
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<PatientDocument>> renameDocument({
    required String documentId,
    required String fileName,
  }) async {
    try {
      final String trimmed = fileName.trim();
      if (trimmed.isEmpty ||
          trimmed.length > 255 ||
          trimmed.contains(RegExp(r'[\x00-\x1F\x7F]'))) {
        return const Result.failure(
          DatabaseException(
            code: 'db/invalid-document-name',
            message: 'Document name must be 1-255 printable characters.',
            userMessageKey: 'error_database_validation_failed',
          ),
        );
      }
      final Map<String, dynamic> row = await _service
          .from('patient_documents')
          .update({'file_name': trimmed})
          .eq('id', documentId)
          .select()
          .single();
      return Result.success(PatientDocument.fromJson(row));
    } on PostgrestException catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<void>> deleteDocument({required String documentId}) =>
      deleteStoredPatientDocument(
        service: _service,
        documentId: documentId,
        cache: _cache,
      );

  @override
  Future<Result<void>> deletePatientStorageFolder(String patientId) {
    _cache.removeByPrefix('$patientId/');
    return deletePatientStorageFolderImpl(_service, patientId);
  }
}
