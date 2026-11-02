import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_repository.dart';
import 'workspace_data.dart';

final bookingReturnPatient = workspacePatient.copyWith(
  id: '11111111-1111-1111-1111-111111111111',
);

class BookingReturnAppointments implements AppointmentRepository {
  bool failBooking = false;
  int bookings = 0;
  final List<Invocation> scheduleQueries = [];
  final List<DateTime> bookedSlots = [];

  @override
  Object? noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #getAssignedDoctors:
        return Future.value(Result.success([workspaceStaff('doctor')]));
      case #getFutureScheduledAppointmentsCountForType:
        return Future.value(const Result.success(0));
      case #createRecurringBookings:
        return _book(invocation);
      case #getAllAppointments:
        scheduleQueries.add(invocation);
        return Future.value(
          Result.success(<AppointmentWithPatient>[
            if (bookings > 0)
              AppointmentWithPatient(
                patient: bookingReturnPatient,
                appointment: Appointment(
                  id: 'booked-appointment',
                  patientId: bookingReturnPatient.id,
                  type: AppointmentType.normalPtSession,
                  scheduledAt: bookedSlots.single,
                  createdAt: DateTime(2026),
                ),
              ),
          ]),
        );
      default:
        return super.noSuchMethod(invocation);
    }
  }

  Future<Result<void>> _book(Invocation invocation) async {
    if (failBooking) {
      return const Result.failure(
        DatabaseException(
          code: 'db/unknown',
          message: 'Booking failed',
          userMessageKey: 'error_database_unknown',
        ),
      );
    }
    bookings++;
    bookedSlots.addAll(invocation.namedArguments[#slots] as List<DateTime>);
    return const Result.success(null);
  }
}

class BookingReturnPatients implements PatientRepository {
  BookingReturnPatients(this.appointments);
  final BookingReturnAppointments appointments;
  final List<Invocation> dueQueries = [];

  @override
  Object? noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getDuePatients) {
      dueQueries.add(invocation);
      return Future.value(
        Result.success(<Patient>[
          if (appointments.bookings == 0) bookingReturnPatient,
        ]),
      );
    }
    return super.noSuchMethod(invocation);
  }
}
