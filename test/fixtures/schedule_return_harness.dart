import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'schedule_repo.dart';
import 'workspace_data.dart';

/// Runs identical freshness/race tests against both real schedule notifiers.
class ScheduleReturnHarness {
  ScheduleReturnHarness(this.doctor) {
    container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(TestUser.new),
        activeBranchProvider.overrideWith(TestBranch.new),
        appointmentRepositoryProvider.overrideWithValue(repo),
        doctorScheduleProvider.overrideWith(
          () => DoctorScheduleNotifier(now: () => now),
        ),
        receptionistAppointmentsProvider.overrideWith(
          () => ReceptionistAppointmentsNotifier(now: () => now),
        ),
      ],
    );
    if (doctor) {
      container.listen(doctorScheduleProvider, (_, _) {});
    } else {
      container.listen(receptionistAppointmentsProvider, (_, _) {});
    }
  }

  final bool doctor;
  final repo = ScheduleRepo();
  DateTime now = DateTime(2026, 9, 27, 10);
  late final ProviderContainer container;
  DoctorScheduleNotifier get _doctor =>
      container.read(doctorScheduleProvider.notifier);
  ReceptionistAppointmentsNotifier get _reception =>
      container.read(receptionistAppointmentsProvider.notifier);

  Future<void> refresh() =>
      doctor ? _doctor.refreshIfStale() : _reception.refreshIfStale();
  Future<void> settle() => container.pump().then((_) async {
    await Future<void>.delayed(Duration.zero);
    await container.pump();
  });
  void advance(int seconds) => now = now.add(Duration(seconds: seconds));
  void select(DateTime date) =>
      doctor ? _doctor.selectDate(date) : _reception.selectDate(date);
  void checkIn() => doctor
      ? _doctor.changeStatus('a', AppointmentStatus.checkedIn)
      : _reception.changeStatus('a', AppointmentStatus.checkedIn);
  void toggleCancelled() =>
      doctor ? _doctor.toggleShowCancelled() : _reception.toggleShowCancelled();

  List<AppointmentWithPatient> get items => doctor
      ? container.read(doctorScheduleProvider).allItems
      : container.read(receptionistAppointmentsProvider).allItems;
  bool get loading => doctor
      ? container.read(doctorScheduleProvider).loading
      : container.read(receptionistAppointmentsProvider).loading;
  Object? get error => doctor
      ? container.read(doctorScheduleProvider).error
      : container.read(receptionistAppointmentsProvider).error;
  bool get showCancelled => doctor
      ? container.read(doctorScheduleProvider).showCancelled
      : container.read(receptionistAppointmentsProvider).showCancelled;
  DateTime get selected => (doctor
      ? container.read(doctorScheduleProvider).selectedDate
      : container.read(receptionistAppointmentsProvider).selectedDate)!;
}

AppointmentWithPatient scheduleItem(String id) => AppointmentWithPatient(
  patient: workspacePatient,
  doctorNames: const ['Dr. Test'],
  appointment: Appointment(
    id: id,
    patientId: workspacePatient.id,
    type: AppointmentType.normalPtSession,
    scheduledAt: DateTime.now(),
    createdAt: DateTime(2026),
  ),
);
