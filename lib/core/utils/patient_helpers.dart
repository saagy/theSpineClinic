/// Shared helper for computing a patient's last attended visit date
/// from embedded appointment rows.
///
/// Used by every repository that reads patient records so the computation
/// is always consistent — no reliance on a DB trigger or stale column.
library;

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
      continue; // Malformed timestamp — skip this row
    }
    if (date.isAfter(now)) continue; // Future dates are not a past visit
    if (latest == null || date.isAfter(latest)) {
      latest = date;
    }
  }
  return latest;
}
