/// Freezed domain model for the `public.appointments` table.
///
/// Maps exactly to the schema defined in AGENT_CONTEXT §3.
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';

part 'appointment.freezed.dart';
part 'appointment.g.dart';

/// Represents a single appointment record.
@freezed
abstract class Appointment with _$Appointment {
  /// Creates an [Appointment] instance.
  const factory Appointment({
    /// Primary key (`uuid`).
    required String id,

    /// FK references `patients(id)`.
    @JsonKey(name: 'patient_id') required String patientId,

    /// Type of the appointment (session or traction device).
    required AppointmentType type,

    /// Time the appointment is scheduled for.
    @JsonKey(name: 'scheduled_at') required DateTime scheduledAt,

    /// Workflow status of the appointment.
    @Default(AppointmentStatus.scheduled) AppointmentStatus status,

    /// Whether this appointment uses/deducts from the patient's package balance.
    @JsonKey(name: 'use_package') @Default(true) bool usePackage,

    /// Optional notes added by receptionist or doctor.
    String? notes,

    /// FK references `staff(id)` representing the receptionist/admin who booked it.
    @JsonKey(name: 'created_by') String? createdBy,

    /// Row creation timestamp.
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Appointment;

  /// Deserialises a JSON map (e.g. from a Supabase query) into [Appointment].
  factory Appointment.fromJson(Map<String, dynamic> json) =>
      _$AppointmentFromJson(json);
}
