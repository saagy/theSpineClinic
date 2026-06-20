/// Repository and implementation managing patient documents.
///
/// Communicates directly with Supabase Storage and database.
/// Wraps all async returns in [Result] to satisfy Rule 4.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;

import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/utils/file_cache_manager.dart';
import 'package:spine_clinic_app/features/patient/data/image_compress_service.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';

/// Repository interface defining document operations.
abstract class PatientDocumentsRepository {
  /// Fetches all documents associated with a specific patient, newest first.
  Future<Result<List<PatientDocument>>> fetchDocuments(String patientId);

  /// Uploads a file payload to storage and saves a record row in database.
  ///
  /// For image uploads the bytes are compressed (skipped when already
  /// ≤ 400 KB) and a 320×320 thumbnail is generated and uploaded
  /// alongside. PDF uploads are byte-pass-through with a size guard.
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
  ///
  /// [compressService] compresses uploaded images and produces
  /// thumbnails. Pass a no-op if compression is undesired (testing only).
  PatientDocumentsRepositoryImpl({required ImageCompressService compressService})
      : _compressService = compressService;

  final ImageCompressService _compressService;

  /// Gets the underlying Supabase Client directly (Rule 1 / SupabaseService guard).
  SupabaseClient get _client => Supabase.instance.client;

  // Upload size guards.
  static const int _maxImageBytes = 25 * 1024 * 1024;
  static const int _maxPdfBytes = 10 * 1024 * 1024;

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

  /// Hard timeout ceiling for any single upload pipeline call.
  ///
  /// Acts as the last-line safety net so that an underlying plugin
  /// deadlock (notably `flutter_image_compress` on web, where
  /// `compressWithList` can throw `UnimplementedError` or hang) cannot
  /// trap the caller in a permanent loading state.
  static const Duration _uploadTimeout = Duration(seconds: 30);

  @override
  Future<Result<PatientDocument>> uploadDocument({
    required String patientId,
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
    required String uploadedBy,
  }) async {
    return _uploadDocumentImpl(
      patientId: patientId,
      fileName: fileName,
      filePath: filePath,
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
  }

  Future<Result<PatientDocument>> _uploadDocumentImpl({
    required String patientId,
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
    required String uploadedBy,
  }) async {
    try {
      // 0. Resolve bytes (read from disk if a file path was supplied).
      Uint8List? bytes = fileBytes;
      if (bytes == null && filePath != null) {
        bytes = await File(filePath).readAsBytes();
      }
      if (bytes == null) {
        return const Result.failure(
          DatabaseException(
            code: 'db/invalid-payload',
            message: 'Both filePath and fileBytes are null.',
            userMessageKey: 'error_database_generic',
          ),
        );
      }

      // 1. Classify by extension + enforce size guards.
      final String ext = p.extension(fileName).toLowerCase();
      final bool isImage = const ['.png', '.jpg', '.jpeg', '.heic']
          .contains(ext);
      final bool isPdf = ext == '.pdf';

      if (isImage && bytes.length > _maxImageBytes) {
        return const Result.failure(
          StorageException(
            code: 'storage/image-too-large',
            message: 'Image upload exceeds the 25 MB limit.',
            userMessageKey: 'error_doc_image_too_large',
          ),
        );
      }
      if (isPdf && bytes.length > _maxPdfBytes) {
        return const Result.failure(
          StorageException(
            code: 'storage/pdf-too-large',
            message: 'PDF upload exceeds the 10 MB limit.',
            userMessageKey: 'error_doc_pdf_too_large',
          ),
        );
      }

      // 2. Image-only: compress (skip if already small) + generate thumb.
      Uint8List uploadBytes = bytes;
      String? thumbnailStoragePath;
      Uint8List? thumbnailBytes;
      if (isImage) {
        uploadBytes = await _compressService.compressForUpload(
          source: bytes,
          originalName: fileName,
        );
        thumbnailBytes = await _compressService.compressForThumbnail(
          source: bytes,
          originalName: fileName,
        );
      }

      // 3. Upload to Supabase Storage in 'patient-documents' bucket.
      final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String storagePath = '$patientId/${stamp}_$fileName';
      await _client.storage
          .from('patient-documents')
          .uploadBinary(storagePath, uploadBytes);

      // 4. Upload thumbnail (same bucket, separate path).
      if (thumbnailBytes != null) {
        thumbnailStoragePath =
            '$patientId/${stamp}_thumb_$fileName';
        await _client.storage.from('patient-documents').uploadBinary(
              thumbnailStoragePath,
              thumbnailBytes,
            );
      }

      // 5. Resolve public URLs (storage RLS still gates GETs).
      final String fileUrl = _client.storage
          .from('patient-documents')
          .getPublicUrl(storagePath);
      final String? thumbnailUrl = thumbnailStoragePath == null
          ? null
          : _client.storage
              .from('patient-documents')
              .getPublicUrl(thumbnailStoragePath);

      // 6. Insert the row in public.patient_documents.
      final Map<String, dynamic> docRow = {
        'patient_id': patientId,
        'file_url': fileUrl,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
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
    } on StorageException catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    } on PostgrestException catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    } on AppException catch (e) {
      return Result.failure(e);
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      // Temporary diagnostic — surfaces the actual `Error` type to the
      // Flutter run-time console / Chrome DevTools console. Remove once
      // root cause is confirmed.
      debugPrint('upload-doc throwable: ${e.runtimeType} → $e');
      // Catches `Error` subtypes that would otherwise escape the future
      // (e.g. `UnsupportedError` / `UnimplementedError` from
      // `flutter_image_compress` on web when the platform plugin can't
      // encode). Mapping to `Result.failure` keeps the AsyncNotifier's
      // `await` resolvable so the UI can recover instead of spinning
      // forever.
      return Result.failure(UnknownException(message: e.toString()));
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
            userMessageKey: AppStrings.errorDatabaseRecordNotFound,
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
    } on StorageException catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }
}
