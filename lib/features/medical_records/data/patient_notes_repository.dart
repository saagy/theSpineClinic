/// Repository and implementation managing patient notes.
///
/// Wraps Supabase PostgREST queries in [Result] to satisfy Rule 4.
/// Rule 2 — data isolation: all Supabase operations in repo.
library;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';

/// Repository interface defining clinical note operations.
abstract class PatientNotesRepository {
  /// Fetches notes for a specific patient, ordered by created_at DESC.
  Future<Result<List<PatientNote>>> getNotesForPatient(String patientId);

  /// Inserts a new note.
  Future<Result<PatientNote>> createNote({
    required String patientId,
    required String noteText,
    required String createdBy,
    String? appointmentId,
  });

  /// Fetches a note associated with a specific appointment.
  Future<Result<PatientNote?>> getNoteByAppointmentId(String appointmentId);

  /// Updates an existing note.
  Future<Result<PatientNote>> updateNote({
    required String noteId,
    required String noteText,
  });

  /// Deletes a note by its ID.
  Future<Result<void>> deleteNote(String noteId);
}

/// Supabase-backed implementation of [PatientNotesRepository].
class PatientNotesRepositoryImpl implements PatientNotesRepository {
  /// Creates a [PatientNotesRepositoryImpl].
  PatientNotesRepositoryImpl({required SupabaseService supabaseService})
      : _service = supabaseService;

  final SupabaseService _service;

  @override
  Future<Result<List<PatientNote>>> getNotesForPatient(String patientId) async {
    try {
      final List<Map<String, dynamic>> rows =
          await _service.getPatientNotes(patientId);
      final List<PatientNote> notes = rows.map(PatientNote.fromJson).toList();
      return Result.success(notes);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<PatientNote>> createNote({
    required String patientId,
    required String noteText,
    required String createdBy,
    String? appointmentId,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'patient_id': patientId,
        'note_text': noteText,
        'created_by': createdBy,
        if (appointmentId != null) 'appointment_id': appointmentId,
      };

      final Map<String, dynamic> row = await _service.insertPatientNote(data);
      final PatientNote createdNote = PatientNote.fromJson(row);
      return Result.success(createdNote);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<PatientNote?>> getNoteByAppointmentId(
    String appointmentId,
  ) async {
    try {
      final Map<String, dynamic>? row =
          await _service.getNoteByAppointmentId(appointmentId);
      if (row == null) {
        return const Result.success(null);
      }
      final PatientNote note = PatientNote.fromJson(row);
      return Result.success(note);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<PatientNote>> updateNote({
    required String noteId,
    required String noteText,
  }) async {
    try {
      final Map<String, dynamic> row = await _service.guardQuery(
        () => _service
            .from('patient_notes')
            .update({'note_text': noteText})
            .eq('id', noteId)
            .select()
            .single(),
      );
      final PatientNote note = PatientNote.fromJson(row);
      return Result.success(note);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<void>> deleteNote(String noteId) async {
    try {
      await _service.guardQuery(
        () => _service.from('patient_notes').delete().eq('id', noteId),
      );
      return const Result.success(null);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }
}
