/// Appointment status enum mapping to Supabase `appointment_status` type.
///
/// Values: `'scheduled'` | `'checked_in'` | `'completed'` | `'cancelled'` | `'no_show'` (AGENT_CONTEXT §3).
/// Display labels come from [AppStrings] (Rule 7).
library;

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

/// The workflow status of an appointment.
@JsonEnum(valueField: 'dbValue')
enum AppointmentStatus {
  /// Appointment is scheduled.
  scheduled('scheduled'),

  /// Patient has arrived and checked in.
  checkedIn('checked_in'),

  /// Appointment has been completed by the attending doctor.
  completed('completed'),

  /// Appointment was cancelled.
  cancelled('cancelled'),

  /// Patient did not show up.
  noShow('no_show');

  const AppointmentStatus(this.dbValue);

  /// The raw string stored in the database.
  final String dbValue;

  /// Human-readable display label from [AppStrings].
  String get displayLabel => switch (this) {
    AppointmentStatus.scheduled => AppStrings.scheduled,
    AppointmentStatus.checkedIn => AppStrings.checkedIn,
    AppointmentStatus.completed => AppStrings.completed,
    AppointmentStatus.cancelled => AppStrings.cancelled,
    AppointmentStatus.noShow => AppStrings.noShow,
  };

  /// Text color for UI badges.
  Color get textColor => switch (this) {
    AppointmentStatus.scheduled => AppColors.info,
    AppointmentStatus.checkedIn => AppColors.success,
    AppointmentStatus.completed => AppColors.success,
    AppointmentStatus.cancelled || AppointmentStatus.noShow => AppColors.error,
  };

  /// Background color for UI badges.
  Color get backgroundColor => switch (this) {
    AppointmentStatus.scheduled => AppColors.infoBg,
    AppointmentStatus.checkedIn => AppColors.successBg,
    AppointmentStatus.completed => AppColors.successBg,
    AppointmentStatus.cancelled || AppointmentStatus.noShow => AppColors.errorBg,
  };
}
