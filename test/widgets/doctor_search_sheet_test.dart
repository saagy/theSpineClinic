// Lock-in tests for the DoctorSearchSheet selection state fix.
// Reproduces previously reported bugs:
//   B1: only first/last taps register (modal read stale widget.selectedDoctors)
//   B2: check indicator never updates inside the modal
//   B3: tapping the same doctor twice added duplicates
// Verifies the modal now owns its selection via Set<String>, re-renders
// on every toggle, and propagates cumulative lists to the parent.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/doctor_search_sheet.dart';

Staff _staff(String id, String name) => Staff(
      id: id,
      fullName: name,
      email: '$id@spine.test',
      role: UserRole.doctor,
      isActive: true,
      createdAt: DateTime(2024),
    );

Widget _harness({
  required List<Staff> activeDoctors,
  required List<Staff> selectedDoctors,
  required void Function(List<Staff>) onSelectionChanged,
}) =>
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => Center(
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: ctx,
                isScrollControlled: true,
                builder: (_) => DoctorSearchSheet(
                  activeDoctors: activeDoctors,
                  selectedDoctors: selectedDoctors,
                  onSelectionChanged: onSelectionChanged,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

void main() {
  final doctors = [
    _staff('a', 'Dr Alice'),
    _staff('b', 'Dr Bob'),
    _staff('c', 'Dr Carol'),
  ];

  group('DoctorSearchSheet selection', () {
    testWidgets('3 taps accumulate; check icons update each tap',
        (tester) async {
      final emitted = <List<String>>[];
      await tester.pumpWidget(_harness(
        activeDoctors: doctors,
        selectedDoctors: const [],
        onSelectionChanged: (u) => emitted.add(u.map((s) => s.id).toList()),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.selectDoctors), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);

      await tester.tap(find.text('Dr Alice'));
      await tester.pumpAndSettle();
      expect(emitted.last, ['a']);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.circle_outlined), findsNWidgets(2));

      await tester.tap(find.text('Dr Bob'));
      await tester.pumpAndSettle();
      expect(emitted.last, ['a', 'b']);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));

      await tester.tap(find.text('Dr Carol'));
      await tester.pumpAndSettle();
      expect(emitted.last, ['a', 'b', 'c']);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
      expect(find.byIcon(Icons.circle_outlined), findsNothing);
    });

    testWidgets('toggle-off removes a doctor from the list', (tester) async {
      final emitted = <List<String>>[];
      await tester.pumpWidget(_harness(
        activeDoctors: doctors,
        selectedDoctors: const [],
        onSelectionChanged: (u) => emitted.add(u.map((s) => s.id).toList()),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dr Alice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dr Bob'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dr Carol'));
      await tester.pumpAndSettle();
      expect(emitted.last, ['a', 'b', 'c']);

      await tester.tap(find.text('Dr Bob'));
      await tester.pumpAndSettle();
      expect(emitted.last, ['a', 'c']);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    });

    testWidgets('cannot toggle off the only selected doctor', (tester) async {
      var emitCount = 0;
      Object? captured;
      await tester.pumpWidget(_harness(
        activeDoctors: [_staff('a', 'Dr Alice')],
        selectedDoctors: const [],
        onSelectionChanged: (u) {
          emitCount += 1;
          try {
            expect(u.map((s) => s.id).toList(), ['a']);
          } catch (e) {
            captured = e;
          }
        },
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dr Alice'));
      await tester.pumpAndSettle();
      expect(emitCount, 1);

      await tester.tap(find.text('Dr Alice'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      expect(emitCount, 1, reason: 'callback must not fire a second time');
      expect(find.text(AppStrings.atLeastOneDoctorRequired), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(captured, isNull);
    });

    testWidgets('respects the parent initial selection', (tester) async {
      final emitted = <List<String>>[];
      await tester.pumpWidget(_harness(
        activeDoctors: [doctors[0], doctors[1]],
        selectedDoctors: [doctors[0]],
        onSelectionChanged: (u) => emitted.add(u.map((s) => s.id).toList()),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.circle_outlined), findsOneWidget);

      await tester.tap(find.text('Dr Bob'));
      await tester.pumpAndSettle();
      expect(emitted.last, ['a', 'b']);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    });
  });
}
