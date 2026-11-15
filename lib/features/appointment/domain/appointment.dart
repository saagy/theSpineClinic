/// Freezed domain model for the `public.appointments` table.
///
/// Maps exactly to the schema defined in AGENT_CONTEXT §3.
library;

import 'package:flutter/material.dart' show DateUtils;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

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

    /// FK references `staff(id)` representing the receptionist/admin who booked it.
    @JsonKey(name: 'created_by') String? createdBy,

    /// Row creation timestamp.
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Where the visit happens. Filled from the patient's branch by the
    /// database when a caller sends none.
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ClinicLocation? branch,

    /// When the current status was recorded; null for visits recorded
    /// before this was kept.
    @JsonKey(name: 'status_changed_at', includeToJson: false) DateTime? statusChangedAt,
  }) = _Appointment;

  const Appointment._();

  /// Whether the recorded outcome is past the day it can be freely changed:
  /// both the day it was recorded and the visit's own day are over. After
  /// that only payment staff may change it, with a reason (the database
  /// enforces the same rule).
  bool outcomeLocked({DateTime? now}) {
    if (!status.isOutcome) return false;
    final DateTime today = DateUtils.dateOnly(now ?? DateTime.now());
    final DateTime visitDay = DateUtils.dateOnly(scheduledAt.toLocal());
    final DateTime recordedDay = DateUtils.dateOnly((statusChangedAt ?? scheduledAt).toLocal());
    final DateTime latest = recordedDay.isAfter(visitDay) ? recordedDay : visitDay;
    return latest.isBefore(today);
  }

  /// Deserialises a JSON map (e.g. from a Supabase query) into [Appointment].
  factory Appointment.fromJson(Map<String, dynamic> json) =>
      _$AppointmentFromJson(json);
}
