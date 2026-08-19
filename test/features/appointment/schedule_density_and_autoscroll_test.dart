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
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_grouped_appointment_card.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

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

      expect(find.text('Dina Sherif'), findsOneWidget);
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

      expect(find.text('Dina Sherif'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Schedule Day List Auto-Scroll Tests', () {
    final patient = Patient(
      id: 'patient-1',
      fullName: 'Youssef Nabil',
      phoneNumber: '01012345678',
      clinic: ClinicLocation.tagamoa,
      createdAt: DateTime(2026),
    );

    final appointmentPast = Appointment(
      id: 'appointment-1',
      patientId: patient.id,
      type: AppointmentType.normalPtSession,
      scheduledAt: DateTime.now().subtract(const Duration(hours: 2)),
      createdAt: DateTime(2026),
    );

    final appointmentFuture = Appointment(
      id: 'appointment-2',
      patientId: patient.id,
      type: AppointmentType.normalPtSession,
      scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      createdAt: DateTime(2026),
    );

    testWidgets('ReceptionistDayList mounts and renders now indicator for today', (
      tester,
    ) async {
      final state = ReceptionistAppointmentsState(
        selectedDate: DateTime.now(),
        allItems: [
          AppointmentWithPatient(
            appointment: appointmentPast,
            patient: patient,
          ),
          AppointmentWithPatient(
            appointment: appointmentFuture,
            patient: patient,
          ),
        ],
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

    testWidgets('DoctorDayList mounts and renders now indicator for today', (
      tester,
    ) async {
      final state = DoctorScheduleState(
        selectedDate: DateTime.now(),
        allItems: [
          AppointmentWithPatient(
            appointment: appointmentPast,
            patient: patient,
          ),
          AppointmentWithPatient(
            appointment: appointmentFuture,
            patient: patient,
          ),
        ],
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
}
