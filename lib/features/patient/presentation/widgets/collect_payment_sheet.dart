import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/collect_payment_content.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_input_parsers.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_reason_presets.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

class CollectPaymentSheet extends ConsumerStatefulWidget {
  const CollectPaymentSheet({
    super.key,
    required this.patient,
    this.scrollController,
  });

  final Patient patient;
  final ScrollController? scrollController;

  @override
  ConsumerState<CollectPaymentSheet> createState() =>
      _CollectPaymentSheetState();
}

class _CollectPaymentSheetState extends ConsumerState<CollectPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _totalPriceCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _sessionCtrl = TextEditingController();
  final _tractionCtrl = TextEditingController();
  final _amountFocus = FocusNode();

  bool _submitting = false;
  bool _isPartial = false;
  bool _addToPackage = false;
  String _reason = AppStrings.paymentReasonNormalPtSession;
  String _lastTotalPrice = '';

  bool get _isAssessment =>
      _reason == AppStrings.paymentReasonInitialAssessment ||
      _reason == AppStrings.paymentReasonReassessment;

  @override
  void initState() {
    super.initState();
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
    _sessionCtrl.dispose();
    _tractionCtrl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _setPartial(bool value) {
    setState(() {
      _isPartial = value;
      if (value) {
        _totalPriceCtrl.text = _lastTotalPrice.isNotEmpty
            ? _lastTotalPrice
            : _amountCtrl.text;
      } else {
        _lastTotalPrice = _totalPriceCtrl.text;
        _totalPriceCtrl.clear();
      }
    });
  }

  void _setReason(String value) {
    setState(() {
      _reason = value;
      _reasonCtrl.clear();
      _addToPackage =
          !_isAssessment && value == AppStrings.paymentReasonPackage;
    });
  }

  Future<void> _submit() async {
    final double? amount = _readAmount();
    if (amount == null) return;
    final double? totalPrice = _isPartial ? _readTotalPrice(amount) : null;
    if (_isPartial && totalPrice == null) return;
    final String reason = _finalReason();
    if (reason.isEmpty) {
      return _err(
        _reason == AppStrings.paymentReasonOther
            ? AppStrings.customReasonRequiredMessage
            : AppStrings.reasonRequiredMessage,
      );
    }
    final credits = _readCredits();
    if (credits == null) return;

    final String amountText = amount.toCurrencyString();
    final String message = credits.pt > 0 || credits.traction > 0
        ? AppStrings.confirmRecordPaymentWithCredits(
            amountText,
            reason,
            credits.pt,
            credits.traction,
          )
        : AppStrings.confirmRecordPayment(amountText, reason);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: AppStrings.confirmPayment,
        message: message,
        confirmLabel: AppStrings.confirm,
        cancelLabel: AppStrings.cancel,
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _submitting = true);
    final result = await ref
        .read(recordPaymentControllerProvider.notifier)
        .submitPayment(
          patientId: widget.patient.id,
          amount: amount,
          reason: reason,
          sessionBalanceAdded: credits.pt,
          tractionBalanceAdded: credits.traction,
          totalPrice: totalPrice,
        );
    if (!mounted) return;
    if (result is Failure) {
      setState(() => _submitting = false);
      return _err(result.exception.message);
    }
    ref.invalidate(patientDetailProvider(widget.patient.id));
    ref.invalidate(patientPaymentsProvider(widget.patient.id));
    AppSnackbar.show(
      context,
      message: AppStrings.paymentRecordedSuccess,
      variant: AppSnackbarVariant.success,
    );
    Navigator.of(context).pop();
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

  ({int pt, int traction})? _readCredits() {
    if (!_addToPackage || _isAssessment) return (pt: 0, traction: 0);
    final int? pt = readOptionalCredit(_sessionCtrl.text);
    final int? traction = readOptionalCredit(_tractionCtrl.text);
    if (pt == null) return _errNull(AppStrings.validPtSessionsMessage);
    if (traction == null) {
      return _errNull(AppStrings.validTractionSessionsMessage);
    }
    return (pt: pt, traction: traction);
  }

  String _finalReason() => _reason == AppStrings.paymentReasonOther
      ? _reasonCtrl.text.trim()
      : _reason;

  void _err(String message) => AppSnackbar.show(
    context,
    message: message,
    variant: AppSnackbarVariant.error,
  );

  ({int pt, int traction})? _errNull(String message) {
    _err(message);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return CollectPaymentContent(
      scrollController: widget.scrollController,
      amountCtrl: _amountCtrl,
      totalPriceCtrl: _totalPriceCtrl,
      reasonCtrl: _reasonCtrl,
      sessionCtrl: _sessionCtrl,
      tractionCtrl: _tractionCtrl,
      amountFocus: _amountFocus,
      reason: _reason,
      reasonPresets: paymentReasonPresets,
      isPartial: _isPartial,
      addToPackage: _addToPackage,
      isAssessment: _isAssessment,
      submitting: _submitting,
      onPartialChanged: _setPartial,
      onReasonChanged: _setReason,
      onPackageChanged: (value) => setState(() => _addToPackage = value),
      onSubmit: _submit,
    );
  }
}
