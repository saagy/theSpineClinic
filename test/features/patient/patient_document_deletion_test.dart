import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import '../../fixtures/deferred_document_repository.dart';
import '../../fixtures/workspace_data.dart';

class _User extends CurrentUser {
  _User({this.active = true});
  final bool active;
  @override
  Future<Staff?> build() async => workspaceStaff('doctor').copyWith(isActive: active);
  void signOut() => state = const AsyncData(null);
}

const _failure = Result<void>.failure(NetworkException(code: 'test/offline', message: 'Offline'));

void main() {
  final provider = patientDocumentsNotifierProvider(workspacePatient.id);
  late DeferredDocumentRepository repo;
  late ProviderContainer container;

  Future<void> start({bool active = true}) async {
    repo = DeferredDocumentRepository();
    container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(() => _User(active: active)),
        patientDocumentsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    await container.read(provider.future);
  }

  List<String> visible() => container.read(provider).requireValue.map((doc) => doc.id).toList();

  test(
    'removes immediately, coalesces duplicate deletes and remains hidden during refresh',
    () async {
      await start();
      final doc = repo.rows.first;
      final notifier = container.read(provider.notifier);
      final first = notifier.deleteDocument(doc);
      final duplicate = notifier.deleteDocument(doc);
      expect(visible(), ['doc-1', 'doc-2']);
      expect(repo.deleteCalls, [doc.id]);
      container.invalidate(provider);
      await container.read(provider.future);
      expect(visible(), ['doc-1', 'doc-2']);
      repo.deletions[doc.id]!.complete(const Result.success(null));
      expect((await first).isSuccess, true);
      expect((await duplicate).isSuccess, true);
      await container.read(provider.future);
      expect(visible(), ['doc-1', 'doc-2']);
    },
  );

  test(
    'failure restores only its document while preserving concurrent rename and delete',
    () async {
      await start();
      final original = [...repo.rows];
      final notifier = container.read(provider.notifier);
      final failed = notifier.deleteDocument(original[0]);
      final successful = notifier.deleteDocument(original[1]);
      await notifier.renameDocument(document: original[2], fileName: 'Renamed scan.pdf');
      await container.read(provider.future);
      expect(visible(), ['doc-2']);
      repo.deletions[original[0].id]!.complete(_failure);
      expect((await failed).isFailure, true);
      await container.read(provider.future);
      expect(visible(), ['doc-0', 'doc-2']);
      expect(container.read(provider).requireValue.last.fileName, 'Renamed scan.pdf');
      repo.deletions[original[1].id]!.complete(const Result.success(null));
      await successful;
      await container.read(provider.future);
      expect(visible(), ['doc-0', 'doc-2']);
    },
  );

  test('a refresh started before deletion cannot resurrect the document afterward', () async {
    await start();
    final snapshot = [...repo.rows];
    final deletion = container.read(provider.notifier).deleteDocument(snapshot.first);
    final stale = Completer<Result<List<PatientDocument>>>();
    repo.nextFetch = stale;
    container.invalidate(provider);
    container.read(provider);
    await container.pump();
    repo.deletions[snapshot.first.id]!.complete(const Result.success(null));
    await deletion;
    await container.read(provider.future);
    stale.complete(Result.success(snapshot));
    await container.pump();
    expect(visible(), ['doc-1', 'doc-2']);
  });

  test('inactive staff cannot change the list or start a delete', () async {
    await start(active: false);
    final result = await container.read(provider.notifier).deleteDocument(repo.rows.first);
    expect(result.isFailure, true);
    expect(visible().length, 3);
    expect(repo.deleteCalls, isEmpty);
  });

  test('an obsolete failed delete cannot repopulate a signed-out session', () async {
    await start();
    final doc = repo.rows.first;
    final deletion = container.read(provider.notifier).deleteDocument(doc);
    repo.rows.clear();
    (container.read(currentUserProvider.notifier) as _User).signOut();
    await container.read(provider.future);
    repo.deletions[doc.id]!.complete(_failure);
    await deletion;
    await container.pump();
    expect(visible(), isEmpty);
  });
}
