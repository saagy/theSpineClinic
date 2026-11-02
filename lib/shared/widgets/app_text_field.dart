import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'app_input_decoration.dart';
import 'labeled_form_field.dart';
import 'password_visibility_toggle.dart';

/// A standard labeled form input with theme-aware states and password visibility.
class AppTextField extends StatefulWidget {
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
    this.autofillHints,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onFieldSubmitted,
  });
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onFieldSubmitted;
  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscured = true;
  @override
  Widget build(BuildContext context) {
    final Widget? suffix = widget.isPassword
        ? PasswordVisibilityToggle(
            isObscured: _obscured,
            onToggle: () => setState(() => _obscured = !_obscured),
          )
        : widget.suffixIcon;
    return LabeledFormField(
      label: widget.labelText,
      enabled: widget.enabled,
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword ? _obscured : widget.obscureText,
        autocorrect: !widget.isPassword,
        enableSuggestions: !widget.isPassword,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        enabled: widget.enabled,
        maxLines: widget.maxLines,
        onChanged: widget.onChanged,
        autofillHints: widget.autofillHints,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        onFieldSubmitted: widget.onFieldSubmitted,
        style: AppTextStyles.body.copyWith(
          color: widget.enabled
              ? Theme.of(context).colorScheme.onSurface
              : ClinicColors.of(context).textMuted,
        ),
        decoration: appInputDecoration(
          context,
          enabled: widget.enabled,
          hintText: widget.hintText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
