import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_patient_search_provider.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_repository.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import '../../fixtures/workspace_data.dart';
import '../../fixtures/schedule_repo.dart';

class PatientRepo implements PatientRepository {
  final calls = <Invocation>[];
  @override
  Future<Result<List<Patient>>> noSuchMethod(Invocation call) async {
    calls.add(call);
    return Result.success(List.filled(30, workspacePatient));
  }
}

void main() {
  test(
    'branch switch reloads and discards the previous branch request',
    () async {
      final repo = ScheduleRepo();
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(TestUser.new),
          activeBranchProvider.overrideWith(TestBranch.new),
          appointmentRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(receptionistAppointmentsProvider, (_, _) {});
      await settle(container);
      expect(repo.calls.last.namedArguments[#clinic], 'tagamoa');
      await container
          .read(activeBranchProvider.notifier)
          .setBranch(ClinicLocation.masrElgedida);
      await settle(container);
      expect(repo.calls.last.namedArguments[#clinic], 'masr_elgedida');
      repo.pending.first.complete(const Result.success([]));
      await settle(container);
      expect(container.read(receptionistAppointmentsProvider).loading, true);
      repo.pending.last.complete(const Result.success([]));
      await settle(container);
      expect(container.read(receptionistAppointmentsProvider).loading, false);
      final notifier = container.read(
        receptionistAppointmentsProvider.notifier,
      );
      final selected = DateTime.now().add(const Duration(days: 20));
      notifier.selectDate(selected);
      await settle(container);
      repo.pending.last.complete(const Result.success([]));
      await settle(container);
      final previousDate = container
          .read(receptionistAppointmentsProvider)
          .selectedDate;
      final before = repo.calls.length;
      container.invalidate(receptionistAppointmentsProvider);
      await settle(container);
      expect(repo.calls.length, before + 1);
      expect(
        container.read(receptionistAppointmentsProvider).selectedDate,
        previousDate,
      );
      final booked = AppointmentWithPatient(
        patient: workspacePatient,
        appointment: Appointment(
          id: 'new-booking',
          patientId: workspacePatient.id,
          type: AppointmentType.normalPtSession,
          scheduledAt: selected,
          createdAt: DateTime.now(),
        ),
      );
      repo.pending.last.complete(Result.success([booked]));
      await settle(container);
      expect(container.read(receptionistAppointmentsProvider).loading, false);
      expect(
        container.read(receptionistAppointmentsProvider).itemsForSelectedDay,
        [booked],
      );
    },
  );

  test('doctor schedule invalidation reloads for the same user', () async {
    final repo = ScheduleRepo();
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(TestUser.new),
        appointmentRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    container.listen(doctorScheduleProvider, (_, _) {});
    await settle(container);
    repo.pending.last.complete(const Result.success([]));
    await settle(container);
    container.invalidate(doctorScheduleProvider);
    await settle(container);
    expect(repo.calls.length, 2);
    repo.pending.last.complete(const Result.success([]));
    await settle(container);
    expect(container.read(doctorScheduleProvider).loading, false);
  });

  test(
    'booking search scopes every page and resets on branch switch',
    () async {
      final repo = PatientRepo();
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(TestUser.new),
          activeBranchProvider.overrideWith(TestBranch.new),
          patientRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      final provider = bookingPatientSearchProvider(' Nour ');
      container.listen(provider, (_, _) {});
      await container.read(provider.future);
      await container.read(provider.notifier).loadMore();
      expect(
        repo.calls.map((call) => call.namedArguments[#clinic]),
        everyElement(ClinicLocation.tagamoa),
      );
      expect(repo.calls.last.namedArguments[#offset], 30);
      expect(repo.calls.last.namedArguments[#query], 'Nour');
      await container
          .read(activeBranchProvider.notifier)
          .setBranch(ClinicLocation.masrElgedida);
      await container.read(provider.future);
      expect(
        repo.calls.last.namedArguments[#clinic],
        ClinicLocation.masrElgedida,
      );
      expect(repo.calls.last.namedArguments[#offset], 0);
      expect(container.read(provider).requireValue.length, 30);
    },
  );
}
