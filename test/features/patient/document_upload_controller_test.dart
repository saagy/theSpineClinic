import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/document_upload_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/document_upload_state.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import '../../fixtures/workspace_data.dart';
import '../../fixtures/workspace_document_repository.dart';

class _User extends CurrentUser {
  @override
  Future<Staff?> build() async => workspaceStaff('doctor');
  void signOut() => state = const AsyncData(null);
}

class _Documents extends WorkspaceDocumentRepository {
  final List<String> uploaded = [];
  bool fail = true;
  Completer<void>? gate;
  @override
  Future<Result<List<PatientDocument>>> fetchDocuments(String patientId) async =>
      const Result.success([]);
  @override
  Future<Result<PatientDocument>> uploadDocument({
    required String patientId,
    required String fileName,
    required Uint8List fileBytes,
    required String uploadedBy,
    String? programId,
  }) async {
    uploaded.add(fileName);
    await gate?.future;
    if (fail && fileName == 'second.pdf') {
      return const Result.failure(
        NetworkException(
          code: 'mutation/unconfirmed',
          message: 'Lost response',
          userMessageKey: 'mutation_unconfirmed',
        ),
      );
    }
    return Result.success(
      PatientDocument(
        id: fileName,
        patientId: patientId,
        fileName: fileName,
        fileUrl: '$patientId/$fileName',
        uploadedAt: DateTime(2026),
      ),
    );
  }
}

PlatformFile _file(String name) =>
    PlatformFile(name: name, size: 1, bytes: Uint8List.fromList([1]));

void main() {
  test('keeps uncertain files and retries only unfinished uploads', () async {
    final repo = _Documents();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(_User.new),
        patientDocumentsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    final provider = documentUploadControllerProvider('patient');
    final controller = container.read(provider.notifier);
    final result = await controller.uploadFiles([_file('first.pdf'), _file('second.pdf')]);
    expect(result.isFailure, true);
    expect(container.read(provider).completed, 1);
    expect(container.read(provider).files.first.bytes, isNull);
    expect(container.read(provider).files.last.bytes, isNotNull);
    controller.removeRejected(1);
    expect(container.read(provider).files.length, 2);
    repo.fail = false;
    expect((await controller.retry()).isSuccess, true);
    expect(repo.uploaded, ['first.pdf', 'second.pdf', 'second.pdf']);
    expect(container.read(provider).hasFailures, false);
    expect(container.read(provider).files.every((file) => file.bytes == null), true);
  });

  test('unobserved uploads survive, duplicate starts are rejected', () async {
    final repo = _Documents()..gate = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(_User.new),
        patientDocumentsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    final provider = documentUploadControllerProvider('patient');
    final controller = container.read(provider.notifier);
    final saving = controller.uploadFiles([_file('first.pdf')]);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(provider).isLoading, true);
    expect(container.read(provider).active?.fileName, 'first.pdf');
    expect((await controller.uploadFiles([_file('extra.pdf')])).isFailure, true);
    repo.gate!.complete();
    await saving;
    expect(container.read(provider).files.single.status, DocumentUploadStatus.done);
    expect(repo.uploaded, ['first.pdf']);
  });

  test('signing out clears bytes and ignores old upload completion', () async {
    final repo = _Documents()..gate = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(_User.new),
        patientDocumentsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    final provider = documentUploadControllerProvider('patient');
    final saving = container.read(provider.notifier).uploadFiles([_file('first.pdf')]);
    await Future<void>.delayed(Duration.zero);
    (container.read(currentUserProvider.notifier) as _User).signOut();
    expect(container.read(provider).files, isEmpty);
    repo.gate!.complete();
    await saving;
    expect(container.read(provider).files, isEmpty);
    expect(container.read(provider).isLoading, false);
  });
}
