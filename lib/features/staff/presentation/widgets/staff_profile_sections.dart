import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_assignments.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_shift.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_schedule_format.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

const _s = AppStrings.staffSchedule;
const _d = AppStrings.staffDetails;

String staffRoleLabel(Staff staff) => switch (staff.role) {
  UserRole.superAdmin => AppStrings.superAdmin,
  UserRole.doctor => staff.isSenior ? AppStrings.consultant : AppStrings.doctor,
  UserRole.receptionist => AppStrings.receptionist,
};

/// Name, role and branches at the top of the profile.
class StaffProfileIdentity extends StatelessWidget {
  const StaffProfileIdentity({super.key, required this.staff, required this.schedule});
  final Staff staff;
  final StaffSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final List<String> tags = [
      staffRoleLabel(staff),
      if (staff.role == UserRole.receptionist && staff.canManagePayments) _s.managesPayments,
      if (!staff.isActive) _s.inactive,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: PatientMonogramBadge(name: staff.fullName, size: AppSizes.avatarLarge)),
          const SizedBox(width: AppSizes.p16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(staff.fullName, style: AppTextStyles.headingMedium.copyWith(color: colors.onSurface)),
                const SizedBox(height: AppSizes.p4),
                Text(tags.join(' · '), style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: AppSizes.p4),
                Text(
                  schedule.branches.isEmpty ? _s.noBranches : joinBranches(schedule.branches),
                  style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StaffContactSection extends StatelessWidget {
  const StaffContactSection({super.key, required this.staff});
  final Staff staff;

  @override
  Widget build(BuildContext context) => RecordSection(
    title: _s.contact,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RecordFact(label: _s.email, value: staff.email),
        if (staff.phone?.trim().isNotEmpty ?? false)
          RecordFact(label: _s.phone, value: Formatters.formatPhone(staff.phone!)),
      ],
    ),
  );
}

/// The week in clinic order, one row per day with that day's hours.
class StaffScheduleSection extends StatelessWidget {
  const StaffScheduleSection({super.key, required this.schedule});
  final StaffSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RecordSection(
      title: _s.weeklySchedule,
      child: schedule.shifts.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
              child: Text(_s.noSchedule, style: AppTextStyles.bodySecondary.copyWith(color: colors.onSurfaceVariant)),
            )
          : Column(
              children: [
                for (final int day in StaffShift.weekOrder)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.p10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: colors.outlineVariant, width: AppSizes.borderWidth)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: AppSizes.staffProfileLabelWidth,
                          child: Text(_d.weekdayLong(day), style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface)),
                        ),
                        Expanded(child: _dayHours(context, schedule.shiftsOn(day))),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _dayHours(BuildContext context, List<StaffShift> shifts) {
    final colors = Theme.of(context).colorScheme;
    if (shifts.isEmpty) {
      return Text(_s.off, style: AppTextStyles.bodySecondary.copyWith(color: colors.onSurfaceVariant));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (int index, StaffShift shift) in shifts.indexed)
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : AppSizes.p8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatShiftHours(context, shift), style: AppTextStyles.bodyMedium),
                Text(
                  shift.branch.displayLabel,
                  style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
