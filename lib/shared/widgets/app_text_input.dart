/// Modern rounded text input with teal leading icon and floating label.
///
/// Matches the Medics UI Kit style: rounded border, light gray outline,
/// coloured leading icon, and a label positioned above the field.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A styled text input field with teal accent icon and rounded border.
class AppTextInput extends StatelessWidget {
  /// Creates an [AppTextInput].
  const AppTextInput({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.enabled = true,
    this.onChanged,
    this.errorText,
    this.maxLines = 1,
    this.textInputAction,
    this.onSubmitted,
  });

  /// The controller for this input field.
  final TextEditingController? controller;

  /// Label displayed above the input.
  final String? labelText;

  /// Placeholder hint inside the field.
  final String? hintText;

  /// Icon displayed at the leading edge (coloured teal).
  final IconData? prefixIcon;

  /// Icon displayed at the trailing edge.
  final Widget? suffixIcon;

  /// Whether to obscure the text (for passwords).
  final bool obscureText;

  /// The keyboard type for the field.
  final TextInputType? keyboardType;

  /// Validation function.
  final FormFieldValidator<String>? validator;

  /// Whether the field is enabled.
  final bool enabled;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// External error text to display.
  final String? errorText;

  /// Maximum number of lines.
  final int maxLines;

  /// The action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Called when the user submits the field.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.p6),
            child: Text(
              labelText!,
              style: AppTextStyles.bodyBold,
            ),
          ),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          onChanged: onChanged,
          maxLines: maxLines,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: AppColors.primary,
                    size: AppSizes.iconDefault,
                  )
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
