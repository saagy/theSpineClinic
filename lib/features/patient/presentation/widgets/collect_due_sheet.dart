import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_due_summary_card.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_input_parsers.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_live_summary_strip.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_text_field.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

class CollectDueSheet extends ConsumerStatefulWidget {
  const CollectDueSheet({
    super.key,
    required this.payment,
    required this.patientId,
    this.scrollController,
  });

  final PaymentRecord payment;
  final String patientId;
  final ScrollController? scrollController;

  @override
  ConsumerState<CollectDueSheet> createState() => _CollectDueSheetState();
}

class _CollectDueSheetState extends ConsumerState<CollectDueSheet> {
  final _amountCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  bool _submitting = false;

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0;
  double get _newDue => widget.payment.remainingDue - _amount;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.payment.remainingDue.toStringAsFixed(2);
    _amountCtrl.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_amountFocus);
    });
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _amountCtrl.removeListener(_refresh);
    _amountCtrl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final result = readPositiveAmount(
      _amountCtrl.text,
      emptyMessage: AppStrings.amountRequiredMessage,
    );
    final double? amount = result.value;
    if (amount == null) return _err(result.error!);
    if (amount > widget.payment.remainingDue) {
      return _err(AppStrings.amountExceedsRemainingDue);
    }

    final String amountText = amount.toCurrencyString();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: AppStrings.confirmCollection,
        message: AppStrings.confirmCollectDue(amountText),
        confirmLabel: AppStrings.confirm,
        cancelLabel: AppStrings.cancel,
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _submitting = true);
    final saveResult = await ref
        .read(recordPaymentControllerProvider.notifier)
        .collectDue(
          paymentId: widget.payment.id,
          patientId: widget.patientId,
          additionalAmount: amount,
        );
    if (!mounted) return;
    if (saveResult is Failure) {
      setState(() => _submitting = false);
      return _err(saveResult.exception.message);
    }
    AppSnackbar.show(
      context,
      message: AppStrings.collectionRecordedSuccess,
      variant: AppSnackbarVariant.success,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final String cta = _amount > 0
        ? AppStrings.collectPaymentCta(_amount.toCurrencyString())
        : AppStrings.confirmCollection;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PaymentDueSummaryCard(payment: widget.payment),
                const SizedBox(height: AppSizes.p20),
                PaymentTextField(
                  controller: _amountCtrl,
                  focusNode: _amountFocus,
                  labelText: AppStrings.amountToCollect,
                  hintText: AppStrings.zeroAmountHint,
                  suffixText: AppStrings.currencyEgp,
                  enabled: !_submitting,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p24,
            AppSizes.p12,
            AppSizes.p24,
            AppSizes.p16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PaymentLiveSummaryStrip(
                amount: _amount,
                amountLabel: AppStrings.amountToCollect,
                remainingDue: _newDue < 0 ? 0 : _newDue,
              ),
              const SizedBox(height: AppSizes.p12),
              AppButton(
                labelText: cta,
                isLoading: _submitting,
                onPressed: _submit,
                debounceMs: 1000,
                shape: AppButtonShape.pill,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _err(String message) => AppSnackbar.show(
    context,
    message: message,
    variant: AppSnackbarVariant.error,
  );
}
