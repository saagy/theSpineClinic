import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/shared/widgets/app_input_decoration.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';

const _t = AppStrings.staffDetails;

/// A labeled form field whose value is chosen in a picker dialog. It looks
/// like the app's text inputs and offers Clear once a value is set.
class FormPickerField<T> extends StatelessWidget {
  const FormPickerField({
    super.key,
    required this.name,
    required this.label,
    required this.enabled,
    required this.icon,
    required this.pickLabel,
    required this.format,
    required this.pick,
    this.initialValue,
    this.validator,
    this.onChanged,
  });
  final String name;
  final String label;
  final bool enabled;
  final IconData icon;
  final ValueChanged<T?>? onChanged;

  /// Hint shown while empty, such as "Choose date".
  final String pickLabel;
  final String Function(BuildContext context, T value) format;
  final Future<T?> Function(BuildContext context, T? current) pick;
  final T? initialValue;
  final String? Function(T? value)? validator;

  @override
  Widget build(BuildContext context) => LabeledFormField(
    label: label,
    enabled: enabled,
    child: FormBuilderField<T>(
      name: name,
      enabled: enabled,
      initialValue: initialValue,
      validator: validator,
      onChanged: onChanged,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (field) {
        final colors = Theme.of(context).colorScheme;
        final T? value = field.value;
        Future<void> open() async {
          final T? picked = await pick(context, value);
          if (picked != null) field.didChange(picked);
        }

        return Semantics(
          button: true,
          value: value == null ? null : format(context, value),
          child: InkWell(
            onTap: enabled ? open : null,
            borderRadius: BorderRadius.circular(AppSizes.r6),
            child: InputDecorator(
              isEmpty: value == null,
              decoration: appInputDecoration(
                context,
                enabled: enabled,
                hintText: pickLabel,
                prefixIcon: Icon(icon, size: AppSizes.iconSmall, color: colors.onSurfaceVariant),
                suffixIcon: value == null
                    ? null
                    : IconButton(
                        tooltip: _t.clear,
                        onPressed: enabled ? () => field.didChange(null) : null,
                        icon: const Icon(Icons.close, size: AppSizes.iconSmall),
                        // Same height as the text inputs beside it.
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size.square(AppSizes.tappableMin),
                          fixedSize: const Size.square(AppSizes.tappableMin),
                        ),
                      ),
              ).copyWith(errorText: field.errorText),
              child: value == null
                  ? null
                  : Text(
                      format(context, value),
                      style: AppTextStyles.body.copyWith(color: colors.onSurface),
                    ),
            ),
          ),
        );
      },
    ),
  );
}

/// A calendar date between [firstDate] and [lastDate].
class FormDateField extends StatelessWidget {
  const FormDateField({
    super.key,
    required this.name,
    required this.label,
    required this.enabled,
    required this.firstDate,
    required this.lastDate,
    this.initialValue,
    this.validator,
    this.onChanged,
  });
  final String name;
  final String label;
  final bool enabled;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialValue;
  final String? Function(DateTime? value)? validator;
  final ValueChanged<DateTime?>? onChanged;

  @override
  Widget build(BuildContext context) => FormPickerField<DateTime>(
    name: name,
    label: label,
    enabled: enabled,
    icon: Icons.calendar_today_outlined,
    pickLabel: _t.chooseDate,
    initialValue: initialValue,
    validator: validator,
    onChanged: onChanged,
    format: (_, value) => Formatters.formatDateMedium(value),
    pick: (context, current) {
      final DateTime today = DateTime.now();
      DateTime initial = current ?? (today.isAfter(lastDate) ? lastDate : today);
      if (initial.isBefore(firstDate)) initial = firstDate;
      if (initial.isAfter(lastDate)) initial = lastDate;
      return showDatePicker(
        context: context,
        firstDate: firstDate,
        lastDate: lastDate,
        initialDate: initial,
        helpText: label,
      );
    },
  );
}

/// A time of day, stored as minutes after midnight.
class FormTimeField extends StatelessWidget {
  const FormTimeField({
    super.key,
    required this.name,
    required this.label,
    required this.enabled,
    this.initialValue,
    this.validator,
    this.onChanged,
  });
  final String name;
  final String label;
  final bool enabled;
  final int? initialValue;
  final String? Function(int? value)? validator;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) => FormPickerField<int>(
    name: name,
    label: label,
    enabled: enabled,
    icon: Icons.schedule_outlined,
    pickLabel: _t.chooseTime,
    initialValue: initialValue,
    validator: validator,
    onChanged: onChanged,
    format: (context, minutes) => MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    ),
    pick: (context, current) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: current == null
            ? const TimeOfDay(hour: 9, minute: 0)
            : TimeOfDay(hour: current ~/ 60, minute: current % 60),
        helpText: label,
      );
      return picked == null ? null : picked.hour * 60 + picked.minute;
    },
  );
}
