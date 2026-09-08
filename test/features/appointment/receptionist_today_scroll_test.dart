import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_with_patient.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_table_header.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_day_list.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_today_tab.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/schedule_toolbar.dart';
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
  testWidgets(
    'upper controls scroll away on mobile so appointment density remains high',
    (WidgetTester tester) async {
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

      final Finder upperControls = find.byKey(
        const ValueKey<String>('receptionist-schedule-upper-controls'),
      );
      final Finder toolbar = find.byType(ScheduleToolbar);
      final Finder calendar = find.byKey(
        const ValueKey<String>('schedule-week-navigator'),
      );

      expect(upperControls.hitTestable(), findsOneWidget);
      expect(toolbar.hitTestable(), findsOneWidget);
      expect(calendar.hitTestable(), findsOneWidget);

      await tester.drag(
        find.byType(ReceptionistDayList),
        const Offset(0, -(AppSizes.p48 * 4)),
      );
      await tester.pumpAndSettle();

      expect(upperControls.hitTestable(), findsNothing);

      await tester.drag(
        find.byType(ReceptionistDayList),
        const Offset(0, AppSizes.p48 * 4),
      );
      await tester.pumpAndSettle();

      expect(upperControls.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'upper controls scroll away in loading state',
    (WidgetTester tester) async {
      _setViewport(tester, const Size(390, 640));
      await _pumpTodayTab(tester);

      final Finder upperControls = find.byKey(
        const ValueKey<String>('receptionist-schedule-upper-controls'),
      );

      expect(upperControls.hitTestable(), findsOneWidget);

      await tester.drag(
        find.byType(SkeletonTileList),
        const Offset(0, -(AppSizes.p48 * 3)),
      );
      await tester.pumpAndSettle();

      expect(upperControls.hitTestable(), findsNothing);

      await tester.drag(
        find.byType(SkeletonTileList),
        const Offset(0, AppSizes.p48 * 3),
      );
      await tester.pumpAndSettle();

      expect(upperControls.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('desktop agenda table header renders on desktop and hides on mobile', (
    WidgetTester tester,
  ) async {
    // Desktop viewport
    _setViewport(tester, const Size(1200, 800));
    await _pumpTodayTab(tester);

    expect(find.byType(AppointmentAgendaTableHeader), findsOneWidget);
    expect(
      tester.getSize(find.byType(AppointmentAgendaTableHeader)).height,
      38.0,
    );

    // Mobile viewport
    _setViewport(tester, const Size(390, 640));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(AppointmentAgendaTableHeader)).height,
      0.0,
    );
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
