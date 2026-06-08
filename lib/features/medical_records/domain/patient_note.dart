/// Freezed domain model for the `public.patient_notes` table.
///
/// Maps exactly to the schema defined in AGENT_CONTEXT §3.
/// Rule 4 — repositories wrap this in `Result<T>`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'patient_note.freezed.dart';
part 'patient_note.g.dart';

/// Represents a single clinical or visit note for a patient.
@freezed
abstract class PatientNote with _$PatientNote {
  /// Creates a [PatientNote] instance.
  const factory PatientNote({
    /// Primary key (`uuid`).
    required String id,

    /// FK referencing patients(id).
    @JsonKey(name: 'patient_id') required String patientId,

    /// FK referencing appointments(id) — nullable.
    @JsonKey(name: 'appointment_id') String? appointmentId,

    /// FK referencing staff(id) who created the note.
    @JsonKey(name: 'created_by') required String createdBy,

    /// The actual text content of the note.
    @JsonKey(name: 'note_text') required String noteText,

    /// Note creation timestamp.
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Note update timestamp.
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _PatientNote;

  /// Deserialises a JSON map (e.g. from a Supabase query) into [PatientNote].
  factory PatientNote.fromJson(Map<String, dynamic> json) =>
      _$PatientNoteFromJson(json);
}
