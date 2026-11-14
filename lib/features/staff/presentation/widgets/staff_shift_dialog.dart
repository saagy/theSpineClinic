import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_shift.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_schedule_format.dart';
import 'package:spine_clinic_app/shared/widgets/app_input_decoration.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';
import 'package:spine_clinic_app/shared/widgets/record_action_menu.dart';
import 'package:spine_clinic_app/shared/widgets/record_menu_select.dart';

const _s = AppStrings.staffSchedule;
const _d = AppStrings.staffDetails;

/// Asks for one shift's branch and hours on [weekday]. [others] are the
/// person's other shifts that day, which the new hours may not overlap.
Future<StaffShift?> showStaffShiftDialog(
  BuildContext context, {
  required int weekday,
  required List<ClinicLocation> branches,
  required List<StaffShift> others,
  StaffShift? initial,
}) => showDialog<StaffShift>(
  context: context,
  builder: (_) => _ShiftDialog(weekday: weekday, branches: branches, others: others, initial: initial),
);

class _ShiftDialog extends StatefulWidget {
  const _ShiftDialog({required this.weekday, required this.branches, required this.others, this.initial});
  final int weekday;
  final List<ClinicLocation> branches;
  final List<StaffShift> others;
  final StaffShift? initial;

  @override
  State<_ShiftDialog> createState() => _ShiftDialogState();
}

class _ShiftDialogState extends State<_ShiftDialog> {
  late ClinicLocation _branch = widget.initial?.branch ?? widget.branches.first;
  late int? _start = widget.initial?.startMinutes;
  late int? _end = widget.initial?.endMinutes;
  String? _error;

  Future<void> _pick(bool start) async {
    final int current = (start ? _start : _end) ?? (start ? 9 * 60 : 17 * 60);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: start ? _s.startsAt : _s.endsAt,
    );
    if (picked == null || !mounted) return;
    setState(() {
      final int minutes = picked.hour * 60 + picked.minute;
      start ? _start = minutes : _end = minutes;
      _error = null;
    });
  }

  void _save() {
    if (_start == null || _end == null) return setState(() => _error = _s.pickTimes);
    if (_end! <= _start!) return setState(() => _error = _s.endAfterStart);
    final StaffShift shift = StaffShift(
      branch: _branch,
      weekday: widget.weekday,
      startMinutes: _start!,
      endMinutes: _end!,
    );
    if (widget.others.any(shift.overlaps)) return setState(() => _error = _s.overlaps);
    Navigator.of(context).pop(shift);
  }

  Widget _time(String label, int? value, bool start) => LabeledFormField(
    label: label,
    enabled: true,
    child: OutlinedButton.icon(
      onPressed: () => _pick(start),
      icon: const Icon(Icons.schedule_outlined, size: AppSizes.iconSmall),
      label: Text(value == null ? _d.chooseTime : formatClock(context, value)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSizes.tappableMin),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text('${widget.initial == null ? _s.addShift : _s.editShift} · ${_d.weekdayLong(widget.weekday)}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.shiftDialogWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.branches.length > 1) ...[
              LabeledFormField(
                label: _s.branch,
                enabled: true,
                child: RecordMenuSelect<ClinicLocation>(
                  label: _s.branch,
                  value: _branch,
                  isField: true,
                  decoration: appInputDecoration(context, enabled: true),
                  options: [
                    for (final b in widget.branches) RecordMenuAction(b, b.displayLabel, Icons.location_on_outlined),
                  ],
                  onChanged: (b) => setState(() => _branch = b),
                ),
              ),
              const SizedBox(height: AppSizes.p16),
            ],
            Row(
              children: [
                Expanded(child: _time(_s.startsAt, _start, true)),
                const SizedBox(width: AppSizes.p12),
                Expanded(child: _time(_s.endsAt, _end, false)),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSizes.p12),
              Text(_error!, style: AppTextStyles.caption.copyWith(color: colors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(_s.cancel)),
        FilledButton(onPressed: _save, child: Text(_s.save)),
      ],
    );
  }
}
