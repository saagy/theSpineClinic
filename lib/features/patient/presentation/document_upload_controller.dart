import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'document_upload_state.dart';
import 'patient_documents_providers.dart';

part 'document_upload_controller.g.dart';

/// Retains unfinished bytes within this signed-in session, including after navigation.
@Riverpod(keepAlive: true)
class DocumentUploadController extends _$DocumentUploadController {
  int _generation = 0;
  @override
  DocumentUploadState build(String patientId) {
    ref.watch(currentUserProvider.select((user) => (user.value?.id, user.value?.isActive)));
    _generation++;
    return const DocumentUploadState();
  }

  Future<Result<void>> uploadFiles(List<PlatformFile> files) async {
    if (!state.canPick) {
      return const Result.failure(
        NetworkException(
          code: 'mutation/unconfirmed',
          message: 'Finish the current upload first.',
          userMessageKey: 'mutation_unconfirmed',
        ),
      );
    }
    if (files.isEmpty) return const Result.success(null);
    final error = _permissionError();
    if (error != null) return Result.failure(error);
    state = state.copyWith(
      files: [for (final file in files) DocumentUploadItem(fileName: file.name, bytes: file.bytes)],
    );
    return _run();
  }

  void retainFailures(List<DocumentUploadItem> files) {
    if (_permissionError() != null || files.isEmpty || !state.canPick) return;
    state = state.copyWith(files: List.unmodifiable(files));
  }

  Future<Result<void>> retry() async {
    if (state.isLoading) return const Result.success(null);
    final error = _permissionError();
    if (error != null) return Result.failure(error);
    return _run();
  }

  void removeRejected(int index) {
    if (_permissionError() != null || state.isLoading) return;
    final file = state.files[index];
    // An unknown receipt must be reconciled rather than silently forgotten.
    if (file.status != DocumentUploadStatus.failed || file.isUnconfirmed) return;
    state = state.copyWith(files: [...state.files]..removeAt(index));
  }

  AppException? _permissionError() {
    final user = ref.read(currentUserProvider).value;
    if (user?.isActive == true) return null;
    return const AuthException(
      code: 'auth/unauthorized',
      message: 'An active staff session is required to upload documents.',
      userMessageKey: 'error_auth_generic',
    );
  }

  Future<Result<void>> _run() async {
    final actor = ref.read(currentUserProvider).value?.id;
    final generation = _generation;
    state = state.copyWith(isLoading: true);
    AppException? failure;
    int activeIndex = 0;
    try {
      for (int i = 0; i < state.files.length; i++) {
        activeIndex = i;
        final file = state.files[i];
        if (file.status == DocumentUploadStatus.done) continue;
        _patch(i, file.copyWith(status: DocumentUploadStatus.uploading, clearError: true));
        final bytes = file.bytes;
        final Result<void> result;
        if (bytes == null) {
          result = const Result.failure(
            StorageException(
              code: 'storage/missing-bytes',
              message: 'The original file must be selected again.',
              userMessageKey: 'select_file_again',
            ),
          );
        } else {
          final uploaded = await ref
              .read(patientDocumentsNotifierProvider(patientId).notifier)
              .uploadDocument(fileName: file.fileName, fileBytes: bytes);
          result = uploaded.when(
            success: (_) => const Result.success(null),
            failure: Result.failure,
          );
        }
        if (!ref.mounted ||
            generation != _generation ||
            ref.read(currentUserProvider).value?.id != actor) {
          return result;
        }
        failure ??= result.exceptionOrNull;
        _patch(
          i,
          file.copyWith(
            status: result.isSuccess ? DocumentUploadStatus.done : DocumentUploadStatus.failed,
            error: result.exceptionOrNull,
            clearError: result.isSuccess,
            releaseBytes: result.isSuccess,
          ),
        );
      }
    } catch (_) {
      failure = const NetworkException(
        code: 'mutation/unconfirmed',
        message: 'The upload result is unconfirmed.',
        userMessageKey: 'mutation_unconfirmed',
      );
      if (ref.mounted && generation == _generation) {
        _patch(
          activeIndex,
          state.files[activeIndex].copyWith(status: DocumentUploadStatus.failed, error: failure),
        );
      }
    } finally {
      if (ref.mounted &&
          generation == _generation &&
          ref.read(currentUserProvider).value?.id == actor) {
        state = state.copyWith(isLoading: false);
      }
    }
    return failure == null ? const Result.success(null) : Result.failure(failure);
  }

  void _patch(int index, DocumentUploadItem file) {
    final files = [...state.files];
    files[index] = file;
    state = state.copyWith(files: files);
  }
}
