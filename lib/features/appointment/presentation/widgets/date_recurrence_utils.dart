library;

/// Helper utility for generating recurring appointment slots.
abstract final class DateRecurrenceUtils {
  /// Generates a list of [DateTime] slots for recurring appointments.
  ///
  /// Enforces a hard ceiling of 24 slots and a maximum search space of
  /// 168 days (24 slots * 7 days/week) to avoid infinite loops.
  static List<DateTime> generateRecurrenceSlots({
    required DateTime startDate,
    required Set<int> weekdays,
    required int totalSessions,
  }) {
    if (weekdays.isEmpty || totalSessions <= 0) {
      return [];
    }

    final List<DateTime> slots = [];
    final int limit = totalSessions > 24 ? 24 : totalSessions;

    // Normalise start date to start of day (midnight) to prevent hour drift
    DateTime cursor = DateTime(startDate.year, startDate.month, startDate.day);
    int iterations = 0;
    const int maxIterations = 168; // 24 * 7

    while (slots.length < limit && iterations < maxIterations) {
      if (weekdays.contains(cursor.weekday)) {
        slots.add(cursor);
      }
      cursor = cursor.add(const Duration(days: 1));
      iterations++;
    }

    return slots;
  }
}
