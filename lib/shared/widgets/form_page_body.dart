import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Bounded, keyboard-aware forms with persistent actions on phone and desktop.
class FormPageBody extends StatelessWidget {
  const FormPageBody({
    super.key,
    required this.child,
    required this.onSave,
    required this.onCancel,
    this.isSaving = false,
    this.saveLabel = AppStrings.save,
    this.maxWidth = AppSizes.clinicalContentMaxWidth,
  });
  final Widget child;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final bool isSaving;
  final String saveLabel;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: AbsorbPointer(
          absorbing: isSaving,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SizedBox(width: double.infinity, child: child),
              ),
            ),
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p12),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: LayoutBuilder(
                  builder: (context, constraints) => Row(
                    children: [
                      if (constraints.maxWidth >= AppSizes.desktopBreakpoint) const Spacer(),
                      TextButton(
                        onPressed: isSaving ? null : onCancel,
                        style: TextButton.styleFrom(
                          minimumSize: const Size.square(AppSizes.tappableMin),
                        ),
                        child: const Text(AppStrings.cancel, style: AppTextStyles.bodyMedium),
                      ),
                      const SizedBox(width: AppSizes.p16),
                      if (constraints.maxWidth >= AppSizes.desktopBreakpoint)
                        SizedBox(width: AppSizes.formActionWidth, child: _saveButton())
                      else
                        Expanded(child: _saveButton()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _saveButton() => FilledButton(
    onPressed: isSaving ? null : onSave,
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(AppSizes.inputHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
    ),
    child: Text(
      isSaving ? AppStrings.savingClinicalRecord : saveLabel,
      textAlign: TextAlign.center,
      style: AppTextStyles.bodyBold,
    ),
  );
}
