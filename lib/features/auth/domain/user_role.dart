/// Strongly-typed user role enum mapping to the `user_role` Postgres enum.
///
/// Database values: `'super_admin'`, `'receptionist'`, `'doctor'`.
/// Rule 7 — no hardcoded strings; mapping is centralised here.
library;

import 'package:json_annotation/json_annotation.dart';

/// The three staff role tiers enforced by the Supabase RLS policies.
///
/// Serialisation uses the [dbValue] field so that `json_serializable`
/// reads / writes the exact snake_case string stored in Postgres.
@JsonEnum(valueField: 'dbValue')
enum UserRole {
  /// Full system access — manages staff, settings, and reports.
  superAdmin('super_admin'),

  /// Front-desk operations — patients, appointments, payments.
  receptionist('receptionist'),

  /// Clinical operations — schedule, notes, own replacements.
  doctor('doctor');

  const UserRole(this.dbValue);

  /// The snake_case string stored in the Postgres `user_role` column.
  final String dbValue;
}
