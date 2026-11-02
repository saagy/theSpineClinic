import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_input_decoration.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';

class StaffTextField extends StatelessWidget {
  const StaffTextField({
    super.key,
    required this.name,
    required this.label,
    required this.enabled,
    this.hint,
    this.initialValue,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });
  final String name;
  final String label;
  final bool enabled;
  final String? hint;
  final String? initialValue;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String?>? onSubmitted;
  @override
  Widget build(BuildContext context) => LabeledFormField(
    label: label,
    enabled: enabled,
    child: FormBuilderTextField(
      name: name,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: enabled,
      initialValue: initialValue,
      style: AppTextStyles.body.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: appInputDecoration(context, enabled: enabled, hintText: hint),
      validator: (String? value) => validator?.call(value?.trim()),
      valueTransformer: (String? value) => value?.trim(),
    ),
  );
}
