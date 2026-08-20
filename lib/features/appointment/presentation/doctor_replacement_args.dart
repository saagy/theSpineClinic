import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';

/// Arguments payload passed to the [DoctorReplacementScreen].
class DoctorReplacementArgs {
  const DoctorReplacementArgs({
    required this.absentDoctor,
    required this.availableDoctors,
    required this.appointments,
    required this.day,
  });

  final Staff absentDoctor;
  final List<Staff> availableDoctors;
  final List<AppointmentWithPatient> appointments;
  final DateTime day;
}
