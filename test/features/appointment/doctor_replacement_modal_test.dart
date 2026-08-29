import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/domain/bulk_doctor_replacement_result.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_replacement_args.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_replacement_screen.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';

class _FakeAppointmentRepository implements AppointmentRepository {
  List<String>? submittedDoctors;
  List<String>? submittedAppointments;

  @override
  Future<Result<BulkDoctorReplacementResult>> bulkReplaceDoctor({
    required String absentDoctorId,
    required List<String> replacementDoctorIds,
    required List<String> appointmentIds,
    required DateTime day,
  }) async {
    submittedDoctors = replacementDoctorIds;
    submittedAppointments = appointmentIds;
    return const Result.success(
      BulkDoctorReplacementResult(replacedCount: 1, remainingCount: 1),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('replacement preselects all and submits the chosen subset', (
    tester,
  ) async {
    final fakeRepo = _FakeAppointmentRepository();
    final Patient patient = _patient();
    final List<AppointmentWithPatient> appointments = [
      _appointment('appointment-1', patient, 9),
      _appointment('appointment-2', patient, 10),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appointmentRepositoryProvider.overrideWithValue(fakeRepo),
          activeDoctorsProvider.overrideWith((ref) => [
            _doctor('replacement', 'Dr Replacement'),
            _doctor('absent', 'Dr Absent'),
          ]),
          allDoctorsForFilterProvider.overrideWith((ref) => [
            _doctor('replacement', 'Dr Replacement'),
            _doctor('absent', 'Dr Absent'),
          ]),
        ],
        child: MaterialApp(
          home: DoctorReplacementScreen(
            args: DoctorReplacementArgs(
              absentDoctor: _doctor('absent', 'Dr Absent'),
              availableDoctors: [_doctor('replacement', 'Dr Replacement')],
              appointments: appointments,
              day: DateTime(2026, 7, 14),
            ),
          ),
        ),
      ),
    );

    final List<Checkbox> initial = tester
        .widgetList<Checkbox>(find.byType(Checkbox))
        .toList();
    expect(initial, hasLength(3));
    expect(initial.every((checkbox) => checkbox.value == true), isTrue);

    await tester.tap(find.text(AppStrings.selectReplacementDoctors));
    await tester.pumpAndSettle();

    // Select Dr Replacement directly in the picker sheet
    await tester.tap(find.text('Dr Replacement'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();
    await tester.tap(find.text(AppStrings.replaceOnAppointments(1)));
    await tester.pumpAndSettle();

    expect(fakeRepo.submittedDoctors, ['replacement']);
    expect(fakeRepo.submittedAppointments, ['appointment-1']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replacement screen back button pops route cleanly', (
    tester,
  ) async {
    final fakeRepo = _FakeAppointmentRepository();
    final Patient patient = _patient();
    final List<AppointmentWithPatient> appointments = [
      _appointment('appointment-1', patient, 9),
    ];
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push(
                AppRoutes.doctorReplacement,
                extra: DoctorReplacementArgs(
                  absentDoctor: _doctor('absent', 'Dr Absent'),
                  availableDoctors: [_doctor('replacement', 'Dr Replacement')],
                  appointments: appointments,
                  day: DateTime(2026, 7, 14),
                ),
              ),
              child: const Text('Go Replace'),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.doctorReplacement,
          builder: (_, state) => DoctorReplacementScreen(
            args: state.extra as DoctorReplacementArgs?,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appointmentRepositoryProvider.overrideWithValue(fakeRepo),
          allDoctorsForFilterProvider.overrideWith((ref) => [
            _doctor('replacement', 'Dr Replacement'),
            _doctor('absent', 'Dr Absent'),
          ]),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('Go Replace'));
    await tester.pumpAndSettle();

    expect(find.byType(DoctorReplacementScreen), findsOneWidget);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(find.byType(DoctorReplacementScreen), findsNothing);
    expect(find.text('Go Replace'), findsOneWidget);
  });
}

Staff _doctor(String id, String name) => Staff(
  id: id,
  fullName: name,
  email: '$id@clinic.test',
  role: UserRole.doctor,
  branch: ClinicLocation.tagamoa,
  createdAt: DateTime(2026),
);

Patient _patient() => Patient(
  id: 'patient-1',
  fullName: 'Mariam Hassan',
  phoneNumber: '01000000000',
  clinic: ClinicLocation.tagamoa,
  createdAt: DateTime(2026),
);

AppointmentWithPatient _appointment(String id, Patient patient, int hour) {
  return AppointmentWithPatient(
    appointment: Appointment(
      id: id,
      patientId: patient.id,
      type: AppointmentType.normalPtSession,
      status: AppointmentStatus.scheduled,
      scheduledAt: DateTime(2026, 7, 14, hour),
      createdAt: DateTime(2026),
    ),
    patient: patient,
  );
}
