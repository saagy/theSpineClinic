/// Repository and implementation managing patient documents.
///
/// Communicates directly with Supabase Storage and database.
/// Wraps all async returns in [Result] to satisfy Rule 4.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/utils/file_cache_manager.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';

/// Repository interface defining document operations.
abstract class PatientDocumentsRepository {
  /// Fetches all documents associated with a specific patient, newest first.
  Future<Result<List<PatientDocument>>> fetchDocuments(String patientId);

  /// Uploads a file payload to storage and saves a record row in database.
  Future<Result<PatientDocument>> uploadDocument({
    required String patientId,
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
    required String uploadedBy,
  });

  /// Downloads raw bytes for a stored document.
  ///
  /// On web, downloads directly from Supabase Storage.
  /// On mobile/desktop, reads cached file bytes from the local file system.
  Future<Result<Uint8List>> downloadDocumentBytes({
    required String fileUrl,
    required String fileName,
  });

  /// Deletes a document record from database and its file from storage.
  Future<Result<void>> deleteDocument({
    required String documentId,
    required String storagePath,
  });
}

/// Supabase-backed implementation of [PatientDocumentsRepository].
class PatientDocumentsRepositoryImpl implements PatientDocumentsRepository {
  /// Creates a [PatientDocumentsRepositoryImpl].
  PatientDocumentsRepositoryImpl();

  /// Gets the underlying Supabase Client directly (Rule 1 / SupabaseService guard).
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<Result<List<PatientDocument>>> fetchDocuments(String patientId) async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('patient_documents')
          .select()
          .eq('patient_id', patientId)
          .order('uploaded_at', ascending: false);

      final List<PatientDocument> docs =
          rows.map(PatientDocument.fromJson).toList();
      return Result.success(docs);
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
    String? filePath,
    Uint8List? fileBytes,
    required String uploadedBy,
  }) async {
    try {
      // 1. Upload to Supabase Storage in 'patient-documents' bucket
      // Generate a unique path to avoid collisions
      final String storagePath =
          '$patientId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      if (fileBytes != null) {
        await _client.storage
            .from('patient-documents')
            .uploadBinary(storagePath, fileBytes);
      } else if (filePath != null) {
        await _client.storage
            .from('patient-documents')
            .upload(storagePath, File(filePath));
      } else {
        return const Result.failure(
          DatabaseException(
            code: 'db/invalid-payload',
            message: 'Both filePath and fileBytes are null.',
            userMessageKey: 'error_database_generic',
          ),
        );
      }

      // 2. Resolve the public URL
      final String fileUrl = _client.storage
          .from('patient-documents')
          .getPublicUrl(storagePath);

      // 3. Write row to public.patient_documents table
      final Map<String, dynamic> docRow = {
        'patient_id': patientId,
        'file_url': fileUrl,
        'file_name': fileName,
        'uploaded_by': uploadedBy,
      };

      final Map<String, dynamic> row = await _client
          .from('patient_documents')
          .insert(docRow)
          .select()
          .single();

      final PatientDocument createdDoc = PatientDocument.fromJson(row);
      return Result.success(createdDoc);
    } on PostgrestException catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<Uint8List>> downloadDocumentBytes({
    required String fileUrl,
    required String fileName,
  }) async {
    try {
      final String key = 'patient-documents/';
      final int index = fileUrl.indexOf(key);
      final String storagePath = index != -1
          ? Uri.decodeComponent(fileUrl.substring(index + key.length))
          : '';
      if (storagePath.isEmpty) {
        return const Result.failure(
          DatabaseException(
            code: 'db/invalid-path',
            message: 'Invalid storage path extracted from file URL.',
            userMessageKey: 'error_database_generic',
          ),
        );
      }
      if (kIsWeb) {
        final Uint8List bytes = await _client.storage
            .from('patient-documents')
            .download(storagePath);
        return Result.success(bytes);
      } else {
        final File file = await FileCacheManager.instance.getFile(fileUrl, fileName);
        final Uint8List bytes = await file.readAsBytes();
        return Result.success(bytes);
      }
    } on StorageException catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<void>> deleteDocument({
    required String documentId,
    required String storagePath,
  }) async {
    try {
      // 1. Remove from storage first
      if (storagePath.isNotEmpty) {
        await _client.storage.from('patient-documents').remove([storagePath]);
      }
      // 2. Delete the record row
      await _client.from('patient_documents').delete().eq('id', documentId);
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }
}
