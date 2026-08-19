/// Modern rounded dropdown selector with themed leading icon and external label.
///
/// Matches the style of [AppTextInput]: rounded border, themed leading icon,
/// and a bold label positioned above the field.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A styled dropdown form field matching [AppTextInput] styling.
class AppDropdown<T> extends StatelessWidget {
  /// Creates an [AppDropdown].
  const AppDropdown({
    super.key,
    this.value,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
  });

  /// The currently selected value.
  final T? value;

  /// The list of items the user can select from.
  final List<DropdownMenuItem<T>> items;

  /// Called when the user selects an item.
  final ValueChanged<T?>? onChanged;

  /// Label displayed above the dropdown.
  final String? labelText;

  /// Placeholder hint inside the field when no value is selected.
  final String? hintText;

  /// Icon displayed at the leading edge.
  final IconData? prefixIcon;

  /// Validation function.
  final FormFieldValidator<T>? validator;

  /// Whether the dropdown is interactive.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.p6),
            child: Text(
              labelText!,
              style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
            ),
          ),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          style: AppTextStyles.body.copyWith(
            color: enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.38),
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: cs.onSurfaceVariant,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: cs.primary,
                    size: AppSizes.iconDefault,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
