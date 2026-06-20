/// Freezed domain model for the `public.patient_documents` table.
///
/// Maps exactly to the schema defined in AGENT_CONTEXT §3.
/// Rule 4 — repositories wrap this in `Result<T>`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'patient_document.freezed.dart';
part 'patient_document.g.dart';

/// Represents a single uploaded patient document.
@freezed
abstract class PatientDocument with _$PatientDocument {
  /// Creates a [PatientDocument] instance.
  const factory PatientDocument({
    /// Primary key (`uuid`).
    required String id,

    /// FK referencing patients(id).
    @JsonKey(name: 'patient_id') required String patientId,

    /// Publicly accessible Supabase Storage URL.
    @JsonKey(name: 'file_url') required String fileUrl,

    /// Optional 320×320 thumbnail JPEG URL, populated when the
    /// uploaded document is an image. `null` for PDFs and for legacy
    /// rows that pre-date the thumbnail column migration.
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,

    /// Raw name of the file (e.g. 'xray.pdf').
    @JsonKey(name: 'file_name') required String fileName,

    /// FK referencing staff(id) who uploaded it — nullable.
    @JsonKey(name: 'uploaded_by') String? uploadedBy,

    /// Row creation/upload timestamp.
    @JsonKey(name: 'uploaded_at') required DateTime uploadedAt,
  }) = _PatientDocument;

  /// Deserialises a JSON map (e.g. from a Supabase query) into [PatientDocument].
  factory PatientDocument.fromJson(Map<String, dynamic> json) =>
      _$PatientDocumentFromJson(json);
}
