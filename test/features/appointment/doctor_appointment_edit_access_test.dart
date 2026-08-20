import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_doctor.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/edit_appointment_screen.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

void main() {
  final doctorA = Staff(
    id: 'doctor-a',
    userId: 'user-a',
    fullName: 'Dr. Alice',
    email: 'alice@clinic.com',
    role: UserRole.doctor,
    createdAt: DateTime(2026, 1, 1),
  );

  final doctorB = Staff(
    id: 'doctor-b',
    userId: 'user-b',
    fullName: 'Dr. Bob',
    email: 'bob@clinic.com',
    role: UserRole.doctor,
    createdAt: DateTime(2026, 1, 1),
  );

  final receptionist = Staff(
    id: 'rec-1',
    userId: 'user-rec',
    fullName: 'Rita Receptionist',
    email: 'rita@clinic.com',
    role: UserRole.receptionist,
    createdAt: DateTime(2026, 1, 1),
  );

  final patient = Patient(
    id: 'patient-1',
    fullName: 'John Doe',
    phoneNumber: '01000000000',
    clinic: ClinicLocation.tagamoa,
    createdAt: DateTime(2026, 1, 1),
  );

  final nearAppointment = Appointment(
    id: 'appt-near',
    patientId: 'patient-1',
    scheduledAt: DateTime.now().add(const Duration(days: 1)),
    status: AppointmentStatus.scheduled,
    type: AppointmentType.normalPtSession,
    usePackage: true,
    createdAt: DateTime(2026, 1, 1),
  );

  final distantAppointment = Appointment(
    id: 'appt-distant',
    patientId: 'patient-1',
    scheduledAt: DateTime.now().add(const Duration(days: 14)),
    status: AppointmentStatus.scheduled,
    type: AppointmentType.normalPtSession,
    usePackage: true,
    createdAt: DateTime(2026, 1, 1),
  );

  group('canEditAppointment Provider Tests', () {
    test('non-doctor roles (receptionist) can edit any appointment at any time', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            () => _StaticCurrentUser(receptionist),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);

      final canEdit = await container.read(
        canEditAppointmentProvider(
          appointmentId: 'appt-distant',
          patientId: 'patient-1',
        ).future,
      );

      expect(canEdit, isTrue);
    });

    test('assigned doctor can edit appointment even if distant in future (Case 1)', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            () => _StaticCurrentUser(doctorA),
          ),
          patientAssignedDoctorsProvider('patient-1').overrideWith(
            (ref) async => [doctorA],
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);

      final canEdit = await container.read(
        canEditAppointmentProvider(
          appointmentId: 'appt-distant',
          patientId: 'patient-1',
        ).future,
      );

      expect(canEdit, isTrue);
    });

    test('unassigned covering doctor can edit appointment within ±2 days window (Case 2 positive)', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            () => _StaticCurrentUser(doctorB),
          ),
          patientAssignedDoctorsProvider('patient-1').overrideWith(
            (ref) async => [doctorA], // doctorB is NOT assigned to patient
          ),
          appointmentDoctorsProvider('appt-near').overrideWith(
            (ref) async => [
              AppointmentDoctor(
                id: 'ad-1',
                appointmentId: 'appt-near',
                doctorId: 'doctor-b',
                isActive: true,
                addedAt: DateTime(2026, 1, 1),
              ),
            ],
          ),
          singleAppointmentProvider('appt-near').overrideWith(
            (ref) async => nearAppointment,
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);

      final canEdit = await container.read(
        canEditAppointmentProvider(
          appointmentId: 'appt-near',
          patientId: 'patient-1',
        ).future,
      );

      expect(canEdit, isTrue);
    });

    test('unassigned covering doctor CANNOT edit appointment distant in future (Case 2 negative)', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            () => _StaticCurrentUser(doctorB),
          ),
          patientAssignedDoctorsProvider('patient-1').overrideWith(
            (ref) async => [doctorA], // doctorB is NOT assigned to patient
          ),
          appointmentDoctorsProvider('appt-distant').overrideWith(
            (ref) async => [
              AppointmentDoctor(
                id: 'ad-2',
                appointmentId: 'appt-distant',
                doctorId: 'doctor-b',
                isActive: true,
                addedAt: DateTime(2026, 1, 1),
              ),
            ],
          ),
          singleAppointmentProvider('appt-distant').overrideWith(
            (ref) async => distantAppointment,
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);

      final canEdit = await container.read(
        canEditAppointmentProvider(
          appointmentId: 'appt-distant',
          patientId: 'patient-1',
        ).future,
      );

      expect(canEdit, isFalse);
    });
  });

  group('AppointmentDetailScreen Edit Button Visibility', () {
    testWidgets('shows edit button when canEdit is true', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              () => _StaticCurrentUser(doctorA),
            ),
            appointmentDetailControllerProvider('appt-near').overrideWith(
              () => _MockDetailController((
                appointment: nearAppointment,
                patient: patient,
                activeDoctors: [
                  AppointmentDoctorDetail(
                    assignment: AppointmentDoctor(
                      id: 'ad-1',
                      appointmentId: 'appt-near',
                      doctorId: 'doctor-a',
                      isActive: true,
                      addedAt: DateTime(2026, 1, 1),
                    ),
                    doctor: doctorA,
                  ),
                ],
                inactiveDoctors: [],
              )),
            ),
            canEditAppointmentProvider(
              appointmentId: 'appt-near',
              patientId: 'patient-1',
            ).overrideWith((ref) async => true),
            canAccessAppointmentProvider(
              appointmentId: 'appt-near',
              patientId: 'patient-1',
            ).overrideWith((ref) async => true),
            canAccessPatientProvider('patient-1').overrideWith(
              (ref) async => true,
            ),
          ],
          child: const MaterialApp(
            home: AppointmentDetailScreen(appointmentId: 'appt-near'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('hides edit button when canEdit is false for doctor outside window', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              () => _StaticCurrentUser(doctorB),
            ),
            appointmentDetailControllerProvider('appt-distant').overrideWith(
              () => _MockDetailController((
                appointment: distantAppointment,
                patient: patient,
                activeDoctors: [
                  AppointmentDoctorDetail(
                    assignment: AppointmentDoctor(
                      id: 'ad-2',
                      appointmentId: 'appt-distant',
                      doctorId: 'doctor-b',
                      isActive: true,
                      addedAt: DateTime(2026, 1, 1),
                    ),
                    doctor: doctorB,
                  ),
                ],
                inactiveDoctors: [],
              )),
            ),
            canEditAppointmentProvider(
              appointmentId: 'appt-distant',
              patientId: 'patient-1',
            ).overrideWith((ref) async => false),
            canAccessAppointmentProvider(
              appointmentId: 'appt-distant',
              patientId: 'patient-1',
            ).overrideWith((ref) async => true),
            canAccessPatientProvider('patient-1').overrideWith(
              (ref) async => false,
            ),
          ],
          child: const MaterialApp(
            home: AppointmentDetailScreen(appointmentId: 'appt-distant'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });
  });

  group('EditAppointmentScreen Permission Denied Guard', () {
    testWidgets('renders ErrorView when doctor is outside edit window', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              () => _StaticCurrentUser(doctorB),
            ),
            appointmentDetailControllerProvider('appt-distant').overrideWith(
              () => _MockDetailController((
                appointment: distantAppointment,
                patient: patient,
                activeDoctors: [
                  AppointmentDoctorDetail(
                    assignment: AppointmentDoctor(
                      id: 'ad-2',
                      appointmentId: 'appt-distant',
                      doctorId: 'doctor-b',
                      isActive: true,
                      addedAt: DateTime(2026, 1, 1),
                    ),
                    doctor: doctorB,
                  ),
                ],
                inactiveDoctors: [],
              )),
            ),
            canEditAppointmentProvider(
              appointmentId: 'appt-distant',
              patientId: 'patient-1',
            ).overrideWith((ref) async => false),
          ],
          child: const MaterialApp(
            home: EditAppointmentScreen(appointmentId: 'appt-distant'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);
    });
  });
}

class _StaticCurrentUser extends CurrentUser {
  _StaticCurrentUser(this._user);
  final Staff? _user;

  @override
  Future<Staff?> build() async => _user;
}

class _MockDetailController extends AppointmentDetailController {
  _MockDetailController(this._state);
  final AppointmentDetailState _state;

  @override
  Future<AppointmentDetailState> build(String appointmentId) async => _state;
}
