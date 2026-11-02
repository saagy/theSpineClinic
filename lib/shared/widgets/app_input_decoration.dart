import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

/// Shared control chrome for standard and FormBuilder inputs.
InputDecoration appInputDecoration(
  BuildContext context, {
  required bool enabled,
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final ColorScheme colors = Theme.of(context).colorScheme;
  final ClinicColors clinic = ClinicColors.of(context);
  final OutlineInputBorder border = OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
    borderSide: BorderSide(color: colors.outline, width: AppSizes.borderWidth),
  );
  Widget? inset(Widget? icon) => icon == null
      ? null
      : Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
          child: icon,
        );
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: enabled ? colors.surface : colors.surfaceContainer,
    hintText: hintText,
    hintStyle: AppTextStyles.bodySecondary.copyWith(
      color: enabled ? colors.onSurfaceVariant : clinic.textMuted,
    ),
    contentPadding: AppSizes.paddingCell,
    prefixIcon: inset(prefixIcon),
    suffixIcon: inset(suffixIcon),
    prefixIconConstraints: const BoxConstraints(
      minWidth: AppSizes.iconDefault + AppSizes.p16,
      minHeight: AppSizes.iconDefault,
    ),
    suffixIconConstraints: const BoxConstraints(
      minWidth: AppSizes.iconDefault + AppSizes.p16,
      minHeight: AppSizes.iconDefault,
    ),
    enabledBorder: border,
    disabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(
        color: clinic.outlineStrong,
        width: AppSizes.borderWidthFocused,
      ),
    ),
    errorBorder: border.copyWith(
      borderSide: BorderSide(color: colors.error, width: AppSizes.borderWidth),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: BorderSide(
        color: colors.error,
        width: AppSizes.borderWidthFocused,
      ),
    ),
    errorStyle: AppTextStyles.caption.copyWith(color: colors.error),
  );
}
