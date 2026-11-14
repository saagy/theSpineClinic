import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_assignments.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_details_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_schedule_format.dart';
import 'booking_warning_panel.dart';

/// One sentence per doctor whose usual schedule does not cover a visit at
/// [branch] on one of [starts]: the first such visit explains it. Doctors
/// without a schedule never appear.
List<String> bookingScheduleWarnings(
  BuildContext context, {
  required List<Staff> doctors,
  required ClinicLocation branch,
  required List<DateTime> starts,
  required StaffAssignments assignments,
}) => [
  for (final Staff doctor in doctors)
    if (starts
            .map((start) => scheduleMismatch(assignments.shiftsOf(doctor.id), branch, start))
            .firstWhere((m) => m != null, orElse: () => null)
        case final ScheduleMismatch mismatch)
      describeMismatch(context, doctor.fullName, mismatch),
];

/// Shows schedule mismatches for a booking. It never blocks: the visit can
/// still be booked, which the note says.
class BookingScheduleWarnings extends ConsumerWidget {
  const BookingScheduleWarnings({super.key, required this.doctors, required this.branch, required this.starts});
  final List<Staff> doctors;
  final ClinicLocation branch;
  final List<DateTime> starts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StaffAssignments assignments = ref.watch(staffAssignmentsProvider).value ?? StaffAssignments.none;
    final List<String> lines = bookingScheduleWarnings(
      context,
      doctors: doctors,
      branch: branch,
      starts: starts,
      assignments: assignments,
    );
    if (lines.isEmpty) return const SizedBox.shrink();
    return BookingWarningPanel(
      icon: Icons.schedule_outlined,
      lines: lines,
      note: AppStrings.staffSchedule.warningNote,
    );
  }
}
