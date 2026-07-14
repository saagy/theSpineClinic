import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_state.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_workboard_controls.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_workboard_lists.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/segmented_count_tabs.dart';

void main() {
  test('copyWith preserves workboard lists and can clear the doctor', () {
    final Patient patient = _patient();
    final BookingWorkboardState state = BookingWorkboardState(
      date: DateTime(2026, 7, 14),
      doctorId: 'doctor-1',
      duePatients: [patient],
    );

    final BookingWorkboardState changed = state.copyWith(
      view: BookingWorkboardView.schedule,
    );
    expect(changed.doctorId, 'doctor-1');
    expect(changed.duePatients, [patient]);

    final BookingWorkboardState cleared = changed.copyWith(clearDoctor: true);
    expect(cleared.doctorId, isNull);
    expect(cleared.duePatients, [patient]);
  });

  testWidgets('past scheduled appointments show the needs-action warning', (
    tester,
  ) async {
    final Patient patient = _patient();
    final Appointment appointment = Appointment(
      id: 'appointment-1',
      patientId: patient.id,
      type: AppointmentType.normalPtSession,
      scheduledAt: DateTime.now().subtract(const Duration(days: 30)),
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceptionistAppointmentCard(
            item: AppointmentWithPatient(
              appointment: appointment,
              patient: patient,
            ),
            showMenu: false,
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.pastScheduledNeedsAction), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('booking defaults to all doctors and opens the shared filter', (
    tester,
  ) async {
    bool filterOpened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookingWorkboardControls(
            date: DateTime(2026, 7, 14),
            doctor: null,
            onPreviousDay: () {},
            onNextDay: () {},
            onChooseDate: () {},
            onFilterDoctor: () => filterOpened = true,
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.allDoctors), findsOneWidget);
    await tester.tap(find.text(AppStrings.allDoctors));
    expect(filterOpened, isTrue);
  });

  testWidgets(
    'compact workboard contains one segmented list without overflow',
    (tester) async {
      await _pumpLists(tester, width: 390, wide: false);

      expect(find.byType(SegmentedCountTabs), findsOneWidget);
      expect(find.text(AppStrings.duePatients), findsOneWidget);
      expect(find.text(AppStrings.schedule), findsOneWidget);
      expect(find.text(AppStrings.noDuePatients), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('wide workboard contains both independently constrained panes', (
    tester,
  ) async {
    await _pumpLists(tester, width: 1200, wide: true);

    expect(find.byType(SegmentedCountTabs), findsNothing);
    expect(find.text(AppStrings.noDuePatients), findsOneWidget);
    expect(find.text(AppStrings.noScheduleForDate), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLists(
  WidgetTester tester, {
  required double width,
  required bool wide,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BookingWorkboardLists(
          state: BookingWorkboardState(date: DateTime(2026, 7, 14)),
          wide: wide,
          onRefresh: () async {},
          onViewChanged: (_) {},
          onCall: (_) {},
          onBook: (_) {},
          onRemind: (_) {},
          onStop: (_) {},
        ),
      ),
    ),
  );
}

Patient _patient() => Patient(
  id: 'patient-1',
  fullName: 'Mariam Hassan',
  phoneNumber: '01000000000',
  clinic: ClinicLocation.tagamoa,
  createdAt: DateTime(2026),
  nextVisitDate: DateTime(2026, 7, 14),
);
