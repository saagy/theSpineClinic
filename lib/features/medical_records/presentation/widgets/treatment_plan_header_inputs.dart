library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';

/// Top header inputs (name, active switch, notes) for the treatment plan builder.
class TreatmentPlanHeaderInputs extends StatelessWidget {
  const TreatmentPlanHeaderInputs({
    super.key,
    required this.nameController,
    required this.notesController,
    required this.isActive,
    required this.onActiveChanged,
  });

  final TextEditingController nameController;
  final TextEditingController notesController;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: nameController,
          labelText: AppStrings.planName,
          hintText: AppStrings.planNameHint,
        ),
        const SizedBox(height: AppSizes.p12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            AppStrings.activePlanToggle,
            style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
          ),
          subtitle: Text(
            AppStrings.activePlanSubtitle,
            style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
          ),
          value: isActive,
          onChanged: onActiveChanged,
        ),
        const SizedBox(height: AppSizes.p12),
        AppTextField(
          controller: notesController,
          labelText: AppStrings.planNotes,
          hintText: AppStrings.planNotesHint,
          maxLines: 2,
        ),
      ],
    );
  }
}
