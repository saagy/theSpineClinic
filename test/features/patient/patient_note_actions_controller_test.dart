import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/data/patient_notes_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_note_actions_controller.dart';
import '../../fixtures/workspace_overrides.dart';

class _NotesRepository implements PatientNotesRepository {
  final completion = Completer<Result<PatientNote>>();
  int creates = 0;
  @override
  Future<Result<PatientNote>> createNote({
    required String patientId,
    required String noteText,
    required String createdBy,
    String? appointmentId,
  }) {
    creates++;
    return completion.future;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnsupportedError('${invocation.memberName}');
}

void main() {
  test('an unobserved note action survives until the repository completes', () async {
    final repo = _NotesRepository();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(() => WorkspaceUser('doctor')),
        patientNotesRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    final action = container.read(patientNoteActionsControllerProvider.notifier);
    final pending = action.save(patientId: 'patient', text: 'Progress note');
    await container.pump();
    expect(identical(action, container.read(patientNoteActionsControllerProvider.notifier)), isTrue);
    repo.completion.complete(
      Result.success(
        PatientNote(
          id: 'note',
          patientId: 'patient',
          createdBy: 'staff-fixture',
          noteText: 'Progress note',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ),
    );
    expect(await pending, isA<Success<PatientNote>>());
    expect(repo.creates, 1);
  });

  test('missing session refuses the action before calling a repository', () async {
    final repo = _NotesRepository();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithBuild((ref, notifier) async => null),
        patientNotesRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    final result = await container
        .read(patientNoteActionsControllerProvider.notifier)
        .save(patientId: 'patient', text: 'Progress note');
    expect(result, isA<Failure<PatientNote>>());
    expect(repo.creates, 0);
  });
}
