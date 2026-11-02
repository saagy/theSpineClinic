import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A named settings task with its action beside or below the explanation.
class FormActionRow extends StatelessWidget {
  const FormActionRow({
    super.key,
    required this.title,
    required this.description,
    this.action,
  });
  final String title;
  final String description;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final Widget copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.bodyBold),
        const SizedBox(height: AppSizes.p4),
        Text(
          description,
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        if (action != null &&
            box.maxWidth >= AppSizes.formActionRowBreakpoint &&
            MediaQuery.textScalerOf(context).scale(1) <=
                AppSizes.formPairMaxTextScale) {
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: AppSizes.p16),
              action!,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            copy,
            if (action != null) ...[
              const SizedBox(height: AppSizes.p8),
              action!,
            ],
          ],
        );
      },
    );
  }
}
