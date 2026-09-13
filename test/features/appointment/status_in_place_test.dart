import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_with_patient.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_provider.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_state.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_appointments_state.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import '../../fixtures/workspace_data.dart';

final items = List.generate(
  60,
  (i) => AppointmentWithPatient(
    patient: workspacePatient,
    doctorNames: const ['Dr. Mariam', 'Dr. Omar'],
    appointment: Appointment(
      id: 'a$i',
      patientId: workspacePatient.id,
      type: AppointmentType.normalPtSession,
      scheduledAt: DateTime(2026, 9, 13),
      createdAt: DateTime(2026),
    ),
  ),
);

class AllData extends AllAppointmentsNotifier {
  @override
  Future<List<AppointmentWithPatient>> build() async => items;
}

class PatientData extends PatientAppointments {
  PatientData(this.filtered);
  final bool filtered;
  @override
  PatientAppointmentsState build(String patientId) => PatientAppointmentsState(
    appointments: items,
    totalCount: 65,
    hasMore: true,
    isLoading: false,
    statusFilter: filtered ? {AppointmentStatus.scheduled} : null,
  );
}

class BranchData extends ActiveBranch {
  @override
  ClinicLocation build() => ClinicLocation.tagamoa;
}

class NoUser extends CurrentUser {
  @override
  Future<Staff?> build() async => null;
}

class BookingData extends BookingWorkboard {
  @override
  BookingWorkboardState build() => super.build().copyWith(
    schedule: items,
    duePatients: [workspacePatient],
    scheduleLoading: false,
    dueLoading: false,
  );
}

void main() {
  test('All patches one row without losing loaded pages or doctor metadata', () async {
    final container = ProviderContainer(
      overrides: [allAppointmentsProvider.overrideWith(AllData.new)],
    );
    addTearDown(container.dispose);
    await container.read(allAppointmentsProvider.future);
    container
        .read(allAppointmentsProvider.notifier)
        .updateStatus('a32', AppointmentStatus.checkedIn);
    final result = container.read(allAppointmentsProvider);
    expect(result.isLoading, false);
    expect(result.requireValue.length, 60);
    expect(result.requireValue[32].appointment.status, AppointmentStatus.checkedIn);
    expect(result.requireValue[32].doctorNames, items[32].doctorNames);
    expect(identical(result.requireValue[31], items[31]), true);
  });
  for (final filtered in [false, true]) {
    test('Patient retains pagination and respects status filter=$filtered', () {
      final provider = patientAppointmentsProvider(workspacePatient.id);
      final container = ProviderContainer(
        overrides: [provider.overrideWith(() => PatientData(filtered))],
      );
      addTearDown(container.dispose);
      container.listen(provider, (_, _) {});
      container.read(provider.notifier).changeStatus('a32', AppointmentStatus.checkedIn);
      final result = container.read(provider);
      expect(result.isLoading, false);
      expect(result.appointments.length, filtered ? 59 : 60);
      expect(result.totalCount, filtered ? 64 : 65);
      expect(result.hasMore, true);
      expect(result.statusFilter, filtered ? {AppointmentStatus.scheduled} : null);
    });
  }
  test('Booking changes status while retaining both panes and selected date', () {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(NoUser.new),
        activeBranchProvider.overrideWith(BranchData.new),
        bookingWorkboardProvider.overrideWith(BookingData.new),
      ],
    );
    addTearDown(container.dispose);
    container.listen(bookingWorkboardProvider, (_, _) {});
    final before = container.read(bookingWorkboardProvider);
    container
        .read(bookingWorkboardProvider.notifier)
        .changeStatus('a32', AppointmentStatus.checkedIn);
    final after = container.read(bookingWorkboardProvider);
    expect(after.scheduleLoading, false);
    expect(after.dueLoading, false);
    expect(after.date, before.date);
    expect(after.duePatients, before.duePatients);
    expect(after.schedule.length, 60);
    expect(after.schedule[32].appointment.status, AppointmentStatus.checkedIn);
  });
}
