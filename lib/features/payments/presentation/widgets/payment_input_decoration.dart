import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

InputDecoration paymentInputDecoration(
  BuildContext context, {
  required String labelText,
  String? hintText,
  String? suffixText,
  String? errorText,
}) {
  final ColorScheme cs = Theme.of(context).colorScheme;
  final ClinicColors clinic = ClinicColors.of(context);
  final OutlineInputBorder border = OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
    borderSide: BorderSide(
      color: cs.outlineVariant,
      width: AppSizes.borderWidth,
    ),
  );

  return InputDecoration(
    labelText: labelText,
    labelStyle: AppTextStyles.captionMedium.copyWith(
      color: cs.onSurfaceVariant,
    ),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    isDense: true,
    filled: true,
    fillColor: cs.surface,
    hintText: hintText,
    hintStyle: AppTextStyles.bodySecondary.copyWith(color: clinic.textMuted),
    suffixText: suffixText,
    suffixStyle: AppTextStyles.captionMedium.copyWith(
      color: cs.onSurfaceVariant,
    ),
    errorText: errorText,
    errorStyle: AppTextStyles.caption.copyWith(color: cs.error),
    contentPadding: AppSizes.paddingCell,
    enabledBorder: border,
    disabledBorder: border.copyWith(
      borderSide: BorderSide(color: cs.outlineVariant),
    ),
    focusedBorder: border.copyWith(
      borderSide: BorderSide(
        color: clinic.outlineStrong,
        width: AppSizes.borderWidthFocused,
      ),
    ),
    errorBorder: border.copyWith(borderSide: BorderSide(color: cs.error)),
    focusedErrorBorder: border.copyWith(
      borderSide: BorderSide(
        color: cs.error,
        width: AppSizes.borderWidthFocused,
      ),
    ),
  );
}
