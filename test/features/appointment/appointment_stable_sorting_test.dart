import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_with_patient.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_state.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

void main() {
  final patientA = Patient(
    id: 'pat-1',
    fullName: 'Ahmed Ali',
    phoneNumber: '01000000001',
    clinic: ClinicLocation.tagamoa,
    createdAt: DateTime(2026, 1, 1),
  );

  final patientB = Patient(
    id: 'pat-2',
    fullName: 'Bassem Emad',
    phoneNumber: '01000000002',
    clinic: ClinicLocation.tagamoa,
    createdAt: DateTime(2026, 1, 1),
  );

  final sharedTime = DateTime(2026, 9, 10, 10, 0);

  final item1 = AppointmentWithPatient(
    appointment: Appointment(
      id: 'appt-1',
      patientId: patientA.id,
      type: AppointmentType.normalPtSession,
      scheduledAt: sharedTime,
      createdAt: DateTime(2026, 9, 1, 9, 0),
      status: AppointmentStatus.scheduled,
    ),
    patient: patientA,
  );

  final item2 = AppointmentWithPatient(
    appointment: Appointment(
      id: 'appt-2',
      patientId: patientB.id,
      type: AppointmentType.spinalTractionSession,
      scheduledAt: sharedTime,
      createdAt: DateTime(2026, 9, 1, 9, 30),
      status: AppointmentStatus.scheduled,
    ),
    patient: patientB,
  );

  group('Deterministic Appointment Sorting Tests', () {
    test('distinct scheduled times are ordered chronologically', () {
      final earlier = item1.copyWith(
        appointment: item1.appointment.copyWith(
          scheduledAt: sharedTime.subtract(const Duration(hours: 1)),
        ),
      );
      final list = [item2, earlier]..sort(compareAppointmentsChronologically);
      expect(list.first.appointment.id, 'appt-1');
      expect(list.last.appointment.id, 'appt-2');
    });

    test('same scheduled time is broken by createdAt (booking order)', () {
      final listForward = [item1, item2]
        ..sort(compareAppointmentsChronologically);
      final listReversed = [item2, item1]
        ..sort(compareAppointmentsChronologically);

      expect(listForward.map((e) => e.appointment.id).toList(), [
        'appt-1',
        'appt-2',
      ]);
      expect(listReversed.map((e) => e.appointment.id).toList(), [
        'appt-1',
        'appt-2',
      ]);
    });

    test('same scheduled time and createdAt broken deterministically by id', () {
      final cloneWithIdA = item1.copyWith(
        appointment: item1.appointment.copyWith(id: 'aaa-1'),
      );
      final cloneWithIdB = item1.copyWith(
        appointment: item1.appointment.copyWith(id: 'bbb-2'),
      );

      final list1 = [cloneWithIdB, cloneWithIdA]
        ..sort(compareAppointmentsChronologically);
      expect(list1.first.appointment.id, 'aaa-1');
      expect(list1.last.appointment.id, 'bbb-2');
    });

    test('changing appointment status preserves exact relative order', () {
      final checkedInItem1 = item1.copyWith(
        appointment: item1.appointment.copyWith(
          status: AppointmentStatus.checkedIn,
        ),
      );

      final listAfterCheckIn = [item2, checkedInItem1]
        ..sort(compareAppointmentsChronologically);

      expect(listAfterCheckIn.first.appointment.id, 'appt-1');
      expect(listAfterCheckIn.first.appointment.status, AppointmentStatus.checkedIn);
      expect(listAfterCheckIn.last.appointment.id, 'appt-2');
      expect(listAfterCheckIn.last.appointment.status, AppointmentStatus.scheduled);

      final cancelledItem2 = item2.copyWith(
        appointment: item2.appointment.copyWith(
          status: AppointmentStatus.cancelled,
        ),
      );
      final revertedItem1 = item1.copyWith(
        appointment: item1.appointment.copyWith(
          status: AppointmentStatus.scheduled,
        ),
      );

      final listMutated = [cancelledItem2, revertedItem1]
        ..sort(compareAppointmentsChronologically);

      expect(listMutated.first.appointment.id, 'appt-1');
      expect(listMutated.last.appointment.id, 'appt-2');
    });

    test('compareRawAppointmentsChronologically handles raw Appointment models', () {
      final apptA = item1.appointment;
      final apptB = item2.appointment;

      final list = [apptB, apptA]..sort(compareRawAppointmentsChronologically);
      expect(list.first.id, 'appt-1');
      expect(list.last.id, 'appt-2');
    });

    test('ReceptionistAppointmentsState.itemsForSelectedDay maintains stable order', () {
      final state = ReceptionistAppointmentsState(
        allItems: [item2, item1],
        selectedDate: sharedTime,
        loading: false,
      );

      final items = state.itemsForSelectedDay;
      expect(items.length, 2);
      expect(items[0].appointment.id, 'appt-1');
      expect(items[1].appointment.id, 'appt-2');

      final checkedInItem1 = item1.copyWith(
        appointment: item1.appointment.copyWith(
          status: AppointmentStatus.checkedIn,
        ),
      );

      final updatedState = state.copyWith(
        allItems: [item2, checkedInItem1],
      );

      final updatedItems = updatedState.itemsForSelectedDay;
      expect(updatedItems.length, 2);
      expect(updatedItems[0].appointment.id, 'appt-1');
      expect(updatedItems[0].appointment.status, AppointmentStatus.checkedIn);
      expect(updatedItems[1].appointment.id, 'appt-2');
    });
  });
}
