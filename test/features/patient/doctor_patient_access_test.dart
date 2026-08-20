import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_detail_header.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_notes_list_state.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_notes_list_notifier.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_appointments_state.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_documents_repository.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_repository.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_detail_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/error_scaffold.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_profile.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';

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

  group('canAccessPatient Provider Tests', () {
    test('non-doctor roles (receptionist / superAdmin) have full access to any patient', () async {
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
        canAccessPatientProvider('patient-1').future,
      );

      expect(canAccess, isTrue);
    });

    test('doctor assigned to patient has full access at all times (Case 1)', () async {
      final mockRepo = _MockPatientRepository(canAccessResult: true);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            () => _StaticCurrentUser(doctorA),
          ),
          patientRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);

      final canAccess = await container.read(
        canAccessPatientProvider('patient-1').future,
      );

      expect(canAccess, isTrue);
      expect(mockRepo.lastPatientId, 'patient-1');
      expect(mockRepo.lastDoctorId, 'doctor-a');
    });

    test('doctor not assigned and outside appointment window is denied (Case 2 negative)', () async {
      final mockRepo = _MockPatientRepository(canAccessResult: false);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            () => _StaticCurrentUser(doctorB),
          ),
          patientRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);

      final canAccess = await container.read(
        canAccessPatientProvider('patient-1').future,
      );

      expect(canAccess, isFalse);
    });
  });

  group('Appointment ±2 Days Window Calculation Tests', () {
    bool isWithinTwoDaysWindow(DateTime appointmentTime, DateTime currentTime) {
      final apptDate = DateUtils.dateOnly(appointmentTime.toLocal());
      final nowDate = DateUtils.dateOnly(currentTime.toLocal());
      final diffDays = (nowDate.difference(apptDate).inDays).abs();
      return diffDays <= 2;
    }

    final appt = DateTime(2026, 8, 20, 14, 30);

    test('is true 2 days before appointment', () {
      expect(isWithinTwoDaysWindow(appt, DateTime(2026, 8, 18, 9, 0)), isTrue);
    });

    test('is true 1 day before appointment', () {
      expect(isWithinTwoDaysWindow(appt, DateTime(2026, 8, 19, 23, 59)), isTrue);
    });

    test('is true day of appointment', () {
      expect(isWithinTwoDaysWindow(appt, DateTime(2026, 8, 20, 10, 0)), isTrue);
    });

    test('is true 1 day after appointment', () {
      expect(isWithinTwoDaysWindow(appt, DateTime(2026, 8, 21, 8, 0)), isTrue);
    });

    test('is true 2 days after appointment', () {
      expect(isWithinTwoDaysWindow(appt, DateTime(2026, 8, 22, 23, 59)), isTrue);
    });

    test('is false 3 days before appointment', () {
      expect(isWithinTwoDaysWindow(appt, DateTime(2026, 8, 17, 23, 59)), isFalse);
    });

    test('is false 3 days after appointment', () {
      expect(isWithinTwoDaysWindow(appt, DateTime(2026, 8, 23, 0, 0)), isFalse);
    });
  });

  group('PatientDetailScreen Access Control Widget Tests', () {
    testWidgets('renders patient profile when access is granted', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              () => _StaticCurrentUser(doctorA),
            ),
            canAccessPatientProvider('patient-1').overrideWith(
              (ref) async => true,
            ),
            patientDetailProvider('patient-1').overrideWith(
              (ref) async => patient,
            ),
            patientAssignedDoctorsProvider('patient-1').overrideWith(
              (ref) async => [doctorA],
            ),
            patientIsEmptyProvider('patient-1').overrideWith(
              (ref) async => false,
            ),
            patientAppointmentsProvider('patient-1').overrideWith(
              () => _MockPatientAppointments(),
            ),
            patientPaymentsProvider('patient-1').overrideWith(
              (ref) async => <PaymentRecord>[],
            ),
            patientNotesListProvider('patient-1').overrideWith(
              () => _MockPatientNotesList(),
            ),
            patientDocumentsRepositoryProvider.overrideWithValue(
              _MockDocumentsRepository(),
            ),
          ],
          child: const MaterialApp(
            home: PatientDetailScreen(patientId: 'patient-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PatientProfile), findsOneWidget);
      expect(find.text('John Doe'), findsWidgets);
      expect(find.byType(PatientErrorScaffold), findsNothing);
    });

    testWidgets('renders PatientErrorScaffold when doctor access is denied', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              () => _StaticCurrentUser(doctorB),
            ),
            canAccessPatientProvider('patient-1').overrideWith(
              (ref) async => false,
            ),
            patientDetailProvider('patient-1').overrideWith(
              (ref) async => patient,
            ),
          ],
          child: const MaterialApp(
            home: PatientDetailScreen(patientId: 'patient-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PatientErrorScaffold), findsOneWidget);
      expect(find.byType(PatientProfile), findsNothing);
    });
  });

  group('AppointmentDetailHeader Access Control Tests', () {
    testWidgets('shows permission denied snackbar on denied patient tap for doctor', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              () => _StaticCurrentUser(doctorB),
            ),
            canAccessPatientProvider('patient-1').overrideWith(
              (ref) async => false,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AppointmentDetailHeader(patient: patient),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('John Doe'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}

class _StaticCurrentUser extends CurrentUser {
  _StaticCurrentUser(this._user);
  final Staff? _user;

  @override
  Future<Staff?> build() async => _user;
}

class _MockPatientRepository implements PatientRepository {
  _MockPatientRepository({required this.canAccessResult});
  final bool canAccessResult;
  String? lastPatientId;
  String? lastDoctorId;

  @override
  Future<Result<bool>> canDoctorAccessPatient({
    required String patientId,
    required String doctorId,
  }) async {
    lastPatientId = patientId;
    lastDoctorId = doctorId;
    return Result.success(canAccessResult);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockPatientAppointments extends PatientAppointments {
  @override
  PatientAppointmentsState build(String patientId) {
    return const PatientAppointmentsState(
      appointments: [],
      totalCount: 0,
      isLoading: false,
    );
  }
}

class _MockPatientNotesList extends PatientNotesList {
  @override
  PatientNotesListState build(String patientId) {
    return const PatientNotesListState(
      notes: [],
      totalCount: 0,
      isLoading: false,
    );
  }
}

class _MockDocumentsRepository implements PatientDocumentsRepository {
  @override
  Future<Result<List<PatientDocument>>> fetchDocuments(String patientId) async =>
      const Result.success(<PatientDocument>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
