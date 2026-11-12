import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_details.dart';
import 'package:spine_clinic_app/shared/widgets/filter_option_chip.dart';
import 'package:spine_clinic_app/shared/widgets/form_field_pair.dart';
import 'package:spine_clinic_app/shared/widgets/form_picker_field.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';
import 'staff_form_controls.dart';

const _t = AppStrings.staffDetails;

/// National ID, dates, working days and hours. Values are read back by
/// [staffDetailsFromForm].
class StaffDetailsFields extends StatelessWidget {
  const StaffDetailsFields({
    super.key,
    required this.enabled,
    required this.details,
    required this.formKey,
  });
  final bool enabled;
  final StaffDetails details;
  final GlobalKey<FormBuilderState> formKey;

  Object? _value(String name) => formKey.currentState?.fields[name]?.value;

  /// Re-checks a related field once it has a value or an error, so a fixed
  /// start time clears the end time's message.
  void _recheck(String name) {
    final field = formKey.currentState?.fields[name];
    if (field != null && (field.hasError || field.value != null)) field.validate();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final DateTime day = DateTime(today.year, today.month, today.day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormFieldPair(
          first: StaffTextField(
            name: 'national_id',
            label: _t.nationalId,
            hint: _t.nationalIdHint,
            enabled: enabled,
            initialValue: details.nationalId,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(14),
            ],
            validator: (value) => value == null || value.isEmpty || RegExp(r'^\d{14}$').hasMatch(value)
                ? null
                : _t.nationalIdInvalid,
          ),
          second: FormDateField(
            name: 'birth_date',
            label: _t.birthDate,
            enabled: enabled,
            firstDate: DateTime(1900),
            lastDate: day,
            initialValue: details.birthDate,
            onChanged: (_) => _recheck('hire_date'),
            validator: (value) => value != null && value.isAfter(day) ? _t.birthDateFuture : null,
          ),
        ),
        const SizedBox(height: AppSizes.p20),
        FormFieldPair(
          halfWidth: true,
          first: FormDateField(
            name: 'hire_date',
            label: _t.hireDate,
            enabled: enabled,
            firstDate: DateTime(1950),
            lastDate: DateTime(day.year + 1, day.month, day.day),
            initialValue: details.hireDate,
            validator: (value) {
              final Object? born = _value('birth_date');
              return value != null && born is DateTime && !value.isAfter(born) ? _t.hireBeforeBirth : null;
            },
          ),
        ),
        const SizedBox(height: AppSizes.p20),
        _WorkingDaysField(enabled: enabled, initialValue: details.workingDays),
        const SizedBox(height: AppSizes.p20),
        FormFieldPair(
          first: FormTimeField(
            name: 'work_starts_at',
            label: _t.startsAt,
            enabled: enabled,
            initialValue: details.workStartMinutes,
            onChanged: (_) => _recheck('work_ends_at'),
            validator: (value) => (value == null) != (_value('work_ends_at') == null) ? _t.hoursBoth : null,
          ),
          second: FormTimeField(
            name: 'work_ends_at',
            label: _t.endsAt,
            enabled: enabled,
            initialValue: details.workEndMinutes,
            onChanged: (_) => _recheck('work_starts_at'),
            validator: (value) {
              final Object? start = _value('work_starts_at');
              if ((value == null) != (start == null)) return _t.hoursBoth;
              return value != null && start is int && value <= start ? _t.hoursOrder : null;
            },
          ),
        ),
      ],
    );
  }
}

/// The week as toggles, Saturday first. The value is a sorted list of ISO
/// weekdays.
class _WorkingDaysField extends StatelessWidget {
  const _WorkingDaysField({required this.enabled, required this.initialValue});
  final bool enabled;
  final List<int> initialValue;

  @override
  Widget build(BuildContext context) => LabeledFormField(
    label: _t.workingDays,
    enabled: enabled,
    child: FormBuilderField<List<int>>(
      name: 'working_days',
      enabled: enabled,
      initialValue: initialValue,
      builder: (field) {
        final List<int> selected = field.value ?? const [];
        return Wrap(
          spacing: AppSizes.p8,
          runSpacing: AppSizes.p8,
          children: [
            for (final day in StaffDetails.weekOrder)
              Semantics(
                label: _t.weekdayLong(day),
                selected: selected.contains(day),
                button: true,
                excludeSemantics: true,
                child: Opacity(
                  opacity: enabled ? 1 : 0.6,
                  child: IgnorePointer(
                    ignoring: !enabled,
                    // A minimum width keeps the row even and lets enlarged text grow.
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: AppSizes.staffWeekdayWidth),
                      child: FilterOptionChip(
                        label: _t.weekday(day),
                        isSelected: selected.contains(day),
                        onTap: () {
                          // Read the live value so quick taps never undo each other.
                          final next = {...?field.value};
                          next.contains(day) ? next.remove(day) : next.add(day);
                          field.didChange(next.toList()..sort());
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

/// Reads the details the form holds, in the shape the database saves.
StaffDetails staffDetailsFromForm(Map<String, Object?> values) {
  final String? national = values['national_id'] as String?;
  return StaffDetails(
    nationalId: national == null || national.isEmpty ? null : national,
    birthDate: values['birth_date'] as DateTime?,
    hireDate: values['hire_date'] as DateTime?,
    workingDays: values['working_days'] as List<int>? ?? const [],
    workStartMinutes: values['work_starts_at'] as int?,
    workEndMinutes: values['work_ends_at'] as int?,
  );
}
