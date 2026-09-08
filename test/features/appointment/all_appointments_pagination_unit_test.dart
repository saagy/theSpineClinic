import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

class _MockAppointmentRepo implements AppointmentRepository {
  _MockAppointmentRepo(this.totalCount);
  final int totalCount;

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
    int limit = 30,
    bool ascending = false,
  }) async {
    final now = DateTime.now();
    final count = (totalCount - offset).clamp(0, limit);
    final items = List.generate(
      count,
      (i) => AppointmentWithPatient(
        appointment: Appointment(
          id: 'appt-${offset + i}',
          patientId: 'patient-${offset + i}',
          type: AppointmentType.normalPtSession,
          scheduledAt: now,
          createdAt: now,
        ),
        patient: Patient(
          id: 'patient-${offset + i}',
          fullName: 'Patient ${offset + i}',
          phoneNumber: '0100000000',
          clinic: ClinicLocation.tagamoa,
          createdAt: now,
        ),
      ),
    );
    return Result.success(items);
  }

  @override
  Future<Result<int>> countAllAppointments({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? doctorId,
    String? clinic,
    String? status,
    String? type,
    String? patientQuery,
  }) async =>
      Result.success(totalCount);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestCurrentUser extends CurrentUser {
  @override
  Future<Staff?> build() async => Staff(
        id: 'user-admin',
        fullName: 'Admin User',
        email: 'admin@test.com',
        role: UserRole.superAdmin,
        createdAt: DateTime(2026),
      );
}

void main() {
  group('AllAppointmentsNotifier pagination', () {
    testWidgets('calculates pages and navigates through pages correctly',
        (tester) async {
      final repo = _MockAppointmentRepo(75);
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(_TestCurrentUser.new),
            appointmentRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                final state = ref.watch(allAppointmentsProvider);
                return Text('Count: ${state.value?.length ?? 0}');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final notifier = capturedRef.read(allAppointmentsProvider.notifier);
      expect(notifier.totalCount, 75);
      expect(notifier.pageSize, 30);
      expect(notifier.currentPage, 1);
      expect(notifier.totalPages, 3);
      expect(notifier.hasPreviousPage, isFalse);
      expect(notifier.hasNextPage, isTrue);
      expect(find.text('Count: 30'), findsOneWidget);

      // Navigate to Next page (page 2)
      await notifier.nextPage();
      await tester.pumpAndSettle();

      expect(notifier.currentPage, 2);
      expect(notifier.hasPreviousPage, isTrue);
      expect(notifier.hasNextPage, isTrue);
      expect(find.text('Count: 30'), findsOneWidget);

      // Navigate to Next page (page 3 - last page, 15 items)
      await notifier.nextPage();
      await tester.pumpAndSettle();

      expect(notifier.currentPage, 3);
      expect(notifier.hasPreviousPage, isTrue);
      expect(notifier.hasNextPage, isFalse);
      expect(find.text('Count: 15'), findsOneWidget);

      // Navigate back to page 2 via previousPage
      await notifier.previousPage();
      await tester.pumpAndSettle();

      expect(notifier.currentPage, 2);
      expect(notifier.hasPreviousPage, isTrue);
      expect(notifier.hasNextPage, isTrue);

      // Navigate directly to page 1 via goToPage
      await notifier.goToPage(1);
      await tester.pumpAndSettle();

      expect(notifier.currentPage, 1);
      expect(notifier.hasPreviousPage, isFalse);
      expect(notifier.hasNextPage, isTrue);
    });
  });
}
