/// Custom text input field widget matching the Stripe Dashboard styling design tokens.
///
/// Designed exclusively for phone/touch interactions. Features a clean label
/// sitting above the field, flat white background, subtle border transitions on focus,
/// and custom error styling.
///
/// When [isPassword] is true the field auto-manages its own obscure state
/// and renders a show/hide eye toggle as the suffix icon.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/shared/widgets/password_visibility_toggle.dart';

/// A standard form text field styled with Spine Clinic design tokens.
class AppTextField extends StatefulWidget {
  /// Creates an [AppTextField].
  const AppTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
  });

  /// Controller managing the text input state.
  final TextEditingController controller;

  /// Label displayed above the text input field.
  final String labelText;

  /// Optional placeholder text displayed inside the field.
  final String? hintText;

  /// Whether the input text should be obscured (e.g. for passwords).
  final bool obscureText;

  /// When true, the field manages password obscuring internally and
  /// renders a show/hide eye toggle as the suffix icon.
  final bool isPassword;

  /// The keyboard layout type to display.
  final TextInputType keyboardType;

  /// Custom validation logic function.
  final String? Function(String?)? validator;

  /// Optional leading icon or widget.
  final Widget? prefixIcon;

  /// Optional trailing icon or widget (e.g. eye icon for passwords).
  final Widget? suffixIcon;

  /// Whether the field is interactive.
  final bool enabled;

  /// Maximum lines of text to allow (default is 1).
  final int maxLines;

  /// Optional callback triggered on text change.
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final bool obscured = widget.isPassword ? _obscured : widget.obscureText;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);
    final Widget? suffix = widget.isPassword
        ? PasswordVisibilityToggle(
            isObscured: _obscured,
            onToggle: () => setState(() => _obscured = !_obscured),
          )
        : widget.suffixIcon;

    // Basic border parameters calling strictly AppSizes.r6 for sharp layout feel
    final OutlineInputBorder borderBase = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
      borderSide: BorderSide(color: cs.outline, width: AppSizes.borderWidth),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label above the text field
        Text(
          widget.labelText,
          style: AppTextStyles.captionMedium.copyWith(
            color: widget.enabled ? cs.onSurfaceVariant : clinic.textMuted,
          ),
        ),
        const SizedBox(height: AppSizes.p6),
        // The text input field
        TextFormField(
          controller: widget.controller,
          obscureText: obscured,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          onChanged: widget.onChanged,
          style: AppTextStyles.body.copyWith(
            color: widget.enabled ? cs.onSurface : clinic.textMuted,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: widget.enabled ? cs.surface : cs.surfaceContainer,
            hintText: widget.hintText,
            hintStyle: AppTextStyles.bodySecondary.copyWith(
              color: clinic.textMuted,
            ),
            contentPadding: AppSizes.paddingCell,
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p8,
                    ),
                    child: widget.prefixIcon,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: AppSizes.iconDefault + AppSizes.p16,
              minHeight: AppSizes.iconDefault,
            ),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p8,
                    ),
                    child: suffix,
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: AppSizes.iconDefault + AppSizes.p16,
              minHeight: AppSizes.iconDefault,
            ),
            // Default border state
            enabledBorder: borderBase,
            // Disabled border state
            disabledBorder: borderBase.copyWith(
              borderSide: BorderSide(
                color: cs.outline,
                width: AppSizes.borderWidth,
              ),
            ),
            // Focus border state (transitions cleanly using Flutter's native focus engine)
            focusedBorder: borderBase.copyWith(
              borderSide: BorderSide(
                color: clinic.outlineStrong,
                width: AppSizes.borderWidthFocused,
              ),
            ),
            // Validation error border states
            errorBorder: borderBase.copyWith(
              borderSide: BorderSide(
                color: cs.error,
                width: AppSizes.borderWidth,
              ),
            ),
            focusedErrorBorder: borderBase.copyWith(
              borderSide: BorderSide(
                color: cs.error,
                width: AppSizes.borderWidthFocused,
              ),
            ),
            // Validation error message style
            errorStyle: AppTextStyles.caption.copyWith(color: cs.error),
          ),
        ),
      ],
    );
  }
}
