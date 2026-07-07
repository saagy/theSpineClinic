import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

InputDecoration staffInputDecoration(
  BuildContext context,
  String label, {
  required bool enabled,
  String? hint,
  Widget? suffix,
}) {
  final ColorScheme cs = Theme.of(context).colorScheme;
  final OutlineInputBorder border = OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
    borderSide: BorderSide(color: cs.outline, width: AppSizes.borderWidth),
  );
  return InputDecoration(
    labelText: label,
    labelStyle: AppTextStyles.captionMedium.copyWith(
      color: cs.onSurfaceVariant,
    ),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    isDense: true,
    filled: true,
    fillColor: enabled ? cs.surface : cs.surfaceContainerHighest,
    hintText: hint,
    hintStyle: AppTextStyles.bodySecondary.copyWith(color: cs.onSurfaceVariant),
    contentPadding: AppSizes.paddingCell,
    enabledBorder: border,
    disabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(
        color: cs.primary,
        width: AppSizes.borderWidthFocused,
      ),
    ),
    errorBorder: border.copyWith(
      borderSide: BorderSide(color: cs.error, width: AppSizes.borderWidth),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: BorderSide(
        color: cs.error,
        width: AppSizes.borderWidthFocused,
      ),
    ),
    errorStyle: AppTextStyles.caption.copyWith(color: cs.error),
    suffixIcon: suffix,
  );
}

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
  });

  final String name;
  final String label;
  final bool enabled;
  final String? hint;
  final String? initialValue;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: name,
      enabled: enabled,
      initialValue: initialValue,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: staffInputDecoration(
        context,
        label,
        enabled: enabled,
        hint: hint,
      ),
      validator: validator,
    );
  }
}
