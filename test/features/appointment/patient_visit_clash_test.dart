import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/domain/patient_visit_clash.dart';

Appointment _visit(
  String id,
  DateTime at, {
  AppointmentStatus status = AppointmentStatus.scheduled,
}) => Appointment(
  id: id,
  patientId: 'patient',
  type: AppointmentType.normalPtSession,
  scheduledAt: at.toUtc(),
  status: status,
  createdAt: DateTime(2026),
);

void main() {
  final DateTime nov21at10 = DateTime(2026, 11, 21, 10);

  test('no existing visits means no clash', () {
    expect(findPatientVisitClashes(requested: [nov21at10], existing: const []), isEmpty);
  });

  test('a visit at the same minute is a same-time clash', () {
    final clashes = findPatientVisitClashes(
      requested: [nov21at10],
      existing: [_visit('a', nov21at10)],
    );
    expect(clashes, hasLength(1));
    expect(clashes.single.sameTime, true);
  });

  test('a visit earlier that day is a same-day clash', () {
    final clashes = findPatientVisitClashes(
      requested: [nov21at10],
      existing: [_visit('a', DateTime(2026, 11, 21, 8, 30))],
    );
    expect(clashes.single.sameTime, false);
  });

  test('the same-time visit wins when a day has several', () {
    final clashes = findPatientVisitClashes(
      requested: [nov21at10],
      existing: [_visit('early', DateTime(2026, 11, 21, 8)), _visit('same', nov21at10)],
    );
    expect(clashes.single.existing.id, 'same');
  });

  test('cancelled visits, other days and the edited visit are ignored', () {
    final clashes = findPatientVisitClashes(
      requested: [nov21at10],
      existing: [
        _visit('cancelled', nov21at10, status: AppointmentStatus.cancelled),
        _visit('next-day', DateTime(2026, 11, 22, 10)),
        _visit('editing', nov21at10),
      ],
      ignoreId: 'editing',
    );
    expect(clashes, isEmpty);
  });

  test('checked-in visits still count', () {
    final clashes = findPatientVisitClashes(
      requested: [nov21at10],
      existing: [_visit('done', nov21at10, status: AppointmentStatus.checkedIn)],
    );
    expect(clashes, hasLength(1));
  });

  test('a recurring series reports each clashing date once', () {
    final clashes = findPatientVisitClashes(
      requested: [nov21at10, DateTime(2026, 11, 23, 10), DateTime(2026, 11, 25, 10)],
      existing: [
        _visit('a', DateTime(2026, 11, 21, 9)),
        _visit('b', DateTime(2026, 11, 21, 15)),
        _visit('c', DateTime(2026, 11, 25, 10)),
      ],
    );
    expect(clashes.map((c) => c.requested.day), [21, 25]);
    expect(clashes.map((c) => c.sameTime), [false, true]);
  });
}
