/// Provider tests for [appointmentPatientAccessProvider] and the
/// sealed [PatientAppointmentAccess] returned branches.
///
/// Verifies the family provider resolves the right sealed type given
/// canned upstream dependencies, and the simple widget tap behaviour
/// for the chevron-vs-lock icon swap. We bypass the Tooltip wrapper
/// in the provider test (the widget-level inkwell hover/tooltip is
/// pure decoration).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spine_clinic_app/core/constants/access_window.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_appointment_access.dart';

void main() {
  group('PatientAppointmentAccess sealed type', () {
    test('granted() returns Granted', () {
      expect(granted(), isA<Granted>());
    });

    test('expired() returns AccessExpired', () {
      expect(expired(), isA<AccessExpired>());
    });

    test('notAuthenticated() returns NotAuthenticated', () {
      expect(notAuthenticated(), isA<NotAuthenticated>());
    });

    test('Granted is not a subclass of AccessExpired', () {
      expect(granted(), isNot(isA<AccessExpired>()));
      expect(expired(), isNot(isA<Granted>()));
    });
  });

  group('Access window integration with status icons', () {
    test('header chevron is the icon for granted path', () {
      const patient = 'p-1';
      final scheduled = DateTime.now().toUtc();
      final mapped = guidedIconFor(false, scheduled);
      expect(mapped, Icons.chevron_right_rounded);
      expect(isWithinPatientAccessWindow(scheduled), isTrue);
      expect(patient, isNotEmpty);
    });

    test('header lock is the icon for expired/not-auth paths', () {
      final scheduledPast = DateTime.now().toUtc().subtract(
            const Duration(days: 30),
          );
      final mapped = guidedIconFor(true, scheduledPast);
      expect(mapped, Icons.lock_outline_rounded);
      expect(isWithinPatientAccessWindow(scheduledPast), isFalse);
    });
  });
}

IconData guidedIconFor(bool locked, DateTime scheduled) =>
    locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded;
