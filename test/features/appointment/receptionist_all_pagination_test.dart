import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_with_patient.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_table_header.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_all_tab.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_table_pagination.dart';

class _FakeCurrentUser extends CurrentUser {
  _FakeCurrentUser(this._staff);
  final Staff? _staff;

  @override
  Future<Staff?> build() async => _staff;
}

class _FakeAllAppointmentsNotifier extends AllAppointmentsNotifier {
  _FakeAllAppointmentsNotifier(this._items);

  final List<AppointmentWithPatient> _items;

  @override
  Future<List<AppointmentWithPatient>> build() async => _items;
}

void main() {
  group('ReceptionistAllTab responsiveness', () {
    final testStaff = Staff(
      id: 'staff-1',
      fullName: 'Receptionist User',
      email: 'rec@test.com',
      role: UserRole.receptionist,
      createdAt: DateTime(2026),
    );

    List<AppointmentWithPatient> createDummyAppointments(int count) {
      final now = DateTime.now();
      return List.generate(
        count,
        (i) => AppointmentWithPatient(
          appointment: Appointment(
            id: 'appt-$i',
            patientId: 'patient-$i',
            type: AppointmentType.normalPtSession,
            scheduledAt: now.add(Duration(hours: i)),
            createdAt: now,
          ),
          patient: Patient(
            id: 'patient-$i',
            fullName: 'Patient $i',
            phoneNumber: '0100000000$i',
            clinic: ClinicLocation.tagamoa,
            createdAt: now,
          ),
        ),
      );
    }

    testWidgets('shows desktop table header and pagination on wide screen',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final items = createDummyAppointments(30);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(() => _FakeCurrentUser(testStaff)),
            allAppointmentsProvider.overrideWith(
              () => _FakeAllAppointmentsNotifier(items),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ReceptionistAllTab(onStatusChanged: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Wide desktop should display AppointmentAgendaTableHeader
      expect(find.byType(AppointmentAgendaTableHeader), findsOneWidget);

      // Wide desktop should display AppTablePagination
      expect(find.byType(AppTablePagination), findsOneWidget);
    });

    testWidgets(
        'hides table pagination on mobile screens (infinite scroll mode)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final items = createDummyAppointments(15);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(() => _FakeCurrentUser(testStaff)),
            allAppointmentsProvider.overrideWith(
              () => _FakeAllAppointmentsNotifier(items),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ReceptionistAllTab(onStatusChanged: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile screen should NOT display AppTablePagination
      expect(find.byType(AppTablePagination), findsNothing);
    });
  });
}
