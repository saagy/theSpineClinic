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
import 'package:spine_clinic_app/features/medical_records/presentation/patient_notes_list_notifier.dart';

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

/// Manages the note linked to a specific appointment.
@riverpod
class AppointmentNote extends _$AppointmentNote {
  @override
  FutureOr<PatientNote?> build(String appointmentId) async {
    final PatientNotesRepository repo = ref.watch(patientNotesRepositoryProvider);
    final Result<PatientNote?> result =
        await repo.getNoteByAppointmentId(appointmentId);
    return result.when(
      success: (PatientNote? data) => data,
      failure: (AppException exception) => throw exception,
    );
  }

  /// Saves or updates the note for this appointment.
  Future<void> saveNote({
    required String noteText,
    required String patientId,
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

    final Result<PatientNote?> existingResult =
        await repo.getNoteByAppointmentId(appointmentId);
    if (!ref.mounted) return;

    final PatientNote? existingNote = await existingResult.when(
      success: (PatientNote? note) => note,
      failure: (AppException exception) {
        state = AsyncValue.error(exception, StackTrace.current);
        throw exception;
      },
    );

    Result<PatientNote> result;
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
    if (!ref.mounted) return;

    await result.when(
      success: (PatientNote newNote) async {
        state = AsyncValue.data(newNote);
        // Invalidate the patient notes notifier since the list has changed
        ref.invalidate(patientNotesNotifierProvider(patientId));
        ref.invalidate(patientNotesListProvider(patientId));
      },
      failure: (AppException exception) {
        state = AsyncValue.error(exception, StackTrace.current);
        throw exception;
      },
    );
  }
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
      if (!ref.mounted) return;

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
    if (!ref.mounted) return;

    await result.when(
      success: (PatientNote newNote) async {
        if (appointmentId != null) {
          ref.invalidate(appointmentNoteProvider(appointmentId));
        }
        ref.invalidate(patientNotesListProvider(patientId));
        final Result<List<PatientNote>> notesResult = await repo.getNotesForPatient(patientId);
        if (!ref.mounted) return;
        state = notesResult.when(
          success: (notes) => AsyncValue.data(notes),
          failure: (error) => AsyncValue.error(error, StackTrace.current),
        );
      },
      failure: (AppException exception) {
        state = AsyncValue.error(exception, StackTrace.current);
        throw exception;
      },
    );
  }

  /// Updates an existing patient note.
  Future<void> updateExistingNote({
    required String noteId,
    required String noteText,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(patientNotesRepositoryProvider);
    final result = await repo.updateNote(noteId: noteId, noteText: noteText);
    if (!ref.mounted) return;

    await result.when(
      success: (PatientNote updatedNote) async {
        if (updatedNote.appointmentId != null) {
          ref.invalidate(appointmentNoteProvider(updatedNote.appointmentId!));
        }
        ref.invalidate(patientNotesListProvider(patientId));
        final Result<List<PatientNote>> notesResult = await repo.getNotesForPatient(patientId);
        if (!ref.mounted) return;
        state = notesResult.when(
          success: (notes) => AsyncValue.data(notes),
          failure: (error) => AsyncValue.error(error, StackTrace.current),
        );
      },
      failure: (AppException exception) {
        state = AsyncValue.error(exception, StackTrace.current);
        throw exception;
      },
    );
  }
}
