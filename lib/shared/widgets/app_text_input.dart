/// Modern rounded text input with teal leading icon and floating label.
///
/// Matches the Medics UI Kit style: rounded border, light gray outline,
/// coloured leading icon, and a label positioned above the field.
///
/// When [isPassword] is true the field auto-manages its own obscure state
/// and renders a show/hide eye toggle as the suffix icon.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/password_visibility_toggle.dart';

/// A styled text input field with teal accent icon and rounded border.
class AppTextInput extends StatefulWidget {
  /// Creates an [AppTextInput].
  const AppTextInput({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.isPassword = false,
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

  /// When true, the field manages password obscuring internally and
  /// renders a show/hide eye toggle as the suffix icon.
  final bool isPassword;

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
  State<AppTextInput> createState() => _AppTextInputState();
}

class _AppTextInputState extends State<AppTextInput> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final bool obscured =
        widget.isPassword ? _obscured : widget.obscureText;
    final Widget? suffix = widget.isPassword
        ? PasswordVisibilityToggle(
            isObscured: _obscured,
            onToggle: () => setState(() => _obscured = !_obscured),
          )
        : widget.suffixIcon;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.p6),
            child: Text(
              widget.labelText!,
              style: AppTextStyles.bodyBold,
            ),
          ),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: obscured,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: widget.hintText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: AppColors.primary,
                    size: AppSizes.iconDefault,
                  )
                : null,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
