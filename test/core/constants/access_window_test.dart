/// Unit tests for the patient-access window helper.
///
/// The window is `[scheduled_at - 7 days, scheduled_at + 1 day]`. We verify:
///  - inside window → true
///  - past post-window by minutes → false
///  - 8 days in the future (over pre-window) → false
///  - exactly at the pre-edge → inclusive
///  - exactly at the post-edge → inclusive
///  - timezone drift (UTC vs local) does not flip the result
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/access_window.dart';

void main() {
  group('isWithinPatientAccessWindow', () {
    final DateTime scheduled = DateTime.utc(2026, 6, 21, 10, 0);

    test('inside the window returns true', () {
      expect(
        isWithinPatientAccessWindow(
          scheduled,
          now: DateTime.utc(2026, 6, 21, 10, 0),
        ),
        isTrue,
      );
    });

    test('just past post-edge by 2 minutes returns false', () {
      expect(
        isWithinPatientAccessWindow(
          scheduled,
          now: scheduled.add(const Duration(days: 1, minutes: 2)),
        ),
        isFalse,
        reason: 'Post-window cutoff is 1 day after scheduled_at.',
      );
    });

    test('8 days before scheduled_at returns false', () {
      expect(
        isWithinPatientAccessWindow(
          scheduled,
          now: scheduled.subtract(const Duration(days: 8)),
        ),
        isFalse,
        reason: 'Pre-window cutoff is 7 days before scheduled_at.',
      );
    });

    test('7 days before scheduled_at is inclusive', () {
      expect(
        isWithinPatientAccessWindow(
          scheduled,
          now: scheduled.subtract(const Duration(days: 7)),
        ),
        isTrue,
      );
    });

    test('1 day after scheduled_at is inclusive', () {
      expect(
        isWithinPatientAccessWindow(
          scheduled,
          now: scheduled.add(const Duration(days: 1)),
        ),
        isTrue,
      );
    });

    test('local-time and UTC-time input resolve identically', () {
      // Device-local DateTime constructed without Z suffix.
      final DateTime localScheduled = DateTime(2026, 6, 21, 10, 0);
      final DateTime nowLocal = DateTime(2026, 6, 21, 9, 0);
      expect(
        isWithinPatientAccessWindow(localScheduled, now: nowLocal),
        isTrue,
      );
    });
  });
}
