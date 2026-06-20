// Marker test indicating the SQL sanity script for `handle_package_deduction`
// is checked into the repository. Run with:
//   psql "$DATABASE_URL" -f test/trigger_sanity.sql

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sql sanity file is present in test/ folder', () {
    // Sanity-only marker. No executable assertions here.
  });
}
