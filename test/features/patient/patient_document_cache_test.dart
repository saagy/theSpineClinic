import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/patient/data/patient_document_cache.dart';

void main() {
  test('byte limit evicts oldest entries and reads preserve recent files', () {
    final cache = PatientDocumentCache(maxBytes: 10);
    cache.put('a', Uint8List(3));
    cache.put('b', Uint8List(3));
    cache.put('c', Uint8List(3));
    expect(cache.get('a'), hasLength(3));
    cache.put('d', Uint8List(7));

    expect(cache.get('b'), isNull);
    expect(cache.get('c'), isNull);
    expect(cache.get('a'), hasLength(3));
    expect(cache.get('d'), hasLength(7));
  });

  test('replacing a file frees its previous bytes', () {
    final cache = PatientDocumentCache(maxBytes: 10);
    cache.put('a', Uint8List(8));
    cache.put('a', Uint8List(2));
    cache.put('b', Uint8List(8));

    expect(cache.get('a'), hasLength(2));
    expect(cache.get('b'), hasLength(8));
  });

  test('oversized files do not evict unrelated cached files', () {
    final cache = PatientDocumentCache(maxBytes: 10);
    cache.put('a', Uint8List(5));
    cache.put('large', Uint8List(11));

    expect(cache.get('large'), isNull);
    expect(cache.get('a'), hasLength(5));
    cache.put('a', Uint8List(11));
    expect(cache.get('a'), isNull, reason: 'Do not retain an outdated version');
    cache.put('b', Uint8List(10));
    expect(cache.get('b'), hasLength(10));
  });

  test('removing a file frees its byte budget', () {
    final cache = PatientDocumentCache(maxBytes: 10);
    cache.put('a', Uint8List(6));
    cache.put('b', Uint8List(4));
    cache.remove('a');
    cache.remove('missing');
    cache.put('c', Uint8List(6));

    expect(cache.get('a'), isNull);
    expect(cache.get('b'), hasLength(4));
    expect(cache.get('c'), hasLength(6));
  });

  test('patient cleanup frees bytes without removing other patients', () {
    final cache = PatientDocumentCache(maxBytes: 10);
    cache.put('patient/a', Uint8List(3));
    cache.put('patient/b', Uint8List(3));
    cache.put('other/a', Uint8List(4));
    cache.removeByPrefix('patient/');
    cache.put('next/a', Uint8List(6));

    expect(cache.get('patient/a'), isNull);
    expect(cache.get('patient/b'), isNull);
    expect(cache.get('other/a'), hasLength(4));
    expect(cache.get('next/a'), hasLength(6));
  });

  test('clearing the cache resets the entire byte budget', () {
    final cache = PatientDocumentCache(maxBytes: 10);
    cache.put('old', Uint8List(10));
    cache.clear();
    cache.put('a', Uint8List(4));
    cache.put('b', Uint8List(6));

    expect(cache.get('old'), isNull);
    expect(cache.get('a'), hasLength(4));
    expect(cache.get('b'), hasLength(6));
  });

  test('entry limit still evicts least recently used small files', () {
    final cache = PatientDocumentCache(maxBytes: 100, maxEntries: 2);
    cache.put('a', Uint8List(1));
    cache.put('b', Uint8List(1));
    cache.get('a');
    cache.put('c', Uint8List(1));

    expect(cache.get('b'), isNull);
    expect(cache.get('a'), hasLength(1));
    expect(cache.get('c'), hasLength(1));
  });

  test('zero byte or entry budget disables retention', () {
    for (final cache in [
      PatientDocumentCache(maxBytes: 0),
      PatientDocumentCache(maxEntries: 0),
    ]) {
      cache.put('a', Uint8List(1));
      expect(cache.get('a'), isNull);
    }
  });
}
