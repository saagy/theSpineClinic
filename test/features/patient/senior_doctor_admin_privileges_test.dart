import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_doctor.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_repository.dart';
import 'package:spine_clinic_app/features/patient/presentation/delete_patient_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/edit_patient_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

class _StaticCurrentUser extends CurrentUser {
  _StaticCurrentUser(this._user);
  final Staff? _user;
  @override
  Future<Staff?> build() async => _user;
}

class _MockPatientRepository implements PatientRepository {
  bool deleteCalled = false;
  bool updateDoctorsCalled = false;
  List<String>? updatedDoctorIds;

  @override
  Future<Result<void>> deletePatient(String id) async {
    deleteCalled = true;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> updatePatient(Patient patient) async {
    return const Result.success(null);
  }

  @override
  Future<Result<void>> updatePatientDoctors(String id, List<String> docIds) async {
    updateDoctorsCalled = true;
    updatedDoctorIds = docIds;
    return const Result.success(null);
  }

  @override
  Future<Result<List<Patient>>> getDuePatients({
    required DateTime date,
    String? doctorId,
    required ClinicLocation clinic,
  }) async =>
      const Result.success([]);

  @override
  Future<Result<List<Patient>>> getAllPatients({
    String? query,
    String? doctorId,
    ClinicLocation? clinic,
    int offset = 0,
    int limit = 30,
    String orderBy = 'full_name',
    bool ascending = true,
  }) async =>
      const Result.success([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockAppointmentRepository implements AppointmentRepository {
  final Appointment appt;
  _MockAppointmentRepository(this.appt);

  @override
  Future<Result<Appointment>> getAppointmentById(String id) async =>
      Result.success(appt);

  @override
  Future<Result<List<AppointmentDoctor>>> getAllAppointmentDoctors(String id) async =>
      const Result.success([]);

  @override
  Future<Result<List<AppointmentDoctor>>> getAppointmentDoctors(String id) async =>
      const Result.success([]);

  @override
  Future<Result<List<AppointmentWithPatient>>> getAllAppointments({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? doctorId,
    String? clinic,
    String? status,
    String? type,
    String? patientQuery,
    int offset = 0,
    int limit = 20,
    bool ascending = true,
  }) async =>
      const Result.success([]);

  @override
  Future<Result<void>> updateAppointmentStatus(String id, AppointmentStatus status) async =>
      const Result.success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final seniorDoc = Staff(
    id: 'senior-doc-1',
    userId: 'user-senior',
    fullName: 'Dr. Senior',
    email: 'senior@clinic.com',
    role: UserRole.doctor,
    branch: ClinicLocation.tagamoa,
    isSenior: true,
    createdAt: DateTime(2026, 1, 1),
  );

  final regularDoc = Staff(
    id: 'regular-doc-1',
    userId: 'user-reg',
    fullName: 'Dr. Regular',
    email: 'reg@clinic.com',
    role: UserRole.doctor,
    branch: ClinicLocation.tagamoa,
    isSenior: false,
    createdAt: DateTime(2026, 1, 1),
  );

  final testPatient = Patient(
    id: 'pat-100',
    fullName: 'Test Patient',
    phoneNumber: '01011112222',
    clinic: ClinicLocation.tagamoa,
    createdAt: DateTime(2026, 1, 1),
  );

  final testAppt = Appointment(
    id: 'appt-100',
    patientId: 'pat-100',
    type: AppointmentType.normalPtSession,
    scheduledAt: DateTime(2026, 9, 15, 10, 0),
    status: AppointmentStatus.scheduled,
    createdAt: DateTime(2026, 1, 1),
  );

  group('Senior Doctor Admin Privileges Tests', () {
    test('Senior doctor can delete a patient via DeletePatientController', () async {
      final mockRepo = _MockPatientRepository();
      final mockApptRepo = _MockAppointmentRepository(testAppt);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(() => _StaticCurrentUser(seniorDoc)),
          patientRepositoryProvider.overrideWithValue(mockRepo),
          appointmentRepositoryProvider.overrideWithValue(mockApptRepo),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);

      final result = await container
          .read(deletePatientControllerProvider.notifier)
          .deletePatient('pat-100');

      expect(result.isSuccess, isTrue);
      expect(mockRepo.deleteCalled, isTrue);
    });

    test('Regular doctor is blocked from deleting a patient', () async {
      final mockRepo = _MockPatientRepository();
      final mockApptRepo = _MockAppointmentRepository(testAppt);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(() => _StaticCurrentUser(regularDoc)),
          patientRepositoryProvider.overrideWithValue(mockRepo),
          appointmentRepositoryProvider.overrideWithValue(mockApptRepo),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);

      final result = await container
          .read(deletePatientControllerProvider.notifier)
          .deletePatient('pat-100');

      expect(result.isFailure, isTrue);
      expect(mockRepo.deleteCalled, isFalse);
    });

    test('Senior doctor can update doctor assignments on patient', () async {
      final mockRepo = _MockPatientRepository();
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(() => _StaticCurrentUser(seniorDoc)),
          patientRepositoryProvider.overrideWithValue(mockRepo),
          patientDetailProvider('pat-100').overrideWith((ref) async => testPatient),
          patientAssignedDoctorsProvider('pat-100').overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);

      final success = await container
          .read(editPatientControllerProvider.notifier)
          .submit(
            patient: testPatient,
            selectedDoctorIds: ['doc-1', 'doc-2'],
            initialDoctorIds: [],
          );

      expect(success, isTrue);
      expect(mockRepo.updateDoctorsCalled, isTrue);
      expect(mockRepo.updatedDoctorIds, ['doc-1', 'doc-2']);
    });

    test('Senior doctor can access unassigned appointment in AppointmentDetailController', () async {
      final mockApptRepo = _MockAppointmentRepository(testAppt);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(() => _StaticCurrentUser(seniorDoc)),
          appointmentRepositoryProvider.overrideWithValue(mockApptRepo),
          patientDetailProvider('pat-100').overrideWith((ref) async => testPatient),
          patientAssignedDoctorsProvider('pat-100').overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);

      final detailState = await container.read(
        appointmentDetailControllerProvider('appt-100').future,
      );

      expect(detailState.appointment.id, 'appt-100');
      expect(detailState.patient.id, 'pat-100');
    });

    test('Regular doctor cannot access unassigned appointment in AppointmentDetailController', () async {
      final mockApptRepo = _MockAppointmentRepository(testAppt);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(() => _StaticCurrentUser(regularDoc)),
          appointmentRepositoryProvider.overrideWithValue(mockApptRepo),
          patientDetailProvider('pat-100').overrideWith((ref) async => testPatient),
          patientAssignedDoctorsProvider('pat-100').overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);

      expect(
        container.read(appointmentDetailControllerProvider('appt-100').future),
        throwsA(anything),
      );
    });
  });
}
