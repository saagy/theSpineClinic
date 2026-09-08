import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_with_patient.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row.dart';
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

Patient _makePatient(String id, String name) => Patient(
  id: id,
  fullName: name,
  phoneNumber: '01012345678',
  clinic: ClinicLocation.tagamoa,
  createdAt: DateTime(2026),
);

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

  final patientA = _makePatient('patient-a', 'Amir Karara');
  final patientB = _makePatient('patient-b', 'Karim Abdelaziz');
  final patientC = _makePatient('patient-c', 'Salma Abdelrahman');

  testWidgets('renders check icon on desktop Check-In button', (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final appt = Appointment(
      id: 'appt-1',
      patientId: patientA.id,
      type: AppointmentType.initialAssessment,
      scheduledAt: DateTime(2026, 8, 20, 11, 0),
      status: AppointmentStatus.scheduled,
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(() => _FakeCurrentUser(staff)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AppointmentAgendaRow(
              item: AppointmentWithPatient(
                appointment: appt,
                patient: patientA,
              ),
              showDoctor: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppointmentAgendaWideRow), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    expect(find.text(AppStrings.checkIn), findsOneWidget);
  });

  testWidgets(
    'aligns Type column at identical horizontal position across all rows',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final appt1 = Appointment(
        id: 'appt-1',
        patientId: patientA.id,
        type: AppointmentType.initialAssessment,
        scheduledAt: DateTime(2026, 8, 20, 11, 0),
        status: AppointmentStatus.scheduled,
        createdAt: DateTime(2026),
      );
      final appt2 = Appointment(
        id: 'appt-2',
        patientId: patientB.id,
        type: AppointmentType.normalPtSession,
        scheduledAt: DateTime(2026, 8, 20, 11, 30),
        status: AppointmentStatus.cancelled,
        createdAt: DateTime(2026),
      );
      final appt3 = Appointment(
        id: 'appt-3',
        patientId: patientC.id,
        type: AppointmentType.spinalTractionSession,
        scheduledAt: DateTime(2026, 8, 20, 12, 0),
        status: AppointmentStatus.checkedIn,
        createdAt: DateTime(2026),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(() => _FakeCurrentUser(staff)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  AppointmentAgendaRow(
                    item: AppointmentWithPatient(
                      appointment: appt1,
                      patient: patientA,
                      doctorName: null,
                    ),
                    showDoctor: true,
                  ),
                  AppointmentAgendaRow(
                    item: AppointmentWithPatient(
                      appointment: appt2,
                      patient: patientB,
                      doctorName: 'Sarah Jenkins',
                    ),
                    showDoctor: true,
                  ),
                  AppointmentAgendaRow(
                    item: AppointmentWithPatient(
                      appointment: appt3,
                      patient: patientC,
                      doctorName: 'Sarah Jenkins',
                    ),
                    showDoctor: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final type1Pos = tester.getTopLeft(
        find.text(AppStrings.initialAssessment),
      );
      final type2Pos = tester.getTopLeft(find.text(AppStrings.normalPtSession));
      final type3Pos = tester.getTopLeft(
        find.text(AppStrings.spinalTractionSession),
      );

      expect(type1Pos.dx, equals(type2Pos.dx));
      expect(type2Pos.dx, equals(type3Pos.dx));

      final menus = find.byTooltip(AppStrings.moreActions);
      expect(menus, findsNWidgets(3));
      expect(
        tester.getTopLeft(menus.at(0)).dx,
        equals(tester.getTopLeft(menus.at(1)).dx),
      );
      expect(
        tester.getTopLeft(menus.at(1)).dx,
        equals(tester.getTopLeft(menus.at(2)).dx),
      );
    },
  );
}
