/// Shared calendar-week calculations for schedule screens.
library;

abstract final class ScheduleWeek {
  static const Duration span = Duration(days: 7);

  static DateTime day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime start(DateTime date) {
    final DateTime normalized = day(date);
    return normalized.subtract(Duration(days: (normalized.weekday + 1) % 7));
  }

  static bool same(DateTime first, DateTime second) =>
      start(first) == start(second);

  static DateTime windowStart(DateTime date) => start(date).subtract(span);

  static DateTime windowEnd(DateTime date) =>
      start(date).add(const Duration(days: 14));

  static Map<DateTime, List<T>> groupWindow<T>(
    Iterable<T> items, {
    required DateTime around,
    required DateTime Function(T item) dateOf,
  }) {
    final DateTime center = start(around);
    final Map<DateTime, List<T>> grouped = <DateTime, List<T>>{
      center.subtract(span): <T>[],
      center: <T>[],
      center.add(span): <T>[],
    };
    for (final T item in items) {
      grouped[start(dateOf(item))]?.add(item);
    }
    return grouped;
  }
}
