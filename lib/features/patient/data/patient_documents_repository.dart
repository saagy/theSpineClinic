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
  })  : _service = supabaseService,
        _cache = cache ?? PatientDocumentCache();

  final SupabaseService _service;
  final PatientDocumentCache _cache;

  static const int _maxBytes = 10 * 1024 * 1024; // 10 MB
  static const Duration _uploadTimeout = Duration(seconds: 30);

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
  }) =>
      _upload(
        patientId: patientId,
        fileName: fileName,
        fileBytes: fileBytes,
        uploadedBy: uploadedBy,
        programId: programId,
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

  Future<Result<PatientDocument>> _upload({
    required String patientId,
    required String fileName,
    required Uint8List fileBytes,
    required String uploadedBy,
    String? programId,
  }) async {
    if (fileBytes.length > _maxBytes) {
      return const Result.failure(
        StorageException(
          code: 'storage/file-too-large',
          message: 'File exceeds the 10 MB limit.',
          userMessageKey: 'error_doc_file_too_large',
        ),
      );
    }

    final String objectKey;
    try {
      final FunctionResponse fnRes = await _service.invokeFunction(
        'document-storage',
        body: {
          'action': 'get-upload-url',
          'patientId': patientId,
          'fileName': fileName,
        },
      );
      final data = fnRes.data as Map<String, dynamic>;
      final String uploadUrl = data['uploadUrl'] as String;
      objectKey = data['objectKey'] as String;
      final String contentType =
          (data['contentType'] as String?) ?? 'application/octet-stream';

      final http.Response putRes = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: fileBytes,
      );

      if (putRes.statusCode < 200 || putRes.statusCode >= 300) {
        throw StorageException(
          code: 'storage/upload-failed',
          message: 'R2 upload rejected with HTTP ${putRes.statusCode}',
          userMessageKey: 'error_unknown',
        );
      }
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }

    try {
      final Map<String, dynamic> row = await _service
          .from('patient_documents')
          .insert({
            'patient_id': patientId,
            'file_url': objectKey,
            'thumbnail_url': null,
            'file_name': fileName,
            'uploaded_by': uploadedBy,
            if (programId != null) 'program_id': programId,
          })
          .select()
          .single();
      _cache.put(objectKey, fileBytes);
      return Result.success(PatientDocument.fromJson(row));
    } on Exception catch (error) {
      // Compensating cleanup per Rule 27
      try {
        await _service.invokeFunction('document-storage', body: {
          'action': 'delete-objects',
          'objectKeys': [objectKey],
        });
      } catch (_) {}
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<Uint8List>> downloadDocumentBytes({
    required String fileUrl,
    required String fileName,
  }) async {
    try {
      final String? objectKey = patientDocumentStoragePath(fileUrl);
      if (objectKey == null || objectKey.isEmpty) {
        return const Result.failure(
          DatabaseException(
            code: 'db/invalid-path',
            message: 'Invalid storage path extracted from file URL.',
            userMessageKey: 'error_database_record_not_found',
          ),
        );
      }

      final Uint8List? cachedBytes = _cache.get(objectKey);
      if (cachedBytes != null) {
        return Result.success(cachedBytes);
      }

      // Legacy fallback: check if already in Supabase Storage
      final bool isLegacySupabase = fileUrl.contains('supabase.co/storage') ||
          fileUrl.contains('/storage/v1/object');
      if (isLegacySupabase) {
        try {
          final Uint8List bytes =
              await _service.storage('patient-documents').download(objectKey);
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
        final Uint8List bytes =
            await _service.storage('patient-documents').download(objectKey);
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
