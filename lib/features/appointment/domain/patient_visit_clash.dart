import 'appointment.dart';
import 'appointment_status.dart';

/// A requested visit that falls on a day when the patient already has one.
class PatientVisitClash {
  const PatientVisitClash({required this.requested, required this.existing});

  /// The new visit's start, in local time.
  final DateTime requested;

  /// The patient's visit already on that day.
  final Appointment existing;

  /// True when both start at the same minute: almost certainly a duplicate.
  bool get sameTime {
    final DateTime other = existing.scheduledAt.toLocal();
    return _sameDay(other, requested) &&
        other.hour == requested.hour &&
        other.minute == requested.minute;
  }
}

/// One clash per requested start that shares a day with an uncancelled visit
/// in [existing], preferring a visit at the very same time. [ignoreId] skips
/// the appointment being edited. Never blocks: callers only warn.
List<PatientVisitClash> findPatientVisitClashes({
  required List<DateTime> requested,
  required List<Appointment> existing,
  String? ignoreId,
}) {
  final List<Appointment> live = [
    for (final Appointment visit in existing)
      if (visit.status != AppointmentStatus.cancelled &&
          visit.status != AppointmentStatus.noShow &&
          visit.id != ignoreId)
        visit,
  ];
  final List<PatientVisitClash> clashes = [];
  for (final DateTime start in requested) {
    final List<PatientVisitClash> sameDay = [
      for (final Appointment visit in live)
        if (_sameDay(visit.scheduledAt.toLocal(), start))
          PatientVisitClash(requested: start, existing: visit),
    ];
    if (sameDay.isEmpty) continue;
    clashes.add(
      sameDay.firstWhere((clash) => clash.sameTime, orElse: () => sameDay.first),
    );
  }
  return clashes;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
