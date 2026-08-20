import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_day_list.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_today_tab.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

class _SignedOutUser extends CurrentUser {
  @override
  Future<Staff?> build() async => null;
}

void main() {
  testWidgets('toolbar scrolls away while the calendar stays visible with loaded data', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(390, 640));

    final testDate = DateTime(2026, 7, 16);
    final items = List.generate(
      10,
      (i) => AppointmentWithPatient(
        appointment: Appointment(
          id: 'appt-$i',
          patientId: 'patient-$i',
          type: AppointmentType.normalPtSession,
          scheduledAt: testDate.add(Duration(hours: 9 + i)),
          createdAt: DateTime(2026),
        ),
        patient: Patient(
          id: 'patient-$i',
          fullName: 'Patient Name $i',
          phoneNumber: '0101234567$i',
          clinic: ClinicLocation.tagamoa,
          createdAt: DateTime(2026),
        ),
      ),
    );

    final state = ReceptionistAppointmentsState(
      selectedDate: testDate,
      allItems: items,
      loading: false,
    );

    await _pumpTodayTab(tester, state: state);

    final Finder toolbar = find.byKey(
      const ValueKey<String>('receptionist-schedule-toolbar'),
    );
    final Finder calendar = find.byKey(
      const ValueKey<String>('schedule-week-navigator'),
    );

    expect(toolbar.hitTestable(), findsOneWidget);
    expect(calendar.hitTestable(), findsOneWidget);

    await tester.drag(
      find.byType(ReceptionistDayList),
      const Offset(0, -(AppSizes.p48 * 3)),
    );
    await tester.pumpAndSettle();

    expect(toolbar.hitTestable(), findsNothing);
    expect(calendar.hitTestable(), findsOneWidget);

    await tester.drag(
      find.byType(ReceptionistDayList),
      const Offset(0, AppSizes.p48 * 3),
    );
    await tester.pumpAndSettle();

    expect(toolbar.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toolbar scrolls away while the calendar stays visible in loading state', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(390, 640));
    await _pumpTodayTab(tester);

    final Finder toolbar = find.byKey(
      const ValueKey<String>('receptionist-schedule-toolbar'),
    );
    final Finder calendar = find.byKey(
      const ValueKey<String>('schedule-week-navigator'),
    );

    expect(toolbar.hitTestable(), findsOneWidget);
    expect(calendar.hitTestable(), findsOneWidget);

    await tester.drag(
      find.byType(SkeletonTileList),
      const Offset(0, -(AppSizes.p48 * 2)),
    );
    await tester.pumpAndSettle();

    expect(toolbar.hitTestable(), findsNothing);
    expect(calendar.hitTestable(), findsOneWidget);

    await tester.drag(
      find.byType(SkeletonTileList),
      const Offset(0, AppSizes.p48 * 2),
    );
    await tester.pumpAndSettle();

    expect(toolbar.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('today schedule stays constrained on desktop', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1200, 800));
    await _pumpTodayTab(tester);

    expect(
      tester.getSize(find.byType(NestedScrollView)).width,
      AppSizes.maxContentWidth,
    );
    expect(tester.takeException(), isNull);
  });
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpTodayTab(
  WidgetTester tester, {
  ReceptionistAppointmentsState? state,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [currentUserProvider.overrideWith(_SignedOutUser.new)],
      child: MaterialApp(
        home: Scaffold(
          body: ReceptionistTodayTab(
            state:
                state ??
                ReceptionistAppointmentsState(
                  selectedDate: DateTime(2026, 7, 16),
                ),
            searchQuery: '',
            onSearchChanged: (_) {},
            onRefresh: () {},
            onStatusChanged: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
