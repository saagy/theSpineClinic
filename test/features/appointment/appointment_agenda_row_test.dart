import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_with_patient.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row_compact.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row_wide.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

class _FakeCurrentUser extends CurrentUser {
  _FakeCurrentUser(this._staff);
  final Staff? _staff;

  @override
  Future<Staff?> build() async => _staff;
}

void main() {
  final staff = Staff(
    id: 'staff-1',
    fullName: 'Sara Ahmed',
    email: 'sara@clinic.com',
    role: UserRole.receptionist,
    branch: ClinicLocation.tagamoa,
    isActive: true,
    createdAt: DateTime(2026),
  );

  final patient = Patient(
    id: 'patient-1',
    fullName: 'Youssef Mansour',
    phoneNumber: '01012345678',
    clinic: ClinicLocation.tagamoa,
    createdAt: DateTime(2026),
  );

  final scheduledAppt = Appointment(
    id: 'appt-1',
    patientId: patient.id,
    type: AppointmentType.normalPtSession,
    scheduledAt: DateTime(2026, 8, 20, 10, 30),
    status: AppointmentStatus.scheduled,
    createdAt: DateTime(2026),
  );

  final checkedInAppt = Appointment(
    id: 'appt-2',
    patientId: patient.id,
    type: AppointmentType.spinalTractionSession,
    scheduledAt: DateTime(2026, 8, 20, 11, 0),
    status: AppointmentStatus.checkedIn,
    createdAt: DateTime(2026),
  );

  testWidgets('renders agenda row with patient name, type, and Check-In button when scheduled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(() => _FakeCurrentUser(staff)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AppointmentAgendaRow(
              item: AppointmentWithPatient(
                appointment: scheduledAppt,
                patient: patient,
                doctorName: 'Mahmoud',
              ),
              showDoctor: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppointmentAgendaCompactRow), findsOneWidget);
    expect(find.byType(AppointmentAgendaWideRow), findsNothing);
    expect(find.text('Youssef Mansour'), findsOneWidget);
    expect(find.text(AppointmentType.normalPtSession.displayLabel), findsOneWidget);
    expect(find.textContaining('Mahmoud'), findsNothing);
    expect(find.byTooltip(AppStrings.checkIn), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders agenda row with Checked In indicator and hides doctor name on doctor view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(() => _FakeCurrentUser(staff)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AppointmentAgendaRow(
              item: AppointmentWithPatient(
                appointment: checkedInAppt,
                patient: patient,
                doctorName: 'Mahmoud',
              ),
              showDoctor: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppointmentAgendaWideRow), findsOneWidget);
    expect(find.byType(AppointmentAgendaCompactRow), findsNothing);
    expect(find.text('Youssef Mansour'), findsOneWidget);
    expect(find.text(AppointmentType.spinalTractionSession.displayLabel), findsOneWidget);
    expect(find.text('Dr. Mahmoud'), findsNothing);
    expect(find.text(AppStrings.checkedIn), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping 3-dot button opens anchored popup menu with options', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(() => _FakeCurrentUser(staff)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AppointmentAgendaRow(
              item: AppointmentWithPatient(
                appointment: scheduledAppt,
                patient: patient,
                doctorName: 'Mahmoud',
              ),
              showDoctor: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final menuButton = find.byTooltip(AppStrings.moreActions);
    expect(menuButton, findsOneWidget);
    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.viewDetails), findsOneWidget);
    expect(find.text(AppStrings.cancelAppointment), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

