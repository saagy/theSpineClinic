/// Riverpod providers for the medical records (notes) feature.
///
/// Exposes:
/// - [patientNotesRepositoryProvider] — repository access.
/// - [patientNotesProvider] — family future provider for list of notes.
/// - [appointmentNoteProvider] — family future provider for appointment-linked note.
/// - [PatientNotesNotifier] — family AsyncNotifier managing notes list state.
///
/// Rule 3 — all state via Riverpod.
/// Rule 5 — read role/id from currentUserProvider.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/data/patient_notes_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';

part 'medical_records_providers.g.dart';

/// Provides a singleton instance of [PatientNotesRepository].
@Riverpod(keepAlive: true)
PatientNotesRepository patientNotesRepository(Ref ref) {
  return PatientNotesRepositoryImpl(
    supabaseService: SupabaseService.instance,
  );
}

/// Fetches all notes associated with a specific patient.
@riverpod
FutureOr<List<PatientNote>> patientNotes(Ref ref, String patientId) async {
  final PatientNotesRepository repo = ref.watch(patientNotesRepositoryProvider);
  final Result<List<PatientNote>> result =
      await repo.getNotesForPatient(patientId);
  return result.when(
    success: (List<PatientNote> data) => data,
    failure: (AppException exception) => throw exception,
  );
}

/// Fetches the note linked to a specific appointment.
@riverpod
FutureOr<PatientNote?> appointmentNote(Ref ref, String appointmentId) async {
  final PatientNotesRepository repo = ref.watch(patientNotesRepositoryProvider);
  final Result<PatientNote?> result =
      await repo.getNoteByAppointmentId(appointmentId);
  return result.when(
    success: (PatientNote? data) => data,
    failure: (AppException exception) => throw exception,
  );
}

/// Family notifier managing the patient notes list state.
@riverpod
class PatientNotesNotifierNotifier extends _$PatientNotesNotifierNotifier {
  @override
  FutureOr<List<PatientNote>> build(String patientId) async {
    final PatientNotesRepository repo =
        ref.watch(patientNotesRepositoryProvider);
    final Result<List<PatientNote>> result =
        await repo.getNotesForPatient(patientId);
    return result.when(
      success: (List<PatientNote> data) => data,
      failure: (AppException exception) => throw exception,
    );
  }

  /// Inserts or updates a note for the current patient/appointment.
  Future<void> addNote({
    required String noteText,
    String? appointmentId,
  }) async {
    state = const AsyncValue.loading();

    // Rule 6: Every write action must read currentUserProvider to fetch staff ID
    final Staff? currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      final AuthException exception = const AuthException(
        code: 'auth/unauthorized',
        message: 'User must be authenticated to add notes.',
        userMessageKey: 'error_auth_generic',
      );
      state = AsyncValue.error(exception, StackTrace.current);
      throw exception;
    }

    final PatientNotesRepository repo = ref.read(patientNotesRepositoryProvider);

    Result<PatientNote> result;
    if (appointmentId != null) {
      final Result<PatientNote?> existingResult =
          await repo.getNoteByAppointmentId(appointmentId);

      final PatientNote? existingNote = await existingResult.when(
        success: (PatientNote? note) => note,
        failure: (AppException exception) {
          state = AsyncValue.error(exception, StackTrace.current);
          throw exception;
        },
      );

      if (existingNote != null) {
        result = await repo.updateNote(
          noteId: existingNote.id,
          noteText: noteText,
        );
      } else {
        result = await repo.createNote(
          patientId: patientId,
          noteText: noteText,
          createdBy: currentUser.id,
          appointmentId: appointmentId,
        );
      }
    } else {
      result = await repo.createNote(
        patientId: patientId,
        noteText: noteText,
        createdBy: currentUser.id,
        appointmentId: appointmentId,
      );
    }

    await result.when(
      success: (PatientNote newNote) async {
        if (appointmentId != null) {
          ref.invalidate(appointmentNoteProvider(appointmentId));
        }
        ref.invalidateSelf();
      },
      failure: (AppException exception) {
        state = AsyncValue.error(exception, StackTrace.current);
        throw exception;
      },
    );
  }
}
