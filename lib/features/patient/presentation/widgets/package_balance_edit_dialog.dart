import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/package_balance_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// A dialog allowing authorized staff to edit the package balance of a patient.
class PackageBalanceEditDialog extends StatefulWidget {
  /// Creates a [PackageBalanceEditDialog].
  const PackageBalanceEditDialog({
    super.key,
    required this.patient,
  });

  /// The patient whose balance is being edited.
  final Patient patient;

  @override
  State<PackageBalanceEditDialog> createState() => _PackageBalanceEditDialogState();
}

class _PackageBalanceEditDialogState extends State<PackageBalanceEditDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.patient.packageBalance.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  InputDecoration _buildDecoration({required String labelText}) {
    final OutlineInputBorder borderBase = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
      borderSide: const BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
    );

    return InputDecoration(
      labelText: labelText,
      labelStyle: AppTextStyles.captionMedium.copyWith(color: AppColors.textSecondary),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      isDense: true,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: AppSizes.paddingCell,
      enabledBorder: borderBase,
      disabledBorder: borderBase,
      focusedBorder: borderBase.copyWith(
        borderSide: const BorderSide(color: AppColors.borderStrong, width: AppSizes.borderWidthFocused),
      ),
      errorBorder: borderBase.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: AppSizes.borderWidth),
      ),
      focusedErrorBorder: borderBase.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: AppSizes.borderWidthFocused),
      ),
      errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final AsyncValue<void> state = ref.watch(packageBalanceControllerProvider);
        final bool isLoading = state.isLoading;

        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSizes.r8)),
          ),
          backgroundColor: AppColors.surface,
          title: Text(
            AppStrings.editPackageBalance,
            style: AppTextStyles.headingSmall.copyWith(color: AppColors.textPrimary),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  enabled: !isLoading,
                  decoration: _buildDecoration(labelText: AppStrings.packageBalance),
                  style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.balanceRequired;
                    }
                    if (int.tryParse(value) == null) {
                      return AppStrings.balanceMustBeInteger;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                AppStrings.cancel,
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
                ),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        final int newBalance = int.parse(_controller.text);
                        final result = await ref
                            .read(packageBalanceControllerProvider.notifier)
                            .updateBalance(
                              patient: widget.patient,
                              newBalance: newBalance,
                            );
                        if (context.mounted) {
                          result.when(
                            success: (_) {
                              Navigator.of(context).pop();
                              AppSnackbar.show(
                                context,
                                message: AppStrings.packageBalanceUpdatedSuccess,
                                variant: AppSnackbarVariant.success,
                              );
                            },
                            failure: (AppException error) {
                              AppSnackbar.show(
                                context,
                                message: error.message,
                                variant: AppSnackbarVariant.error,
                              );
                            },
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : Text(
                      AppStrings.save,
                      style: AppTextStyles.bodyBold.copyWith(color: AppColors.textOnPrimary),
                    ),
            ),
          ],
        );
      },
    );
  }
}
