import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';

void main() {
  test('appointment status exposes only the active workflow states', () {
    expect(AppointmentStatus.values.map((status) => status.dbValue), <String>[
      'scheduled',
      'checked_in',
      'cancelled',
      'no_show',
    ]);
  });

  group('an outcome locks once its day is over', () {
    final DateTime now = DateTime(2026, 11, 15, 10);
    Appointment visit(AppointmentStatus status, DateTime day, {DateTime? recorded}) => Appointment(
      id: 'a',
      patientId: 'p',
      type: AppointmentType.normalPtSession,
      scheduledAt: day,
      status: status,
      createdAt: day,
      statusChangedAt: recorded,
    );

    test('a scheduled visit is never locked', () {
      expect(visit(AppointmentStatus.scheduled, DateTime(2026, 11, 1)).outcomeLocked(now: now), isFalse);
    });

    test('a check-in recorded today stays open, even for an older visit', () {
      expect(
        visit(AppointmentStatus.checkedIn, DateTime(2026, 11, 10), recorded: DateTime(2026, 11, 15, 9))
            .outcomeLocked(now: now),
        isFalse,
      );
    });

    test('yesterday\'s check-in is locked', () {
      expect(
        visit(AppointmentStatus.checkedIn, DateTime(2026, 11, 14, 9), recorded: DateTime(2026, 11, 14, 9))
            .outcomeLocked(now: now),
        isTrue,
      );
    });

    test('a cancellation for a visit still ahead stays open', () {
      expect(
        visit(AppointmentStatus.cancelled, DateTime(2026, 11, 20), recorded: DateTime(2026, 11, 2))
            .outcomeLocked(now: now),
        isFalse,
      );
    });

    test('an old visit with no recorded time uses its own day', () {
      expect(visit(AppointmentStatus.noShow, DateTime(2026, 11, 3)).outcomeLocked(now: now), isTrue);
    });
  });
}
