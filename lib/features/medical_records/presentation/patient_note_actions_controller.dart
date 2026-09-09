import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_notes_list_notifier.dart';

part 'patient_note_actions_controller.g.dart';

/// Patient-scoped note mutations survive closing the editor or changing tabs.
@Riverpod(keepAlive: true)
class PatientNoteActionsController extends _$PatientNoteActionsController {
  @override
  void build() {}

  static const denied = AuthException(
    code: 'auth/unauthorized',
    message: 'Active staff required.',
    userMessageKey: 'error_database_permission_denied',
  );

  Future<Result<PatientNote>> save({
    required String patientId,
    required String text,
    PatientNote? existing,
  }) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || !user.isActive) return const Result.failure(denied);
    final repo = ref.read(patientNotesRepositoryProvider);
    final result = existing == null
        ? await repo.createNote(patientId: patientId, noteText: text, createdBy: user.id)
        : await repo.updateNote(noteId: existing.id, noteText: text);
    if (result is Success<PatientNote>) _refresh(patientId, existing?.appointmentId);
    return result;
  }

  Future<Result<void>> delete(PatientNote note) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || !user.isActive) return const Result.failure(denied);
    final result = await ref.read(patientNotesRepositoryProvider).deleteNote(note.id);
    if (result is Success<void>) _refresh(note.patientId, note.appointmentId);
    return result;
  }

  void _refresh(String patientId, String? appointmentId) {
    ref.invalidate(patientNotesNotifierProvider(patientId));
    ref.invalidate(patientNotesListProvider(patientId));
    if (appointmentId != null) ref.invalidate(appointmentNoteProvider(appointmentId));
  }
}
