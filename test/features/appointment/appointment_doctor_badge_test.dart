import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_with_patient.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_doctor_badge.dart';
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

  final appt = Appointment(
    id: 'appt-1',
    patientId: patient.id,
    type: AppointmentType.normalPtSession,
    scheduledAt: DateTime(2026, 8, 20, 10, 30),
    status: AppointmentStatus.scheduled,
    createdAt: DateTime(2026),
  );

  group('AppointmentDoctorBadge formatDoctorName', () {
    test('prepends Dr. when missing', () {
      expect(AppointmentDoctorBadge.formatDoctorName('Khaled Aly'), 'Dr. Khaled Aly');
    });

    test('avoids duplicating Dr. prefix', () {
      expect(AppointmentDoctorBadge.formatDoctorName('Dr. Khaled Aly'), 'Dr. Khaled Aly');
      expect(AppointmentDoctorBadge.formatDoctorName('dr. Khaled Aly'), 'dr. Khaled Aly');
      expect(AppointmentDoctorBadge.formatDoctorName('Dr Khaled Aly'), 'Dr Khaled Aly');
    });
  });

  group('AppointmentDoctorBadge rendering', () {
    testWidgets('renders single doctor with tooltip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppointmentDoctorBadge(
              doctorNames: ['Khaled Aly'],
            ),
          ),
        ),
      );

      expect(find.text('Dr. Khaled Aly'), findsOneWidget);
      expect(find.text('+1'), findsNothing);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Dr. Khaled Aly');
    });

    testWidgets('renders multiple doctors with +N badge and multi-line tooltip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppointmentDoctorBadge(
              doctorNames: ['Khaled Aly', 'Mona Zaki', 'Tamer Hosny'],
            ),
          ),
        ),
      );

      expect(find.text('Dr. Khaled Aly'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Dr. Khaled Aly\nDr. Mona Zaki\nDr. Tamer Hosny');
    });

    testWidgets('compact mode prefixes bullet and renders badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppointmentDoctorBadge(
              doctorNames: ['Khaled Aly', 'Mona Zaki'],
              isCompact: true,
            ),
          ),
        ),
      );

      expect(find.text('• Dr. Khaled Aly'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
    });

    testWidgets('falls back to comma-separated doctorName string', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppointmentDoctorBadge(
              fallbackDoctorName: 'Khaled Aly, Mona Zaki',
            ),
          ),
        ),
      );

      expect(find.text('Dr. Khaled Aly'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Dr. Khaled Aly\nDr. Mona Zaki');
    });
  });

  group('AppointmentAgendaRow multi-doctor integration', () {
    testWidgets('wide row displays Dr. name and +N badge with tooltip', (tester) async {
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
                  appointment: appt,
                  patient: patient,
                  doctorNames: const ['Khaled Aly', 'Mona Zaki'],
                ),
                showDoctor: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dr. Khaled Aly'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);

      final tooltip = tester.widget<Tooltip>(
        find.descendant(
          of: find.byType(AppointmentDoctorBadge),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, 'Dr. Khaled Aly\nDr. Mona Zaki');
    });

    testWidgets('compact row omits doctor name and badge completely', (tester) async {
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
                  appointment: appt,
                  patient: patient,
                  doctorNames: const ['Khaled Aly', 'Mona Zaki'],
                ),
                showDoctor: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppointmentDoctorBadge), findsNothing);
      expect(find.textContaining('Khaled'), findsNothing);
      expect(find.text('+1'), findsNothing);
    });
  });
}
