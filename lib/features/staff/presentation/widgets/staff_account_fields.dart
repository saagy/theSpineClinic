import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/form_action_row.dart';
import 'staff_password_fields.dart';

class StaffAccountFields extends StatelessWidget {
  const StaffAccountFields({
    super.key,
    required this.enabled,
    required this.isSelf,
    required this.staff,
    required this.formKey,
    this.onSubmit,
  });
  final bool enabled;
  final bool isSelf;
  final Staff staff;
  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback? onSubmit;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FormBuilderField<bool>(
        name: 'is_active',
        initialValue: staff.isActive,
        enabled: enabled && !isSelf,
        builder: (FormFieldState<bool> field) {
          final bool active = field.value ?? staff.isActive;
          final bool changed = active != staff.isActive;
          return FormActionRow(
            title: AppStrings.staffAccessStatus(
              changed
                  ? (active
                        ? AppStrings.staffWillActivate
                        : AppStrings.staffWillDeactivate)
                  : (active ? AppStrings.active : AppStrings.deactivated),
            ),
            description: isSelf
                ? AppStrings.staffOwnAccessHelp
                : changed
                ? (active
                      ? AppStrings.staffActivateDraft
                      : AppStrings.staffDeactivateDraft)
                : active
                ? AppStrings.accountEnabledHint
                : AppStrings.accountDisabledHint,
            action: isSelf
                ? null
                : _action(
                    context,
                    label: changed
                        ? AppStrings.undoAccessChange
                        : active
                        ? AppStrings.deactivateOnSave
                        : AppStrings.activateOnSave,
                    destructive: active && !changed,
                    onPressed: enabled ? () => field.didChange(!active) : null,
                  ),
          );
        },
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
        child: Divider(
          height: AppSizes.borderWidth,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      FormBuilderField<bool>(
        name: 'change_password',
        initialValue: false,
        enabled: enabled,
        builder: (FormFieldState<bool> field) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormActionRow(
              title: AppStrings.password,
              description: field.value == true
                  ? AppStrings.staffPasswordDraftHelp
                  : AppStrings.staffPasswordHelp,
              action: _action(
                context,
                label: field.value == true
                    ? AppStrings.cancelPasswordChange
                    : AppStrings.changePassword,
                onPressed: enabled
                    ? () {
                        if (field.value == true) {
                          formKey.currentState?.fields['password']?.didChange(
                            null,
                          );
                          formKey.currentState?.fields['confirm_password']
                              ?.didChange(null);
                        }
                        field.didChange(!(field.value ?? false));
                      }
                    : null,
              ),
            ),
            if (field.value == true) ...[
              const SizedBox(height: AppSizes.p16),
              StaffPasswordFields(
                enabled: enabled,
                formKey: formKey,
                onSubmit: onSubmit,
                isNewAccount: false,
              ),
            ],
          ],
        ),
      ),
    ],
  );
  Widget _action(
    BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
    bool destructive = false,
  }) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: destructive ? Theme.of(context).colorScheme.error : null,
      minimumSize: const Size.square(AppSizes.tappableMin),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r8),
      ),
    ),
    child: Text(label, style: AppTextStyles.bodyMedium),
  );
}
