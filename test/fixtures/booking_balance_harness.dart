import 'package:spine_clinic_app/features/appointment/presentation/pending_booking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/new_appointment_form.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

class _FakeAppointmentRepo implements AppointmentRepository {
  _FakeAppointmentRepo({this.assignedDoctors = const []});

  final List<Staff> assignedDoctors;

  @override
  Future<Result<List<Staff>>> getAssignedDoctors(String patientId) async =>
      Result.success(assignedDoctors);

  @override
  Future<Result<int>> getFutureScheduledAppointmentsCountForType({
    required String patientId,
    required AppointmentType type,
  }) async => const Result.success(0);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestCurrentUser extends CurrentUser {
  _TestCurrentUser(this.staff);
  final Staff staff;

  @override
  Future<Staff?> build() async => staff;
}

final _testPatient = Patient(
  id: '11111111-1111-1111-1111-111111111111',
  fullName: 'Test Patient',
  phoneNumber: '07700000000',
  sessionBalance: 3,
  tractionBalance: 2,
  clinic: ClinicLocation.tagamoa,
  createdAt: DateTime(2026),
);

final bookingTestStaff = Staff(
  id: '22222222-2222-2222-2222-222222222222',
  fullName: 'Receptionist User',
  email: 'receptionist@spine.com',
  role: UserRole.receptionist,
  isActive: true,
  createdAt: DateTime(2026),
);

Widget buildBookingBalanceHarness({
  List<Staff> assignedDoctors = const [],
  bool pendingRetry = false,
}) {
  return ProviderScope(
    overrides: [
      pendingBookingProvider(
        _testPatient.id,
      ).overrideWith((ref) async => pendingRetry),
      appointmentRepositoryProvider.overrideWithValue(
        _FakeAppointmentRepo(assignedDoctors: assignedDoctors),
      ),
      patientDetailProvider(
        _testPatient.id,
      ).overrideWith((ref) => Future.value(_testPatient)),
      currentUserProvider.overrideWith(
        () => _TestCurrentUser(bookingTestStaff),
      ),
      availableBalanceForTypeProvider((
        patientId: _testPatient.id,
        type: AppointmentType.normalPtSession,
      )).overrideWith((ref) => Future.value(3)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: NewAppointmentForm(
          preselectedPatientId: _testPatient.id,
          preselectedDate: DateTime(2026, 9, 1),
        ),
      ),
    ),
  );
}
