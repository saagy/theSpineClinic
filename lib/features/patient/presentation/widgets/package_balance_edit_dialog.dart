/// A dialog allowing authorized staff to edit BOTH of a patient's
/// package balances (PT sessions + traction sessions) in a single save.
///
/// Rule 1 — file is intentionally compact: one save callback updates
/// both columns via a single repository call.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/package_balance_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Edit dialog for both PT and traction package balances.
class PackageBalanceEditDialog extends StatefulWidget {
  /// Creates a [PackageBalanceEditDialog].
  const PackageBalanceEditDialog({
    super.key,
    required this.patient,
  });

  /// The patient whose balances are being edited.
  final Patient patient;

  @override
  State<PackageBalanceEditDialog> createState() => _PackageBalanceEditDialogState();
}

class _PackageBalanceEditDialogState extends State<PackageBalanceEditDialog> {
  late final TextEditingController _sessionCtrl;
  late final TextEditingController _tractionCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _sessionCtrl = TextEditingController(text: widget.patient.sessionBalance.toString());
    _tractionCtrl = TextEditingController(text: widget.patient.tractionBalance.toString());
  }

  @override
  void dispose() {
    _sessionCtrl.dispose();
    _tractionCtrl.dispose();
    super.dispose();
  }

  InputDecoration _buildDecoration({required String labelText, String? hintText}) {
    final OutlineInputBorder borderBase = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
      borderSide: const BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
    );

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: AppTextStyles.captionMedium.copyWith(color: AppColors.textSecondary),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      isDense: true,
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: AppTextStyles.bodySecondary.copyWith(color: AppColors.textMuted),
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
            borderRadius: BorderRadius.all(Radius.circular(AppSizes.r16)),
          ),
          backgroundColor: AppColors.surface,
          title: Text(
            AppStrings.editPackageBalance,
            style: AppTextStyles.headingSmall.copyWith(color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: 360,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${AppStrings.currentBalancePrefix}PT ${widget.patient.sessionBalance} · Tr ${widget.patient.tractionBalance}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  TextFormField(
                    controller: _sessionCtrl,
                    keyboardType: const TextInputType.numberWithOptions(signed: true),
                    enabled: !isLoading,
                    decoration: _buildDecoration(
                      labelText: AppStrings.sessionBalance,
                      hintText: AppStrings.sessionBalanceHint,
                    ),
                    style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                    validator: _validateInt,
                  ),
                  const SizedBox(height: AppSizes.p16),
                  TextFormField(
                    controller: _tractionCtrl,
                    keyboardType: const TextInputType.numberWithOptions(signed: true),
                    enabled: !isLoading,
                    decoration: _buildDecoration(
                      labelText: AppStrings.tractionBalance,
                      hintText: AppStrings.tractionBalanceHint,
                    ),
                    style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                    validator: _validateInt,
                  ),
                  const SizedBox(height: AppSizes.p12),
                  Text(
                    AppStrings.editReplacesExplanation,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
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
            AppButton(
              labelText: AppStrings.save,
              onPressed: isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        final int newSession = int.parse(_sessionCtrl.text);
                        final int newTraction = int.parse(_tractionCtrl.text);
                        final result = await ref
                            .read(packageBalanceControllerProvider.notifier)
                            .updateBalances(
                              patient: widget.patient,
                              newSessionBalance: newSession,
                              newTractionBalance: newTraction,
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
              isLoading: isLoading,
              shape: AppButtonShape.pill,
              fullWidth: false,
            ),
          ],
        );
      },
    );
  }

  String? _validateInt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.balanceRequired;
    }
    if (int.tryParse(value) == null) {
      return AppStrings.balanceMustBeInteger;
    }
    return null;
  }
}
