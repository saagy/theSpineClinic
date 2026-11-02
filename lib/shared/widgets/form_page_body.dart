import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'operation_feedback.dart';

/// Bounded, keyboard-aware forms with persistent actions on phone and desktop.
class FormPageBody extends StatelessWidget {
  const FormPageBody({
    super.key,
    required this.child,
    required this.onSave,
    required this.onCancel,
    this.isSaving = false,
    this.hasDocumentUploads = false,
    this.savingLabel = AppStrings.savingChanges,
    this.savingDetail,
    this.errorMessage,
    this.saveLabel = AppStrings.save,
    this.maxWidth = AppSizes.clinicalContentMaxWidth,
  });
  final Widget child;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final bool isSaving;
  final bool hasDocumentUploads;
  final String savingLabel;
  final String? savingDetail;
  final String? errorMessage;
  final String saveLabel;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !isSaving,
    child: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: ExcludeFocus(
                  excluding: isSaving,
                  child: AbsorbPointer(
                    absorbing: isSaving,
                    child: SizedBox(width: double.infinity, child: child),
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p16,
                vertical: AppSizes.p12,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if ((isSaving && hasDocumentUploads) ||
                          (!isSaving && errorMessage != null)) ...[
                        OperationFeedback(
                          message: isSaving ? savingLabel : errorMessage!,
                          detail: isSaving ? savingDetail : null,
                          isBusy: isSaving,
                          showUploadProgress: hasDocumentUploads,
                          isError: !isSaving,
                        ),
                        const SizedBox(height: AppSizes.p12),
                      ],
                      LayoutBuilder(
                        builder: (context, constraints) => Row(
                          children: [
                            if (constraints.maxWidth >=
                                AppSizes.desktopBreakpoint)
                              const Spacer(),
                            TextButton(
                              onPressed: isSaving ? null : onCancel,
                              style: TextButton.styleFrom(
                                minimumSize: const Size.square(
                                  AppSizes.tappableMin,
                                ),
                              ),
                              child: const Text(
                                AppStrings.cancel,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: AppSizes.p16),
                            if (constraints.maxWidth >=
                                AppSizes.desktopBreakpoint)
                              SizedBox(
                                width: AppSizes.formActionWidth,
                                child: _saveButton(),
                              )
                            else
                              Expanded(child: _saveButton()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _saveButton() => FilledButton(
    onPressed: isSaving ? null : onSave,
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(AppSizes.inputHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r8),
      ),
    ),
    child: Semantics(
      liveRegion: isSaving,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSaving && !hasDocumentUploads) ...[
            const SizedBox.square(
              dimension: AppSizes.iconSmall,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.strokeWidthThin,
              ),
            ),
            const SizedBox(width: AppSizes.p8),
          ],
          Flexible(
            child: Text(
              isSaving ? AppStrings.savingClinicalRecord : saveLabel,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyBold,
            ),
          ),
        ],
      ),
    ),
  );
}
