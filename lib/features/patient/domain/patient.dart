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
    required ClinicLocation clinic,
    @JsonKey(name: 'file_number') int? fileNumber,
    @JsonKey(name: 'personal_details')
    @Default(PatientPersonalDetails())
    PatientPersonalDetails personalDetails,
    @JsonKey(name: 'session_balance') @Default(0) int sessionBalance,
    @JsonKey(name: 'traction_balance') @Default(0) int tractionBalance,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'next_visit_date') DateTime? nextVisitDate,
    @JsonKey(includeFromJson: false, includeToJson: false)
    DateTime? lastAppointmentDate,
  }) = _Patient;

  /// Deserialises from a Supabase JSON row.
  factory Patient.fromJson(Map<String, dynamic> json) =>
      _$PatientFromJson(json);
}

enum PatientGender { female, male }

@freezed
abstract class PatientPersonalDetails with _$PatientPersonalDetails {
  const factory PatientPersonalDetails({
    String? address,
    @JsonKey(name: 'date_of_birth', toJson: _dateOnly) DateTime? dateOfBirth,
    String? nationality,
    PatientGender? gender,
    @JsonKey(name: 'secondary_phone') String? secondaryPhone,
    @JsonKey(name: 'insurance_company') String? insuranceCompany,
    @JsonKey(name: 'insurance_member_number') String? insuranceMemberNumber,
    @JsonKey(name: 'insurance_expiry', toJson: _dateOnly)
    DateTime? insuranceExpiry,
    @JsonKey(name: 'referral_source') String? referralSource,
  }) = _PatientPersonalDetails;

  factory PatientPersonalDetails.fromJson(Map<String, dynamic> json) =>
      _$PatientPersonalDetailsFromJson(json);
}

String? _dateOnly(DateTime? date) => date?.toIso8601String().split('T').first;
