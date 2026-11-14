import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_assignments.dart';

const _s = AppStrings.staffSchedule;

/// One line of the doctor picker: a group heading, a doctor, or the switch
/// that reveals other branches' doctors.
sealed class DoctorPickerRow {
  const DoctorPickerRow();
}

class DoctorPickerHeading extends DoctorPickerRow {
  const DoctorPickerHeading(this.label);
  final String label;
}

class DoctorPickerDoctor extends DoctorPickerRow {
  const DoctorPickerDoctor(this.doctor);
  final Staff doctor;
}

class DoctorPickerToggle extends DoctorPickerRow {
  const DoctorPickerToggle({required this.expanded});
  final bool expanded;
}

/// Groups [doctors] (already filtered and sorted) for [branch]: the
/// branch's doctors first, then everyone else. Doctors without branches yet
/// count as the branch's. When [collapseOthers] is set, other doctors stay
/// behind a toggle unless [expanded], a search is running, or one of them
/// is selected. Without a branch the list is flat.
List<DoctorPickerRow> doctorPickerRows({
  required List<Staff> doctors,
  required ClinicLocation? branch,
  required StaffAssignments assignments,
  required bool collapseOthers,
  required bool expanded,
  required bool searching,
  required Set<String> selectedIds,
}) {
  if (branch == null) return [for (final d in doctors) DoctorPickerDoctor(d)];
  final List<Staff> here = [for (final d in doctors) if (assignments.worksAt(d.id, branch)) d];
  final List<Staff> others = [for (final d in doctors) if (!assignments.worksAt(d.id, branch)) d];
  if (others.isEmpty) return [for (final d in here) DoctorPickerDoctor(d)];
  final bool showOthers =
      !collapseOthers || expanded || searching || others.any((d) => selectedIds.contains(d.id));
  return [
    if (here.isNotEmpty) ...[
      DoctorPickerHeading(_s.atBranch(branch.displayLabel)),
      for (final d in here) DoctorPickerDoctor(d),
    ],
    if (showOthers) ...[
      DoctorPickerHeading(_s.otherDoctors),
      for (final d in others) DoctorPickerDoctor(d),
    ],
    if (collapseOthers && !searching) DoctorPickerToggle(expanded: showOthers),
  ];
}

class DoctorPickerHeadingTile extends StatelessWidget {
  const DoctorPickerHeadingTile({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p6),
    child: Semantics(
      header: true,
      child: Text(
        label,
        style: AppTextStyles.captionBold.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ),
  );
}

class DoctorPickerToggleTile extends StatelessWidget {
  const DoctorPickerToggleTile({super.key, required this.expanded, required this.onPressed});
  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin)),
        icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, size: AppSizes.iconSmall),
        label: Text(expanded ? _s.hideOtherBranches : _s.showOtherBranches),
      ),
    ),
  );
}
