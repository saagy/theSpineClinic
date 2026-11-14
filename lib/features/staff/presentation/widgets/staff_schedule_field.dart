import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_assignments.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_shift.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_schedule_format.dart';
import 'package:spine_clinic_app/shared/widgets/filter_option_chip.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';
import 'staff_shift_dialog.dart';

const _s = AppStrings.staffSchedule;
const _d = AppStrings.staffDetails;

/// Branches and the weekly schedule as one form value, `schedule`, so a
/// removed branch takes its hours with it. Read back as a [StaffSchedule].
class StaffScheduleField extends StatelessWidget {
  const StaffScheduleField({super.key, required this.enabled, required this.initialValue, this.validator});
  final bool enabled;
  final StaffSchedule initialValue;
  final String? Function(StaffSchedule? value)? validator;

  @override
  Widget build(BuildContext context) => FormBuilderField<StaffSchedule>(
    name: 'schedule',
    enabled: enabled,
    initialValue: initialValue,
    validator: validator,
    builder: (field) {
      final StaffSchedule value = field.value ?? StaffSchedule.empty;
      final colors = Theme.of(context).colorScheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledFormField(
            label: _s.branches,
            enabled: enabled,
            child: Wrap(
              spacing: AppSizes.p8,
              runSpacing: AppSizes.p8,
              children: [
                for (final ClinicLocation branch in ClinicLocation.values)
                  Semantics(
                    button: true,
                    selected: value.branches.contains(branch),
                    child: IgnorePointer(
                      ignoring: !enabled,
                      child: FilterOptionChip(
                        label: branch.displayLabel,
                        isSelected: value.branches.contains(branch),
                        onTap: () {
                          // Read the live value so quick taps never undo each other.
                          final StaffSchedule live = field.value ?? StaffSchedule.empty;
                          final Set<ClinicLocation> next = {...live.branches};
                          next.contains(branch) ? next.remove(branch) : next.add(branch);
                          field.didChange(live.withBranches(next));
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p6),
          Text(_s.branchesHelp, style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant)),
          if (field.errorText != null) ...[
            const SizedBox(height: AppSizes.p6),
            Text(field.errorText!, style: AppTextStyles.caption.copyWith(color: colors.error)),
          ],
          const SizedBox(height: AppSizes.p20),
          LabeledFormField(
            label: _s.weeklySchedule,
            enabled: enabled,
            child: value.branches.isEmpty
                ? Text(_s.noBranchesYet, style: AppTextStyles.bodySecondary.copyWith(color: colors.onSurfaceVariant))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final int day in StaffShift.weekOrder)
                        _DayRow(day: day, schedule: value, enabled: enabled, onChanged: field.didChange),
                    ],
                  ),
          ),
        ],
      );
    },
  );
}

/// One weekday: its hours as removable chips, and an add button.
class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.schedule, required this.enabled, required this.onChanged});
  final int day;
  final StaffSchedule schedule;
  final bool enabled;
  final ValueChanged<StaffSchedule> onChanged;

  Future<void> _edit(BuildContext context, [StaffShift? existing]) async {
    final StaffShift? picked = await showStaffShiftDialog(
      context,
      weekday: day,
      branches: schedule.branches,
      others: [for (final s in schedule.shiftsOn(day)) if (s != existing) s],
      initial: existing,
    );
    if (picked == null) return;
    onChanged(schedule.withShifts([
      for (final s in schedule.shifts) if (s != existing) s,
      picked,
    ]));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final List<StaffShift> shifts = schedule.shiftsOn(day);
    return Container(
      constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant, width: AppSizes.borderWidth)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p6),
      child: Row(
        children: [
          SizedBox(
            width: AppSizes.staffWeekdayWidth,
            child: Text(_d.weekday(day), style: AppTextStyles.bodyBold.copyWith(color: colors.onSurface)),
          ),
          Expanded(
            child: shifts.isEmpty
                ? Text(_s.off, style: AppTextStyles.bodySecondary.copyWith(color: colors.onSurfaceVariant))
                : Wrap(
                    spacing: AppSizes.p8,
                    runSpacing: AppSizes.p6,
                    children: [
                      for (final StaffShift shift in shifts)
                        InputChip(
                          label: Text(formatShift(context, shift), style: AppTextStyles.caption),
                          onPressed: enabled ? () => _edit(context, shift) : null,
                          onDeleted: enabled
                              ? () => onChanged(schedule.withShifts([for (final s in schedule.shifts) if (s != shift) s]))
                              : null,
                          deleteButtonTooltipMessage: _s.removeShiftLabel(formatShift(context, shift)),
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                        ),
                    ],
                  ),
          ),
          IconButton(
            tooltip: '${_s.addShift} · ${_d.weekdayLong(day)}',
            onPressed: enabled ? () => _edit(context) : null,
            icon: const Icon(Icons.add, size: AppSizes.iconSmall),
            constraints: const BoxConstraints(minWidth: AppSizes.tappableMin, minHeight: AppSizes.tappableMin),
          ),
        ],
      ),
    );
  }
}
