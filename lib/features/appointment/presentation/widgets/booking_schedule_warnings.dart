import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_assignments.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_details_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_schedule_format.dart';

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
    final ClinicColors clinic = ClinicColors.of(context);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: clinic.warningContainer,
          borderRadius: BorderRadius.circular(AppSizes.r8),
          border: Border.all(color: clinic.warning.withAlpha(110), width: AppSizes.borderWidth),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.schedule_outlined, size: AppSizes.iconSmall, color: clinic.warning),
            const SizedBox(width: AppSizes.p8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final String line in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.p4),
                      child: Text(line, style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface)),
                    ),
                  Text(
                    AppStrings.staffSchedule.warningNote,
                    style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
