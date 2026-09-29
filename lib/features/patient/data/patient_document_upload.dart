import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/pending_mutation.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'patient_document_cache.dart';

/// Upload state is stored on the server before any R2 write is authorized.
class PatientDocumentUpload {
  PatientDocumentUpload(this.service, this.cache);
  final SupabaseService service;
  final PatientDocumentCache cache;
  static final Set<String> _inFlight = {};

  Future<Result<PatientDocument>> upload({
    required String patientId,
    required String fileName,
    required Uint8List fileBytes,
    required String uploadedBy,
    String? programId,
    String? requestId,
  }) async {
    if (fileBytes.isEmpty || fileBytes.length > 10 * 1024 * 1024) {
      return const Result.failure(
        StorageException(
          code: 'storage/file-too-large',
          message: 'File must be 1 byte to 10 MB.',
          userMessageKey: 'error_doc_file_too_large',
        ),
      );
    }
    final String? actor = service.currentUserId;
    if (actor == null) return const Result.failure(unresolvedMutation);
    final Map<String, dynamic> metadata = {
      'patientId': patientId,
      'fileName': fileName,
      'programId': programId,
      'contentHash': sha256.convert(fileBytes).toString(),
      'byteSize': fileBytes.length,
    };
    final String scope = 'upload:${PendingMutation.digest(metadata)}';
    final String lock = '$actor:$scope';
    if (!_inFlight.add(lock)) return const Result.failure(unresolvedMutation);
    try {
      final pending = requestId != null
          ? null
          : await PendingMutation.open(
              actor: actor,
              scope: scope,
              payload: metadata,
            );
      final Map<String, dynamic> body = {
        ...metadata,
        'requestId': requestId ?? pending!.id,
      };
      Map<String, dynamic> response = await _request('start-upload', body);
      if (response['uploadUrl'] != null) {
        await _put(response, fileBytes);
        response = await _request('finish-upload', body);
      }
      if (response['ok'] != true) {
        // Only a persisted failed receipt permits cleanup and a new operation.
        if (response['ok'] == false) {
          await pending?.clear();
          return const Result.failure(
            StorageException(
              code: 'storage/upload-rejected',
              message: 'The upload receipt records a definitive rejection.',
              userMessageKey: 'error_unknown',
            ),
          );
        }
        return const Result.failure(unresolvedMutation);
      }
      final document = PatientDocument.fromJson(
        response['document'] as Map<String, dynamic>,
      );
      await pending?.clear();
      cache.put(document.fileUrl, fileBytes);
      return Result.success(document);
    } on Exception {
      // Leave both the local identity and server receipt for reconciliation.
      return const Result.failure(unresolvedMutation);
    } finally {
      _inFlight.remove(lock);
    }
  }

  Future<Map<String, dynamic>> _request(
    String action,
    Map<String, dynamic> body,
  ) async {
    final response = await service.invokeFunction(
      'document-storage',
      body: {...body, 'action': action},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> _put(Map<String, dynamic> response, Uint8List bytes) async {
    final client = http.Client();
    final abort = Completer<void>();
    try {
      final request =
          http.AbortableRequest(
              'PUT',
              Uri.parse(response['uploadUrl'] as String),
              abortTrigger: abort.future,
            )
            ..headers['Content-Type'] = response['contentType'] as String
            ..bodyBytes = bytes;
      final http.Response result = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 45));
      if (result.statusCode < 200 || result.statusCode >= 300) {
        throw unresolvedMutation;
      }
    } finally {
      abort.complete();
      client.close();
    }
  }
}
