import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel({super.key, required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: AppTextStyles.captionMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppSizes.p8),
      child,
    ],
  );
}

InputDecoration formInputDecoration(BuildContext context, {String? hint}) {
  final cs = Theme.of(context).colorScheme;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSizes.r8),
    borderSide: BorderSide(color: cs.outlineVariant),
  );
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: cs.surface,
    contentPadding: AppSizes.paddingCell,
    hintStyle: AppTextStyles.body.copyWith(color: cs.onSurfaceVariant),
    border: border,
    enabledBorder: border,
    disabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: cs.primary, width: AppSizes.borderWidthFocused),
    ),
    errorBorder: border.copyWith(borderSide: BorderSide(color: cs.error)),
    focusedErrorBorder: border.copyWith(
      borderSide: BorderSide(color: cs.error, width: AppSizes.borderWidthFocused),
    ),
  );
}
