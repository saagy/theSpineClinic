/// Time window during which a doctor retains ad-hoc access to a patient's
/// detail screen purely because they share an attendance record.
///
/// Window: `[scheduled_at - 7 days, scheduled_at + 1 day]` measured against
/// the current instant. Computationally equivalent to
/// `scheduled_at BETWEEN NOW() - postDays AND NOW() + preDays`.
///
/// Rule 7 — no hardcoded durations outside this file.
library;

/// Days of advance access granted before [scheduledAt].
const int kPatientAccessWindowPreDays = 7;

/// Days of trailing access granted after [scheduledAt].
const int kPatientAccessWindowPostDays = 1;

/// Returns true when [scheduledAt] falls inside the access window for an
/// instant (defaults to `DateTime.now()`).
///
/// The comparison is performed in UTC to dodge device-local drift. The DB
/// stores `scheduled_at` as UTC and the matching `is_doctor_in_access_window`
/// SQL helper uses `NOW()` (server time, treated as UTC).
bool isWithinPatientAccessWindow(DateTime scheduledAt, {DateTime? now}) {
  final DateTime scheduledUtc = scheduledAt.toUtc();
  final DateTime nowUtc = (now ?? DateTime.now()).toUtc();
  final DateTime lower = scheduledUtc.subtract(const Duration(days: 7));
  final DateTime upper = scheduledUtc.add(const Duration(days: 1));
  return !nowUtc.isBefore(lower) && !nowUtc.isAfter(upper);
}

/// Lower bound of the access window expressed as an ISO-8601 string.
/// Server-side `is_doctor_in_access_window` mirrors this exactly.
String accessWindowIntervalSql() => "'1 day'";
