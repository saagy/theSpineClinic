/// Freezed model for the `public.patients` table.
///
/// Maps 1:1 to the Supabase schema (AGENT_CONTEXT §3).
/// Rule 4 — repositories wrap this in `Result<T>`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

part 'patient.freezed.dart';
part 'patient.g.dart';

/// A patient record in the Spine Clinic system.
@freezed
abstract class Patient with _$Patient {
  /// Creates a [Patient].
  const factory Patient({
    required String id,
    @JsonKey(name: 'full_name') required String fullName,
    @JsonKey(name: 'phone_number') required String phoneNumber,
    String? program,
    required ClinicLocation clinic,
    @JsonKey(name: 'session_balance') @Default(0) int sessionBalance,
    @JsonKey(name: 'traction_balance') @Default(0) int tractionBalance,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(includeFromJson: false, includeToJson: false) DateTime? lastAppointmentDate,
  }) = _Patient;

  /// Deserialises from a Supabase JSON row.
  factory Patient.fromJson(Map<String, dynamic> json) =>
      _$PatientFromJson(json);
}
