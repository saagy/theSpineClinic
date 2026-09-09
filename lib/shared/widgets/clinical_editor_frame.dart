import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Keeps save/cancel reachable while the clinical form scrolls above the keyboard.
class ClinicalEditorFrame extends StatelessWidget {
  const ClinicalEditorFrame({super.key, required this.child, required this.isSaving, required this.onSave});
  final Widget child;
  final bool isSaving;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !isSaving,
    child: Column(
      children: [
        Expanded(
          child: AbsorbPointer(absorbing: isSaving, child: child),
        ),
        Container(
          padding: const EdgeInsets.all(AppSizes.p12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          ),
          child: Row(
            children: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                child: const Text(AppStrings.cancel),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: FilledButton(
                  onPressed: isSaving ? null : onSave,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSizes.tappableMin),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
                  ),
                  child: Text(
                    isSaving ? AppStrings.savingClinicalRecord : AppStrings.save,
                    style: AppTextStyles.bodyBold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
