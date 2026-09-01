import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/utils/schedule_density_controller.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_state.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_state.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_day_list.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_day_list.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_day_list_helpers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/due_patient_card.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_grouped_appointment_card.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

void main() {
  group('Schedule Density Controller Tests', () {
    test('defaults to standard mode and toggles correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(scheduleCompactControllerProvider), isFalse);
      expect(
        scheduleDensityLabel(
          container.read(scheduleCompactControllerProvider),
        ),
        AppStrings.scheduleDensityStandard,
      );

      container.read(scheduleCompactControllerProvider.notifier).toggle();
      expect(container.read(scheduleCompactControllerProvider), isTrue);
      expect(
        scheduleDensityLabel(
          container.read(scheduleCompactControllerProvider),
        ),
        AppStrings.scheduleDensityCompact,
      );

      container
          .read(scheduleCompactControllerProvider.notifier)
          .setCompact(false);
      expect(container.read(scheduleCompactControllerProvider), isFalse);
    });
  });

  group('ReceptionistAppointmentCard Density & Responsive Layout Tests', () {
    final patient = Patient(
      id: 'patient-1',
      fullName: 'Ahmed Mostafa',
      phoneNumber: '01012345678',
      clinic: ClinicLocation.tagamoa,
      createdAt: DateTime(2026),
    );

    final appointment = Appointment(
      id: 'appointment-1',
      patientId: patient.id,
      type: AppointmentType.normalPtSession,
      scheduledAt: DateTime.now(),
      createdAt: DateTime(2026),
    );

    testWidgets('renders standard card on mobile without overflow', (
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
          child: MaterialApp(
            home: Scaffold(
              body: ReceptionistAppointmentCard(
                item: AppointmentWithPatient(
                  appointment: appointment,
                  patient: patient,
                ),
                isCompact: false,
                showMenu: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Ahmed Mostafa'), findsOneWidget);
      expect(
        find.text(AppointmentType.normalPtSession.displayLabel),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders compact card on mobile without overflow', (
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
          child: MaterialApp(
            home: Scaffold(
              body: ReceptionistAppointmentCard(
                item: AppointmentWithPatient(
                  appointment: appointment,
                  patient: patient,
                ),
                isCompact: true,
                showMenu: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Ahmed Mostafa'), findsOneWidget);
      expect(
        find.text(AppointmentType.normalPtSession.displayLabel),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders wide PC view (>= 600px) cleanly without overflow', (
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
          child: MaterialApp(
            home: Scaffold(
              body: ReceptionistAppointmentCard(
                item: AppointmentWithPatient(
                  appointment: appointment,
                  patient: patient,
                ),
                isCompact: true,
                showMenu: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Ahmed Mostafa'), findsOneWidget);
      expect(
        find.text(AppointmentType.normalPtSession.displayLabel),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Grouped Dual Session Card Tests', () {
    final staff = Staff(
      id: 'staff-rec-1',
      userId: 'user-rec-1',
      fullName: 'Sara Receptionist',
      email: 'sara@clinic.com',
      role: UserRole.receptionist,
      createdAt: DateTime(2026),
    );

    final patient = Patient(
      id: 'patient-2',
      fullName: 'Dina Sherif',
      phoneNumber: '01099887766',
      clinic: ClinicLocation.tagamoa,
      createdAt: DateTime(2026),
    );

    final appointment1 = Appointment(
      id: 'appt-1',
      patientId: patient.id,
      type: AppointmentType.normalPtSession,
      scheduledAt: DateTime(2026, 8, 20, 9, 0),
      createdAt: DateTime(2026),
    );

    final appointment2 = Appointment(
      id: 'appt-2',
      patientId: patient.id,
      type: AppointmentType.normalPtSession,
      scheduledAt: DateTime(2026, 8, 20, 21, 0),
      createdAt: DateTime(2026),
    );

    testWidgets('renders dual session standard card on mobile with clock on left, avatar, name, and Dual session subtitle', (
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
            currentUserProvider.overrideWith(() => _StaticCurrentUser(staff)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ReceptionistGroupedAppointmentCard(
                patient: patient,
                items: [
                  AppointmentWithPatient(
                    appointment: appointment1,
                    patient: patient,
                  ),
                  AppointmentWithPatient(
                    appointment: appointment2,
                    patient: patient,
                  ),
                ],
                isCompact: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dina Sherif'), findsOneWidget);
      expect(find.text(AppStrings.dualSession), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('AM'), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz_rounded), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders dual session compact card on mobile without overflow', (
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
            currentUserProvider.overrideWith(() => _StaticCurrentUser(staff)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ReceptionistGroupedAppointmentCard(
                patient: patient,
                items: [
                  AppointmentWithPatient(
                    appointment: appointment1,
                    patient: patient,
                  ),
                  AppointmentWithPatient(
                    appointment: appointment2,
                    patient: patient,
                  ),
                ],
                isCompact: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dina Sherif'), findsOneWidget);
      expect(find.text('09:00 AM'), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz_rounded), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders dual session compact card on wide PC without overflow', (
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
            currentUserProvider.overrideWith(() => _StaticCurrentUser(staff)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ReceptionistGroupedAppointmentCard(
                patient: patient,
                items: [
                  AppointmentWithPatient(
                    appointment: appointment1,
                    patient: patient,
                  ),
                  AppointmentWithPatient(
                    appointment: appointment2,
                    patient: patient,
                  ),
                ],
                isCompact: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dina Sherif'), findsOneWidget);
      expect(find.text('09:00 AM'), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz_rounded), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });

  group('Schedule Day List Auto-Scroll Tests', () {

    test('estimateScheduleScrollOffset correctly calculates offsets for single and grouped items', () {
      final p1 = Patient(
        id: 'p-1',
        fullName: 'Patient 1',
        phoneNumber: '010',
        clinic: ClinicLocation.tagamoa,
        createdAt: DateTime(2026),
      );
      final singleAppt = Appointment(
        id: 'a-1',
        patientId: p1.id,
        type: AppointmentType.normalPtSession,
        scheduledAt: DateTime.now(),
        createdAt: DateTime(2026),
      );
      final singleItem = AppointmentWithPatient(
        appointment: singleAppt,
        patient: p1,
      );

      final rowItems = [
        ScheduleRowItem(patient: p1, appointments: [singleItem]),
        ScheduleRowItem(patient: p1, appointments: [singleItem, singleItem]),
        ScheduleRowItem(patient: p1, appointments: [singleItem]),
      ];

      // Standard mode
      final offsetStd = estimateScheduleScrollOffset(
        rowItems: rowItems,
        nowIndex: 2,
        isCompact: false,
      );
      // Top padding (8) + item 0 (84) + item 1 (91 + 2*40 = 171) - top margin (16) = 8 + 84 + 171 - 16 = 247
      expect(offsetStd, 247.0);

      // Compact mode
      final offsetCmp = estimateScheduleScrollOffset(
        rowItems: rowItems,
        nowIndex: 2,
        isCompact: true,
      );
      // Top padding (8) + item 0 (37) + item 1 (38 + 2*22 = 82) - top margin (16) = 8 + 37 + 82 - 16 = 111
      expect(offsetCmp, 111.0);
    });

    test('estimateDoctorScheduleScrollOffset accurately calculates offset for doctor lists', () {
      final offset = estimateDoctorScheduleScrollOffset(
        nowIndex: 20,
        isCompact: false,
      );
      // Top padding (8) + 20 * 84 - 16 = 8 + 1680 - 16 = 1672
      expect(offset, 1672.0);
    });

    testWidgets('ReceptionistDayList auto-scrolls to now indicator with 30 appointments', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime.now();
      final allItems = <AppointmentWithPatient>[];
      for (int i = 0; i < 30; i++) {
        final p = Patient(
          id: 'patient-$i',
          fullName: 'Patient $i',
          phoneNumber: '010$i',
          clinic: ClinicLocation.tagamoa,
          createdAt: DateTime(2026),
        );
        // First 20 appointments are in the past, next 10 are in the future
        final scheduledTime = i < 20
            ? now.subtract(Duration(hours: 20 - i))
            : now.add(Duration(hours: i - 19));
        allItems.add(
          AppointmentWithPatient(
            appointment: Appointment(
              id: 'appt-$i',
              patientId: p.id,
              type: AppointmentType.normalPtSession,
              scheduledAt: scheduledTime,
              createdAt: DateTime(2026),
            ),
            patient: p,
          ),
        );
      }

      final state = ReceptionistAppointmentsState(
        selectedDate: now,
        allItems: allItems,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReceptionistDayList(
                state: state,
                searchQuery: '',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ScheduleNowIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DoctorDayList auto-scrolls to now indicator with 30 appointments', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime.now();
      final allItems = <AppointmentWithPatient>[];
      for (int i = 0; i < 30; i++) {
        final p = Patient(
          id: 'patient-$i',
          fullName: 'Patient $i',
          phoneNumber: '010$i',
          clinic: ClinicLocation.tagamoa,
          createdAt: DateTime(2026),
        );
        final scheduledTime = i < 20
            ? now.subtract(Duration(hours: 20 - i))
            : now.add(Duration(hours: i - 19));
        allItems.add(
          AppointmentWithPatient(
            appointment: Appointment(
              id: 'appt-$i',
              patientId: p.id,
              type: AppointmentType.normalPtSession,
              scheduledAt: scheduledTime,
              createdAt: DateTime(2026),
            ),
            patient: p,
          ),
        );
      }

      final state = DoctorScheduleState(
        selectedDate: now,
        allItems: allItems,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DoctorDayList(
                state: state,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ScheduleNowIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('DuePatientCard Density & Responsive Layout Tests', () {
    final patient = Patient(
      id: 'patient-due-1',
      fullName: 'Nour El-Din',
      phoneNumber: '01122334455',
      clinic: ClinicLocation.tagamoa,
      createdAt: DateTime(2026),
      nextVisitDate: DateTime.now().add(const Duration(days: 2)),
    );

    final overduePatient = Patient(
      id: 'patient-due-2',
      fullName: 'Farida Tarek',
      phoneNumber: '01233445566',
      clinic: ClinicLocation.tagamoa,
      createdAt: DateTime(2026),
      nextVisitDate: DateTime.now().subtract(const Duration(days: 5)),
    );

    testWidgets('renders standard DuePatientCard with full AppButtons', (
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
          child: MaterialApp(
            home: Scaffold(
              body: DuePatientCard(
                patient: patient,
                referenceDate: DateTime.now(),
                isCompact: false,
                onCall: () {},
                onBook: () {},
                onRemindLater: () {},
                onStopFollowUp: () {},
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Nour El-Din'), findsOneWidget);
      expect(find.text('01122334455'), findsOneWidget);
      expect(find.byType(AppButton), findsNWidgets(2));
      expect(find.text(AppStrings.call), findsOneWidget);
      expect(find.text(AppStrings.book), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders compact DuePatientCard with single-row quick actions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool callTriggered = false;
      bool bookTriggered = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DuePatientCard(
                patient: patient,
                referenceDate: DateTime.now(),
                isCompact: true,
                onCall: () => callTriggered = true,
                onBook: () => bookTriggered = true,
                onRemindLater: () {},
                onStopFollowUp: () {},
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Nour El-Din'), findsOneWidget);
      expect(find.text('01122334455'), findsOneWidget);
      expect(find.byType(AppButton), findsNothing);
      expect(find.byIcon(Icons.call_outlined), findsOneWidget);
      expect(find.byIcon(Icons.event_available_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.call_outlined));
      expect(callTriggered, isTrue);

      await tester.tap(find.byIcon(Icons.event_available_rounded));
      expect(bookTriggered, isTrue);

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders compact overdue patient on narrow mobile screen (360px) cleanly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DuePatientCard(
                patient: overduePatient,
                referenceDate: DateTime.now(),
                isCompact: true,
                onCall: () {},
                onBook: () {},
                onRemindLater: () {},
                onStopFollowUp: () {},
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Farida Tarek'), findsOneWidget);
      expect(find.text('01233445566'), findsOneWidget);
      expect(find.byIcon(Icons.call_outlined), findsOneWidget);
      expect(find.byIcon(Icons.event_available_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders compact overdue patient and wide PC view without overflow', (
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
          child: MaterialApp(
            home: Scaffold(
              body: DuePatientCard(
                patient: overduePatient,
                referenceDate: DateTime.now(),
                isCompact: true,
                onCall: () {},
                onBook: () {},
                onRemindLater: () {},
                onStopFollowUp: () {},
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Farida Tarek'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _StaticCurrentUser extends CurrentUser {
  _StaticCurrentUser(this._user);
  final Staff? _user;

  @override
  Future<Staff?> build() async => _user;
}

