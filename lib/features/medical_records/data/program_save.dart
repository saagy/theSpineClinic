import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:uuid/uuid.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/pending_mutation.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/patient/data/patient_document_cache.dart';
import 'package:spine_clinic_app/features/patient/data/patient_document_upload.dart';

/// Keeps one identity until the program and every attachment are confirmed.
class ProgramSave {
  ProgramSave(this.service);
  final SupabaseService service;
  static final Set<String> _inFlight = {};

  Future<Result<PatientProgram>> save(
    Map<String, dynamic> fields,
    List<ProgramAttachment> attachments,
  ) async {
    final actor = service.currentUserId;
    if (actor == null) return const Result.failure(unresolvedMutation);
    final scope = fields['p_program_id'] == null
        ? 'program_create:${fields['p_patient_id']}'
        : 'program_update:${fields['p_program_id']}';
    final lock = '$actor:$scope';
    if (!_inFlight.add(lock)) return const Result.failure(unresolvedMutation);
    bool saved = false;
    try {
      for (final attachment in attachments) {
        if (attachment.bytes.isEmpty ||
            attachment.bytes.length > 10 * 1024 * 1024) {
          throw const StorageException(
            code: 'storage/file-too-large',
            message: 'File must be 1 byte to 10 MB.',
            userMessageKey: 'error_doc_file_too_large',
          );
        }
        if (attachment.fileName.length > 255 ||
            !{
              'pdf',
              'jpg',
              'jpeg',
              'png',
              'webp',
              'txt',
            }.contains(attachment.fileName.split('.').last.toLowerCase())) {
          throw const StorageException(
            code: 'storage/unsupported-file',
            message: 'Unsupported attachment type.',
            userMessageKey: 'error_doc_unsupported_type',
          );
        }
      }
      final payload = <String, dynamic>{
        ...fields,
        'attachments': [
          for (final file in attachments)
            {
              'name': file.fileName,
              'hash': sha256.convert(file.bytes).toString(),
              'size': file.bytes.length,
            },
        ],
      };
      final pending = await PendingMutation.open(
        actor: actor,
        scope: scope,
        payload: payload,
        resolveChanged: (id) => service.rpc<bool>(
          'resolve_clinic_mutation',
          params: {'p_request_id': id},
        ),
      );
      final Map<String, dynamic> outcome;
      try {
        outcome = await service.rpc<Map<String, dynamic>>(
          'save_program_mutation',
          params: {'p_request_id': pending.id, 'p_payload': payload},
        );
      } on Exception {
        throw unresolvedMutation;
      }
      if (outcome['ok'] != true) {
        if (outcome['ok'] == false) await pending.clear();
        throw AppException.fromSupabaseException(
          PostgrestException(
            code: outcome['code'] as String?,
            message:
                outcome['message'] as String? ?? 'Program save unconfirmed',
          ),
        );
      }
      saved = true;
      final program = PatientProgram.fromJson(
        outcome['program'] as Map<String, dynamic>,
      );
      final upload = PatientDocumentUpload(
        service,
        PatientDocumentCache(maxEntries: 0),
      );
      for (int i = 0; i < attachments.length; i++) {
        final file = attachments[i];
        final result = await upload.upload(
          patientId: program.patientId,
          programId: program.id,
          fileName: file.fileName,
          fileBytes: file.bytes,
          uploadedBy: program.createdBy,
          requestId: const Uuid().v5(pending.id, 'attachment:$i'),
        );
        if (result.exceptionOrNull?.code == 'storage/upload-rejected') {
          throw const StorageException(
            code: 'program/attachments-pending',
            message: 'Program saved; an attachment was definitively rejected.',
            userMessageKey: 'program_attachments_rejected',
          );
        }
        if (result.isFailure) throw programAttachmentsPending;
      }
      await pending.clear();
      return Result.success(program);
    } catch (error) {
      return Result.failure(
        error is AppException && error.code == 'program/attachments-pending'
            ? error
            : saved
            ? programAttachmentsPending
            : error is AppException
            ? error
            : AppException.fromSupabaseException(error),
      );
    } finally {
      _inFlight.remove(lock);
    }
  }
}

const programAttachmentsPending = NetworkException(
  code: 'program/attachments-pending',
  message: 'Program saved; attachment result unconfirmed.',
  userMessageKey: 'program_attachments_pending',
);
