import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_doctor.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

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

  test('non-doctor roles (receptionist / admin) have full access to any appointment', () async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(
          () => _StaticCurrentUser(receptionist),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);

    final canAccess = await container.read(
      canAccessAppointmentProvider(
        appointmentId: 'appt-99',
        patientId: 'patient-99',
      ).future,
    );

    expect(canAccess, isTrue);
  });

  test('doctor assigned to patient has access to all patient appointments (Case 1)', () async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(
          () => _StaticCurrentUser(doctorA),
        ),
        patientAssignedDoctorsProvider('patient-1').overrideWith(
          (ref) async => [doctorA],
        ),
        appointmentDoctorsProvider('appt-unassigned').overrideWith(
          (ref) async => [],
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);

    final canAccess = await container.read(
      canAccessAppointmentProvider(
        appointmentId: 'appt-unassigned',
        patientId: 'patient-1',
      ).future,
    );

    expect(canAccess, isTrue);
  });

  test('doctor assigned to appointment has access even if not assigned to patient (Case 2)', () async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(
          () => _StaticCurrentUser(doctorA),
        ),
        patientAssignedDoctorsProvider('patient-other').overrideWith(
          (ref) async => [doctorB],
        ),
        appointmentDoctorsProvider('appt-assigned-to-a').overrideWith(
          (ref) async => [
            AppointmentDoctor(
              id: 'ad-1',
              appointmentId: 'appt-assigned-to-a',
              doctorId: 'doctor-a',
              isActive: true,
              addedAt: DateTime(2026, 8, 1),
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);

    final canAccess = await container.read(
      canAccessAppointmentProvider(
        appointmentId: 'appt-assigned-to-a',
        patientId: 'patient-other',
      ).future,
    );

    expect(canAccess, isTrue);
  });

  test('doctor is denied access if neither assigned to patient nor to appointment', () async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(
          () => _StaticCurrentUser(doctorA),
        ),
        patientAssignedDoctorsProvider('patient-other').overrideWith(
          (ref) async => [doctorB],
        ),
        appointmentDoctorsProvider('appt-assigned-to-b').overrideWith(
          (ref) async => [
            AppointmentDoctor(
              id: 'ad-2',
              appointmentId: 'appt-assigned-to-b',
              doctorId: 'doctor-b',
              isActive: true,
              addedAt: DateTime(2026, 8, 1),
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);

    final canAccess = await container.read(
      canAccessAppointmentProvider(
        appointmentId: 'appt-assigned-to-b',
        patientId: 'patient-other',
      ).future,
    );

    expect(canAccess, isFalse);
  });

  test('isDoctorAssignedToPatient correctly checks patient assignment', () async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(
          () => _StaticCurrentUser(doctorA),
        ),
        patientAssignedDoctorsProvider('patient-1').overrideWith(
          (ref) async => [doctorA],
        ),
        patientAssignedDoctorsProvider('patient-2').overrideWith(
          (ref) async => [doctorB],
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);

    final isAssignedTo1 = await container.read(
      isDoctorAssignedToPatientProvider('patient-1').future,
    );
    final isAssignedTo2 = await container.read(
      isDoctorAssignedToPatientProvider('patient-2').future,
    );

    expect(isAssignedTo1, isTrue);
    expect(isAssignedTo2, isFalse);
  });
}

class _StaticCurrentUser extends CurrentUser {
  _StaticCurrentUser(this._user);
  final Staff? _user;

  @override
  Future<Staff?> build() async => _user;
}
