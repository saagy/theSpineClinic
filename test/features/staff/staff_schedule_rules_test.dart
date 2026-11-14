import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_assignments.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_shift.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_picker_rows.dart';
import '../../fixtures/staff_branches_fixture.dart';
import '../../fixtures/staff_workspace.dart';

const tg = ClinicLocation.tagamoa;
const md = ClinicLocation.madinaty;

/// 2026-11-14 is a Saturday.
DateTime saturdayAt(int hour, [int minute = 0]) => DateTime(2026, 11, 14, hour, minute);

void main() {
  group('shifts', () {
    test('round-trip the database shape and order Saturday first', () {
      final StaffShift read = StaffShift.tryFromJson({
        'branch': 'tagamoa', 'weekday': 6, 'starts_at': '10:00:00', 'ends_at': '14:30:00',
      })!;
      expect(read, shift(tg, 6, 10, 14).copyWith(endMinutes: 14 * 60 + 30));
      expect(read.toJson(), {'branch': 'tagamoa', 'weekday': 6, 'starts_at': '10:00', 'ends_at': '14:30'});
      expect(StaffShift.tryFromJson({'branch': 'elsewhere', 'weekday': 1, 'starts_at': '09:00', 'ends_at': '10:00'}), isNull);
      final sorted = [shift(tg, 1, 9, 10), shift(tg, 6, 12, 13), shift(md, 6, 9, 10)]..sort(StaffShift.compare);
      expect(sorted.map((x) => (x.weekday, x.startMinutes ~/ 60)), [(6, 9), (6, 12), (1, 9)]);
    });

    test('back-to-back shifts touch without overlapping', () {
      expect(shift(tg, 6, 10, 14).overlaps(shift(md, 6, 14, 20)), isFalse);
      expect(shift(tg, 6, 10, 14).overlaps(shift(md, 6, 13, 20)), isTrue);
      expect(shift(tg, 6, 10, 14).overlaps(shift(md, 7, 10, 14)), isFalse);
      expect(shift(tg, 6, 10, 14).covers(14 * 60), isFalse);
    });

    test('removing a branch takes its hours with it', () {
      final StaffSchedule schedule = demoAssignments.scheduleOf('doctor').withBranches([tg]);
      expect(schedule.branches, [tg]);
      expect(schedule.shifts.every((x) => x.branch == tg), isTrue);
      expect(schedule.shiftsOn(6).length, 1);
    });
  });

  group('booking schedule mismatch', () {
    final List<StaffShift> week = demoAssignments.shiftsOf('doctor');

    test('fits inside a shift at the branch', () {
      expect(scheduleMismatch(week, tg, saturdayAt(11)), isNull);
      expect(scheduleMismatch(week, md, saturdayAt(15)), isNull);
    });

    test('explains each way a booking can fall outside', () {
      expect(scheduleMismatch(week, tg, saturdayAt(15)), isA<OutsideShiftHours>());
      expect(
        scheduleMismatch(week, tg, DateTime(2026, 11, 15, 13)),
        isA<WorksElsewhereThatDay>().having((m) => m.branches, 'branches', [md]),
      );
      expect(scheduleMismatch(week, md, saturdayAt(10)), isA<OutsideShiftHours>());
      expect(scheduleMismatch(week, tg, DateTime(2026, 11, 20, 11)), isA<NotScheduledThatDay>());
      expect(scheduleMismatch(week, md, DateTime(2026, 11, 16, 11)), isA<WorksElsewhereThatDay>());
    });

    test('no schedule never warns', () {
      expect(scheduleMismatch(const [], tg, saturdayAt(3)), isNull);
    });
  });

  group('doctor picker rows', () {
    final List<Staff> doctors = [staffRoster[1], staffRoster[4], staffRoster[3]];
    List<String> labels(List<DoctorPickerRow> rows) => [
      for (final row in rows)
        switch (row) {
          DoctorPickerHeading(:final label) => '# $label',
          DoctorPickerDoctor(:final doctor) => doctor.id,
          DoctorPickerToggle(:final expanded) => expanded ? 'hide' : 'show',
        },
    ];
    List<DoctorPickerRow> rows({bool collapse = true, bool expanded = false, bool searching = false, Set<String> selected = const {}}) =>
        doctorPickerRows(
          doctors: doctors,
          branch: tg,
          assignments: demoAssignments,
          collapseOthers: collapse,
          expanded: expanded,
          searching: searching,
          selectedIds: selected,
        );

    test('lists the branch first and keeps unassigned doctors there', () {
      expect(labels(rows(collapse: false)), ['# At Tagamoa', 'doctor', 'inactive', '# Other doctors', 'long']);
    });

    test('booking hides other branches until asked, searched or selected', () {
      expect(labels(rows()), ['# At Tagamoa', 'doctor', 'inactive', 'show']);
      expect(labels(rows(expanded: true)).last, 'hide');
      expect(labels(rows(searching: true)), contains('long'));
      expect(labels(rows(selected: {'long'})), contains('long'));
    });

    test('no branch keeps one flat list', () {
      expect(
        labels(doctorPickerRows(
          doctors: doctors, branch: null, assignments: demoAssignments,
          collapseOthers: true, expanded: false, searching: false, selectedIds: const {},
        )),
        ['doctor', 'long', 'inactive'],
      );
    });
  });

  test('head receptionists read staff records; front desk does not', () {
    final Staff desk = staffRoster[2];
    expect(desk.copyWith(canManagePayments: true).canViewStaffRecords, isTrue);
    expect(desk.copyWith(canManagePayments: false).canViewStaffRecords, isFalse);
    expect(staffAdmin.canViewStaffRecords, isTrue);
    expect(staffRoster[1].copyWith(role: UserRole.doctor).canViewStaffRecords, isFalse);
  });
}
