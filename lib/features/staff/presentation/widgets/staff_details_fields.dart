import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_details.dart';
import 'package:spine_clinic_app/shared/widgets/form_field_pair.dart';
import 'package:spine_clinic_app/shared/widgets/form_picker_field.dart';
import 'staff_form_controls.dart';

const _t = AppStrings.staffDetails;

/// National ID and dates. Values are read back by
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
      ],
    );
  }
}

/// Reads the details the form holds, in the shape the database saves.
StaffDetails staffDetailsFromForm(Map<String, Object?> values) {
  final String? national = values['national_id'] as String?;
  return StaffDetails(
    nationalId: national == null || national.isEmpty ? null : national,
    birthDate: values['birth_date'] as DateTime?,
    hireDate: values['hire_date'] as DateTime?,
  );
}
