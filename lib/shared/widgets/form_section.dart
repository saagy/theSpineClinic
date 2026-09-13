import 'package:spine_clinic_app/shared/widgets/record_surface.dart';
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Semantic form group with a restrained border and no nested card shells.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.description,
  });
  final String title;
  final String? description;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => RecordSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: AppTextStyles.headingSmall)),
            if (action != null) ...[const SizedBox(width: AppSizes.p12), action!],
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: AppSizes.p4),
          Text(
            description!,
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
          child: Divider(
            height: AppSizes.borderWidth,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child,
      ],
    ),
  );
}
