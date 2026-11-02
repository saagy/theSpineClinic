import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

/// Visible and accessible external labels for inputs and selections.
class LabeledFormField extends StatelessWidget {
  const LabeledFormField({
    super.key,
    required this.label,
    required this.child,
    this.enabled = true,
  });
  final String label;
  final Widget child;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      ExcludeSemantics(
        child: Text(
          label,
          style: AppTextStyles.captionMedium.copyWith(
            color: enabled
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : ClinicColors.of(context).textMuted,
          ),
        ),
      ),
      const SizedBox(height: AppSizes.p6),
      Semantics(label: label, child: child),
    ],
  );
}
