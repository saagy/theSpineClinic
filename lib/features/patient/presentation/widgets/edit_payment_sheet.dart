import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/edit_payment_content.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_input_parsers.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_reason_presets.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

class EditPaymentSheet extends ConsumerStatefulWidget {
  const EditPaymentSheet({
    super.key,
    required this.payment,
    required this.patientId,
    this.scrollController,
  });

  final PaymentRecord payment;
  final String patientId;
  final ScrollController? scrollController;

  @override
  ConsumerState<EditPaymentSheet> createState() => _EditPaymentSheetState();
}

class _EditPaymentSheetState extends ConsumerState<EditPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _totalPriceCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  final _totalFocus = FocusNode();
  final _reasonFocus = FocusNode();

  bool _submitting = false;
  bool _isPartial = false;
  String _reason = '';
  String _lastTotalPrice = '';

  @override
  void initState() {
    super.initState();
    _isPartial = widget.payment.totalPrice != null;
    _amountCtrl.text = widget.payment.amount.toStringAsFixed(2);
    final double? totalPrice = widget.payment.totalPrice;
    if (totalPrice != null) {
      _totalPriceCtrl.text = totalPrice.toStringAsFixed(2);
      _lastTotalPrice = _totalPriceCtrl.text;
    }
    _reason = paymentReasonPresets.contains(widget.payment.reason)
        ? widget.payment.reason
        : AppStrings.paymentReasonOther;
    if (_reason == AppStrings.paymentReasonOther) {
      _reasonCtrl.text = widget.payment.reason;
    }
    _amountCtrl.addListener(_refresh);
    _totalPriceCtrl.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _amountCtrl.removeListener(_refresh);
    _totalPriceCtrl.removeListener(_refresh);
    _amountCtrl.dispose();
    _totalPriceCtrl.dispose();
    _reasonCtrl.dispose();
    _amountFocus.dispose();
    _totalFocus.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  void _setPartial(bool value) {
    setState(() {
      _isPartial = value;
      if (value) {
        _totalPriceCtrl.text = _lastTotalPrice.isNotEmpty
            ? _lastTotalPrice
            : _amountCtrl.text;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) FocusScope.of(context).requestFocus(_totalFocus);
        });
      } else {
        _lastTotalPrice = _totalPriceCtrl.text;
        _totalPriceCtrl.clear();
      }
    });
  }

  void _setReason(String value) {
    setState(() {
      _reason = value;
      if (value != AppStrings.paymentReasonOther) _reasonCtrl.clear();
    });
  }

  Future<void> _submit() async {
    final double? amount = _readAmount();
    if (amount == null) return;
    final double? totalPrice = _isPartial ? _readTotalPrice(amount) : null;
    if (_isPartial && totalPrice == null) return;
    final String reason = _finalReason();
    if (reason.isEmpty) return _err(AppStrings.customReasonRequiredMessage);

    final bool paidInFull = !_isPartial || amount == totalPrice;
    final String message = paidInFull
        ? AppStrings.confirmEditPaymentPaidInFull()
        : AppStrings.confirmEditPaymentWithDue(
            (totalPrice! - amount).toCurrencyString(),
          );
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: AppStrings.editPayment,
        message: message,
        confirmLabel: AppStrings.save,
        cancelLabel: AppStrings.cancel,
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _submitting = true);
    final result = await ref
        .read(recordPaymentControllerProvider.notifier)
        .editPayment(
          paymentId: widget.payment.id,
          patientId: widget.patientId,
          amount: amount,
          reason: reason,
          totalPrice: paidInFull ? null : totalPrice,
        );
    if (!mounted) return;
    if (result is Failure) {
      setState(() => _submitting = false);
      return _err(result.exception.message);
    }
    AppSnackbar.show(
      context,
      message: AppStrings.paymentUpdated,
      variant: AppSnackbarVariant.success,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return EditPaymentContent(
      scrollController: widget.scrollController,
      amountCtrl: _amountCtrl,
      totalPriceCtrl: _totalPriceCtrl,
      reasonCtrl: _reasonCtrl,
      amountFocus: _amountFocus,
      totalFocus: _totalFocus,
      reasonFocus: _reasonFocus,
      reason: _reason,
      reasonPresets: paymentReasonPresets,
      isPartial: _isPartial,
      submitting: _submitting,
      onPartialChanged: _setPartial,
      onReasonChanged: _setReason,
      onSubmit: _submit,
    );
  }

  double? _readAmount() {
    final result = readPositiveAmount(
      _amountCtrl.text,
      emptyMessage: AppStrings.amountRequiredMessage,
    );
    if (result.error != null) _err(result.error!);
    return result.value;
  }

  double? _readTotalPrice(double amount) {
    final result = readServiceTotal(_totalPriceCtrl.text, amount);
    if (result.error != null) _err(result.error!);
    return result.value;
  }

  String _finalReason() => _reason == AppStrings.paymentReasonOther
      ? _reasonCtrl.text.trim()
      : _reason;

  void _err(String message) => AppSnackbar.show(
    context,
    message: message,
    variant: AppSnackbarVariant.error,
  );
}
