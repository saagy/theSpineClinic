import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/patient/data/patient_document_storage.dart';
import 'package:spine_clinic_app/features/patient/data/patient_storage_cleanup.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_documents_repository.dart';

/// Supabase-backed patient document metadata and Storage operations.
class PatientDocumentsRepositoryImpl implements PatientDocumentsRepository {
  PatientDocumentsRepositoryImpl({required SupabaseService supabaseService})
    : _service = supabaseService;

  final SupabaseService _service;

  static const String _bucket = 'patient-documents';
  static const int _maxBytes = 10 * 1024 * 1024;
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
  }) =>
      _upload(
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

  Future<Result<PatientDocument>> _upload({
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
      await _service.storage(_bucket).uploadBinary(storagePath, fileBytes);
      final String fileUrl = _service
          .storage(_bucket)
          .getPublicUrl(storagePath);
      final Map<String, dynamic> row = await _service
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
    } on PostgrestException catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<Uint8List>> downloadDocumentBytes({
    required String fileUrl,
    required String fileName,
  }) async {
    try {
      final String? storagePath = patientDocumentStoragePath(fileUrl);
      if (storagePath == null || storagePath.isEmpty) {
        return const Result.failure(
          DatabaseException(
            code: 'db/invalid-path',
            message: 'Invalid storage path extracted from file URL.',
            userMessageKey: 'error_database_record_not_found',
          ),
        );
      }
      return Result.success(
        await _service.storage(_bucket).download(storagePath),
      );
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
        bucket: _bucket,
        documentId: documentId,
      );

  @override
  Future<Result<void>> deletePatientStorageFolder(String patientId) =>
      deletePatientStorageFolderImpl(_service, patientId);
}
