import 'dart:collection';
import 'dart:typed_data';

/// In-memory LRU cache for downloaded patient document and image bytes.
///
/// Ensures gallery flipping, thumbnails, and preview loaders render
/// instantaneously (0 ms) without repetitive network fetches.
class PatientDocumentCache {
  PatientDocumentCache({int maxEntries = 50}) : _maxEntries = maxEntries;

  final int _maxEntries;
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

  /// Stores [bytes] for [key], evicting the least-recently used entry if needed.
  void put(String key, Uint8List bytes) {
    _cache.remove(key);
    if (_cache.length >= _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = bytes;
  }

  /// Removes the cached entry for [key].
  void remove(String key) {
    _cache.remove(key);
  }

  /// Removes all entries whose key starts with [prefix].
  void removeByPrefix(String prefix) {
    final List<String> keysToRemove = _cache.keys
        .where((String k) => k.startsWith(prefix))
        .toList();
    for (final String key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Clears the entire cache.
  void clear() {
    _cache.clear();
  }
}
