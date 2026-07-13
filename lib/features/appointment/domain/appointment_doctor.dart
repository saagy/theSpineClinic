/// Freezed domain model for the `public.appointment_doctors` table.
///
/// Maps exactly to the schema defined in AGENT_CONTEXT §3.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'appointment_doctor.freezed.dart';
part 'appointment_doctor.g.dart';

/// Junction record linking an appointment to a doctor.
@freezed
abstract class AppointmentDoctor with _$AppointmentDoctor {
  /// Creates an [AppointmentDoctor] instance.
  const factory AppointmentDoctor({
    /// Primary key (`uuid`).
    required String id,

    /// FK references `appointments(id)`.
    @JsonKey(name: 'appointment_id') required String appointmentId,

    /// FK references `staff(id)` (role must be doctor).
    @JsonKey(name: 'doctor_id') required String doctorId,

    /// Whether this assignment is currently active.
    ///
    /// Removed doctors are kept but marked as inactive (`false`).
    @JsonKey(name: 'is_active') @Default(true) bool isActive,

    /// FK references `staff(id)` representing the person who added this doctor assignment.
    @JsonKey(name: 'added_by') String? addedBy,

    /// Row creation timestamp.
    @JsonKey(name: 'added_at') required DateTime addedAt,
  }) = _AppointmentDoctor;

  /// Deserialises a JSON map (e.g. from a Supabase query) into [AppointmentDoctor].
  factory AppointmentDoctor.fromJson(Map<String, dynamic> json) =>
      _$AppointmentDoctorFromJson(json);
}
