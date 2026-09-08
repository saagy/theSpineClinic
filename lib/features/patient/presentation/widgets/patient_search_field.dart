import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Single-surface search field used by the patient directory header.
class PatientSearchField extends StatelessWidget {
  const PatientSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.r8),
      borderSide: BorderSide(
        color: cs.outlineVariant,
        width: AppSizes.borderWidth,
      ),
    );

    return SizedBox(
      height: AppSizes.tappableMin,
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
        decoration: InputDecoration(
          filled: true,
          fillColor: cs.surface,
          hintText: AppStrings.searchPatients,
          hintStyle: AppTextStyles.caption.copyWith(
            color: cs.onSurfaceVariant.withAlpha(140),
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            size: AppSizes.iconSmall,
            color: cs.onSurfaceVariant,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p12,
            vertical: AppSizes.p12,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(
              color: cs.primary,
              width: AppSizes.borderWidthFocused,
            ),
          ),
        ),
      ),
    );
  }
}
