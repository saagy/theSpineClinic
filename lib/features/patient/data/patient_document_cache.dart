import 'dart:collection';
import 'dart:typed_data';

/// In-memory LRU cache for downloaded patient document and image bytes.
///
/// Retains at most 64 MiB of document bytes by default. Decoded images and
/// documents currently held by viewers are outside this cache's budget.
class PatientDocumentCache {
  PatientDocumentCache({int maxEntries = 50, int maxBytes = 64 * 1024 * 1024})
    : assert(maxEntries >= 0),
      assert(maxBytes >= 0),
      _maxEntries = maxEntries,
      _maxBytes = maxBytes;

  final int _maxEntries;
  final int _maxBytes;
  int _cachedBytes = 0;
  final LinkedHashMap<String, Uint8List> _cache =
      LinkedHashMap<String, Uint8List>();

  /// Retrieves cached bytes for [key], refreshing its LRU position.
  Uint8List? get(String key) {
    final Uint8List? bytes = _cache.remove(key);
    if (bytes != null) {
      _cache[key] = bytes;
    }
    return bytes;
  }

  /// Evicts least-recently used entries until both budgets fit.
  /// Oversized files remain usable by callers but are not retained here.
  void put(String key, Uint8List bytes) {
    remove(key);
    if (_maxEntries <= 0 || _maxBytes <= 0 || bytes.lengthInBytes > _maxBytes) {
      return;
    }
    while (_cache.isNotEmpty &&
        (_cache.length >= _maxEntries ||
            _cachedBytes + bytes.lengthInBytes > _maxBytes)) {
      remove(_cache.keys.first);
    }
    _cache[key] = bytes;
    _cachedBytes += bytes.lengthInBytes;
  }

  /// Removes the cached entry for [key].
  void remove(String key) {
    final Uint8List? bytes = _cache.remove(key);
    if (bytes != null) _cachedBytes -= bytes.lengthInBytes;
  }

  /// Removes all entries whose key starts with [prefix].
  void removeByPrefix(String prefix) {
    final List<String> keysToRemove = _cache.keys
        .where((String k) => k.startsWith(prefix))
        .toList();
    for (final String key in keysToRemove) {
      remove(key);
    }
  }

  /// Clears the entire cache.
  void clear() {
    _cache.clear();
    _cachedBytes = 0;
  }
}
