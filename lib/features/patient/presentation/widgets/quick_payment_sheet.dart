/// Inline bottom-sheet for quick payment entry with optional package balance.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// A bottom-sheet wrapping simplified payment recording with optional
/// package-balance increment.
class QuickPaymentSheet extends ConsumerStatefulWidget {
  const QuickPaymentSheet({super.key, required this.patientId});
  final String patientId;

  @override
  ConsumerState<QuickPaymentSheet> createState() => _QuickPaymentSheetState();
}

class _QuickPaymentSheetState extends ConsumerState<QuickPaymentSheet> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();
  final TextEditingController _balanceCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      contentPadding: AppSizes.paddingCell,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final String amtText = _amountCtrl.text.trim();
    final String reason = _reasonCtrl.text.trim();
    final String balanceText = _balanceCtrl.text.trim();

    // ── client-side validation ──
    if (amtText.isEmpty || reason.isEmpty) {
      AppSnackbar.show(context, message: AppStrings.fillAmountAndReason, variant: AppSnackbarVariant.error);
      return;
    }
    final double? amount = double.tryParse(amtText);
    if (amount == null || amount <= 0) {
      AppSnackbar.show(context, message: AppStrings.amountMustBePositive, variant: AppSnackbarVariant.error);
      return;
    }

    int? balanceDelta;
    if (balanceText.isNotEmpty) {
      balanceDelta = int.tryParse(balanceText);
      if (balanceDelta == null) {
        AppSnackbar.show(context, message: AppStrings.packageBalanceMustBeInteger, variant: AppSnackbarVariant.error);
        return;
      }
    }

    // ── confirmation ──
    final String confirmMsg = balanceDelta != null
        ? 'Record a payment of ${amount.toCurrencyString()} for $reason and add $balanceDelta to package balance?'
        : 'Record a payment of ${amount.toCurrencyString()} for $reason?';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: AppStrings.confirmPayment,
        message: confirmMsg,
        confirmLabel: AppStrings.confirm,
        cancelLabel: AppStrings.cancel,
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isSubmitting = true);

    // ── Step 1: record the payment ──
    final Result<void> payResult = await ref
        .read(recordPaymentControllerProvider.notifier)
        .submitPayment(patientId: widget.patientId, amount: amount, reason: reason);

    if (!mounted) return;

    // Exit early on failure — the controller already transitioned its
    // own state to AsyncError; we just surface the message.
    if (payResult is Failure) {
      setState(() => _isSubmitting = false);
      AppSnackbar.show(
        context,
        message: payResult.exception.message,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    // ── Step 2: optional balance increment (sequential, after payment) ──
    if (balanceDelta != null && balanceDelta != 0) {
      try {
        final Patient? patient =
            ref.read(patientDetailProvider(widget.patientId)).value;
        if (patient != null) {
          final int newBalance = patient.packageBalance + balanceDelta;
          final repo = ref.read(patientRepositoryProvider);
          final Result<void> balanceResult =
              await repo.updatePatient(patient.copyWith(packageBalance: newBalance));

          if (!mounted) return;

          if (balanceResult is Failure) {
            setState(() => _isSubmitting = false);
            AppSnackbar.show(
              context,
              message: balanceResult.exception.message,
              variant: AppSnackbarVariant.error,
            );
            return;
          }
        }
      } catch (_) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        AppSnackbar.show(
          context,
          message: AppStrings.errorDatabaseQueryFailed,
          variant: AppSnackbarVariant.error,
        );
        return;
      }
    }

    // ── Step 3: invalidate & dismiss ──
    // Both operations succeeded — we can safely invalidate all
    // affected providers so the parent screen re-fetches fresh data.
    ref.invalidate(patientDetailProvider(widget.patientId));
    ref.invalidate(patientPaymentsProvider(widget.patientId));

    if (!mounted) return;
    AppSnackbar.show(context, message: AppStrings.paymentRecordedSuccess, variant: AppSnackbarVariant.success);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSizes.p24, AppSizes.p24, AppSizes.p24, AppSizes.p24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.quickPayment, style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSizes.p20),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !_isSubmitting,
            decoration: _decoration(AppStrings.paymentAmount, AppStrings.paymentAmountHint),
          ),
          const SizedBox(height: AppSizes.p16),
          TextField(
            controller: _reasonCtrl,
            enabled: !_isSubmitting,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoration(AppStrings.paymentReason, AppStrings.paymentReasonHint),
          ),
          const SizedBox(height: AppSizes.p16),
          TextField(
            controller: _balanceCtrl,
            keyboardType: TextInputType.number,
            enabled: !_isSubmitting,
            decoration: _decoration(AppStrings.addPackageBalanceOptional, AppStrings.packageBalanceHint),
          ),
          const SizedBox(height: AppSizes.p24),
          AppButton(
            labelText: AppStrings.save,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _handleSubmit,
          ),
        ],
      ),
    );
  }
}
