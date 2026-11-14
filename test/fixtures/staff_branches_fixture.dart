import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_assignments.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_shift.dart';

StaffShift shift(ClinicLocation branch, int weekday, int startHour, int endHour) =>
    StaffShift(branch: branch, weekday: weekday, startMinutes: startHour * 60, endMinutes: endHour * 60);

/// Ahmed (doctor) splits his week: Sat/Mon/Wed at Tagamoa, Sun/Tue/Thu at
/// Madinaty, with a split Saturday. Nour (reception) works at Tagamoa.
final StaffAssignments demoAssignments = StaffAssignments(
  branches: {
    'doctor': [ClinicLocation.tagamoa, ClinicLocation.madinaty],
    'reception': [ClinicLocation.tagamoa],
    'long': [ClinicLocation.madinaty],
  },
  shifts: {
    'doctor': [
      shift(ClinicLocation.tagamoa, 6, 10, 14),
      shift(ClinicLocation.madinaty, 6, 15, 20),
      shift(ClinicLocation.madinaty, 7, 12, 20),
      shift(ClinicLocation.tagamoa, 1, 10, 18),
      shift(ClinicLocation.madinaty, 2, 12, 20),
      shift(ClinicLocation.tagamoa, 3, 10, 18),
      shift(ClinicLocation.madinaty, 4, 12, 20),
    ]..sort(StaffShift.compare),
  },
);
