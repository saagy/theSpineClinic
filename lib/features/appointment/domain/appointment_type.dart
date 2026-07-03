/// Appointment type enum mapping to Supabase `appointment_type` enum.
///
/// Values: 'normal_pt_session' | 'spinal_traction_session' |
///         'initial_assessment' | 'reassessment'.
/// Display labels come from [AppStrings] (Rule 7).
library;

import 'package:json_annotation/json_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

/// The type of an appointment.
@JsonEnum(valueField: 'dbValue')
enum AppointmentType {
  /// Normal physiotherapy session.
  normalPtSession('normal_pt_session'),

  /// Spinal traction / mechanical traction session.
  spinalTractionSession('spinal_traction_session'),

  /// First-visit assessment by the senior doctor.
  initialAssessment('initial_assessment'),

  /// Follow-up reassessment by the senior doctor.
  reassessment('reassessment');

  const AppointmentType(this.dbValue);

  /// The raw string stored in the database.
  final String dbValue;

  /// Human-readable display label from [AppStrings].
  String get displayLabel => switch (this) {
        AppointmentType.normalPtSession => AppStrings.normalPtSession,
        AppointmentType.spinalTractionSession => AppStrings.spinalTractionSession,
        AppointmentType.initialAssessment => AppStrings.initialAssessment,
        AppointmentType.reassessment => AppStrings.reassessment,
      };

  /// Whether this type ever deducts a patient balance on completion.
  bool get affectsPackageBalance => switch (this) {
        AppointmentType.normalPtSession => true,
        AppointmentType.spinalTractionSession => true,
        AppointmentType.initialAssessment => false,
        AppointmentType.reassessment => false,
      };

}
