/// Text for visit outcomes (check-in, no-show, cancel), their history and
/// the reason asked for when an earlier day's outcome is changed.
final class VisitStrings {
  const VisitStrings();

  // Outcomes and actions.
  final String noShow = 'No-show';
  final String markNoShow = 'Mark as no-show';
  final String undoNoShow = 'Undo no-show';
  final String markedNoShow = 'Marked as no-show';
  final String noShowShort = 'No-show';
  final String confirmNoShow =
      'Record that the patient did not come? No session is used. You can undo this today.';
  final String confirmUndoNoShow = 'Put this visit back on the schedule?';
  final String noShowDescription = 'The patient did not come. No session was used.';
  final String cancelShort = 'Cancel Appt.';

  // Changing an earlier day's outcome.
  final String reasonTitle = 'Change an earlier visit';
  final String reasonMessage =
      'This visit was recorded on an earlier day. Say why it is being changed; '
      'the reason is kept in the visit history.';
  final String reasonLabel = 'Reason';
  final String reasonHint = 'For example: checked in on the wrong patient';
  final String reasonRequired = 'Enter a reason.';
  final String saveChange = 'Save change';
  final String keepAsIs = 'Keep as is';
  final String lockedForDesk =
      'Recorded on an earlier day. Ask a head receptionist or the admin to change it.';

  // History.
  final String history = 'History';
  final String historyEmpty = 'No changes recorded for this visit yet.';
  final String historyError = 'The history could not be loaded.';
  final String eventBooked = 'Booked';
  final String eventCheckedIn = 'Checked in';
  final String eventCheckInUndone = 'Check-in undone';
  final String eventCancelled = 'Cancelled';
  final String eventRestored = 'Restored';
  final String eventNoShow = 'Marked as no-show';
  final String eventNoShowUndone = 'No-show undone';
  final String eventDeleted = 'Deleted';
  final String eventChanged = 'Status changed';
  final String unknownStaff = 'System';
  String eventBy(String name, String when) => '$name · $when';
  String eventReason(String reason) => 'Reason: $reason';

  Map<String, String> get errorKeys => {
    'visit_outcome_locked':
        'This visit was recorded on an earlier day. Only a head receptionist or the admin '
        'can change it, and they need to give a reason.',
    'visit_was_attended':
        'This visit was checked in at some point, so it is kept in the records. Cancel it instead.',
    'visit_not_found': 'This visit no longer exists or you cannot change it.',
  };
}
