/// Shared helpers for computing a patient's last attended visit date
/// from embedded appointment rows, and for parsing patient rows with
/// embedded appointments into a [Patient] model.
///
/// Used by every repository that reads patient records so the computation
/// is always consistent — no reliance on a DB trigger or stale column.
library;

import 'package:spine_clinic_app/features/patient/domain/patient.dart';

/// Returns the latest [scheduled_at] among [appointmentRows] whose
/// [status] is `checked_in` or `completed`, or `null` if none qualify.
///
/// Dates in the future are silently ignored — a checked-in session
/// scheduled for tomorrow cannot be a "last visit" that already happened.
///
/// Each row is expected to have at least:
/// - `scheduled_at`: ISO‑8601 timestamp string
/// - `status`: one of the `appointment_status` enum values
DateTime? computeLastAppointmentDate(List<Map<String, dynamic>> appointmentRows) {
  final DateTime now = DateTime.now();
  DateTime? latest;
  for (final row in appointmentRows) {
    final String? status = row['status'] as String?;
    if (status != 'checked_in' && status != 'completed') continue;
    final String? scheduledAt = row['scheduled_at'] as String?;
    if (scheduledAt == null) continue;
    final DateTime date;
    try {
      date = DateTime.parse(scheduledAt);
    } on FormatException {
      continue;
    }
    if (date.isAfter(now)) continue;
    if (latest == null || date.isAfter(latest)) {
      latest = date;
    }
  }
  return latest;
}

/// Builds a [Patient] from a row that includes embedded appointments.
///
/// The DB's `last_appointment_date` column is **always** replaced by the
/// result of [computeLastAppointmentDate] so every screen shares one
/// consistent derivation. If the embedded `appointments` key is absent
/// the raw Patient from JSON is returned unchanged.
Patient parsePatientRowWithLastAppt(Map<String, dynamic> row) {
  final dynamic appts = row['appointments'];
  final Patient patient = Patient.fromJson(row);

  if (appts is! List) return patient;

  final List<Map<String, dynamic>> apptRows = appts
      .whereType<Map<String, dynamic>>()
      .toList();
  final DateTime? computed = computeLastAppointmentDate(apptRows);
  return patient.copyWith(lastAppointmentDate: computed);
}
