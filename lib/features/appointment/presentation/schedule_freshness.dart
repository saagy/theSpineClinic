/// Tracks successful week loads separately from local appointment edits.
class ScheduleFreshness {
  ScheduleFreshness({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const maxAge = Duration(minutes: 1);
  final DateTime Function() _now;
  final Map<DateTime, DateTime> _loadedAt = {};
  final Map<DateTime, DateTime> _attemptedAt = {};
  bool _refreshing = false;
  int revision = 0;

  void clear() {
    _loadedAt.clear();
    _attemptedAt.clear();
  }

  void loaded(DateTime week) => _loadedAt[week] = _now();

  bool startRefresh(DateTime week) {
    final loaded = _loadedAt[week];
    final attempted = _attemptedAt[week];
    final now = _now();
    if (_refreshing ||
        loaded == null ||
        now.difference(loaded) < maxAge ||
        (attempted != null && now.difference(attempted) < maxAge)) {
      return false;
    }
    _refreshing = true;
    _attemptedAt[week] = now;
    return true;
  }

  void finishRefresh() => _refreshing = false;
}
