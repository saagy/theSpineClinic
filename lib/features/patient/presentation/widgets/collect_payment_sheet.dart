/// Bottom sheet for the Quick Action "Collect Payment" — amount,
/// reason chips, dual PT/Traction balance adders, and confirm button.
///
/// Wrapped in a [DraggableScrollableSheet] so the keyboard or expanded
/// add-fields never push live controls off-screen on phones. All chips
/// use the shared [ReasonChipsRow] so visual state matches the full
/// Record Payment screen.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/debounced_button.dart';
import 'package:spine_clinic_app/shared/widgets/reason_chips_row.dart';

/// Bottom sheet for collecting a payment with reason selection and
/// optional per-bucket package balance increments.
class CollectPaymentSheet extends ConsumerStatefulWidget {
  const CollectPaymentSheet({super.key, required this.patient});
  final Patient patient;

  @override
  ConsumerState<CollectPaymentSheet> createState() =>
      _CollectPaymentSheetState();
}

class _CollectPaymentSheetState extends ConsumerState<CollectPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _sessionBalanceCtrl = TextEditingController();
  final _tractionBalanceCtrl = TextEditingController();

  /// Default 'Session' so users get a sensible starting reason. The
  /// toggle stays OFF for every reason until they explicitly pick "Package".
  String _reason = 'Session';
  bool _addToPackage = false;
  bool _submitting = false;

  bool get _isAssessment =>
      _reason == AppStrings.paymentReasonInitialAssessment ||
      _reason == AppStrings.paymentReasonReassessment;

  /// Lifted list — also used by the `_handleReasonChange` reason lookup.
  static const List<String> _reasonPresets = [
    AppStrings.paymentReasonPackage,
    AppStrings.paymentReasonNormalPtSession,
    AppStrings.paymentReasonSpinalTraction,
    AppStrings.paymentReasonInitialAssessment,
    AppStrings.paymentReasonReassessment,
    AppStrings.paymentReasonOther,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_amountFocus);
    });
  }

  final _amountFocus = FocusNode();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _sessionBalanceCtrl.dispose();
    _tractionBalanceCtrl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _err(String msg) => AppSnackbar.show(context, message: msg, variant: AppSnackbarVariant.error);

  void _handleReasonChange(String next) {
    setState(() {
      _reason = next;
      _reasonCtrl.clear();
      // Package reason always defaults the add-toggle on (auto-filled
      // elsewhere). Every other non-assessment reason defaults it OFF;
      // assessments never show the toggle at all.
      if (_isAssessment) {
        _addToPackage = false;
      } else {
        _addToPackage = next == AppStrings.paymentReasonPackage;
      }
    });
  }

  Future<void> _submit() async {
    final amtText = _amountCtrl.text.trim();
    if (amtText.isEmpty) return _err('Please enter an amount.');
    final double? amount = double.tryParse(amtText);
    if (amount == null || amount <= 0) return _err(AppStrings.amountMustBePositive);
    final reason = _reason == AppStrings.paymentReasonOther ? _reasonCtrl.text.trim() : _reason;
    if (reason.isEmpty) return _err('Please enter a reason.');

    int sessionAdded = 0;
    int tractionAdded = 0;
    if (_addToPackage) {
      // Fields can be left empty — that means "no change in this bucket".
      // Only reject when the receptionist typed something invalid.
      final String sText = _sessionBalanceCtrl.text.trim();
      final String tText = _tractionBalanceCtrl.text.trim();
      final int? sParsed = sText.isEmpty ? 0 : int.tryParse(sText);
      final int? tParsed = tText.isEmpty ? 0 : int.tryParse(tText);
      if (sParsed == null || sParsed < 0) {
        return _err('Enter a valid PT session amount (or leave empty).');
      }
      if (tParsed == null || tParsed < 0) {
        return _err('Enter a valid traction amount (or leave empty).');
      }
      sessionAdded = sParsed;
      tractionAdded = tParsed;
    }

    final bool hasChanges = sessionAdded > 0 || tractionAdded > 0;
    final confirmMsg = hasChanges
        ? 'Record ${amount.toCurrencyString()} for $reason and add $sessionAdded PT + $tractionAdded traction?'
        : 'Record ${amount.toCurrencyString()} for $reason?';
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: AppStrings.confirmPayment, message: confirmMsg,
        confirmLabel: AppStrings.confirm, cancelLabel: AppStrings.cancel,
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _submitting = true);
    final result = await ref.read(recordPaymentControllerProvider.notifier)
        .submitPayment(
          patientId: widget.patient.id,
          amount: amount,
          reason: reason,
          sessionBalanceAdded: sessionAdded,
          tractionBalanceAdded: tractionAdded,
        );
    if (!mounted) return;
    if (result is Failure) {
      setState(() => _submitting = false);
      return _err(result.exception.message);
    }
    ref.invalidate(patientDetailProvider(widget.patient.id));
    ref.invalidate(patientPaymentsProvider(widget.patient.id));
    if (!mounted) return;
    AppSnackbar.show(context, message: AppStrings.paymentRecordedSuccess,
        variant: AppSnackbarVariant.success);
    Navigator.of(context).pop();
  }

  InputDecoration _dec(String label, [String? hint]) => InputDecoration(
        labelText: label, hintText: hint, isDense: true,
        contentPadding: const EdgeInsets.all(AppSizes.p12),
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    final bool allowsBalanceAdders = !_isAssessment;
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext ctx, ScrollController scrollController) {
        return _SheetBody(
          patient: widget.patient,
          scrollController: scrollController,
          amountCtrl: _amountCtrl,
          amountFocus: _amountFocus,
          reasonCtrl: _reasonCtrl,
          sessionBalanceCtrl: _sessionBalanceCtrl,
          tractionBalanceCtrl: _tractionBalanceCtrl,
          reason: _reason,
          addToPackage: _addToPackage,
          submitting: _submitting,
          allowsBalanceAdders: allowsBalanceAdders,
          reasonPresets: _reasonPresets,
          isAssessment: _isAssessment,
          onReasonChange: _handleReasonChange,
          onToggleAdd: (v) => setState(() => _addToPackage = v),
          onSubmit: _submit,
          dec: _dec,
        );
      },
    );
  }
}

/// Stateless body so the scroll controller lives outside the rebuild zone.
class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.patient,
    required this.scrollController,
    required this.amountCtrl,
    required this.amountFocus,
    required this.reasonCtrl,
    required this.sessionBalanceCtrl,
    required this.tractionBalanceCtrl,
    required this.reason,
    required this.addToPackage,
    required this.submitting,
    required this.allowsBalanceAdders,
    required this.reasonPresets,
    required this.isAssessment,
    required this.onReasonChange,
    required this.onToggleAdd,
    required this.onSubmit,
    required this.dec,
  });

  final Patient patient;
  final ScrollController scrollController;
  final TextEditingController amountCtrl;
  final FocusNode amountFocus;
  final TextEditingController reasonCtrl;
  final TextEditingController sessionBalanceCtrl;
  final TextEditingController tractionBalanceCtrl;
  final String reason;
  final bool addToPackage;
  final bool submitting;
  final bool allowsBalanceAdders;
  final List<String> reasonPresets;
  final bool isAssessment;
  final ValueChanged<String> onReasonChange;
  final ValueChanged<bool> onToggleAdd;
  final Future<void> Function() onSubmit;
  final InputDecoration Function(String, [String?]) dec;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
          AppSizes.p24, AppSizes.p20, AppSizes.p24, AppSizes.p32 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Collect Payment', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSizes.p20),
          TextField(
            controller: amountCtrl,
            focusNode: amountFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !submitting,
            decoration: dec('Amount', '0.00'),
          ),
          const SizedBox(height: AppSizes.p16),
          Text(
            'Reason',
            style: AppTextStyles.captionMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.p8),
          ReasonChipsRow(
            options: reasonPresets,
            selected: reason,
            enabled: !submitting,
            onChanged: onReasonChange,
          ),
          if (reason == AppStrings.paymentReasonOther) ...[
            const SizedBox(height: AppSizes.p12),
            TextField(
              controller: reasonCtrl,
              enabled: !submitting,
              decoration: dec('Specify reason'),
            ),
          ],
          if (allowsBalanceAdders) ...[
            const SizedBox(height: AppSizes.p12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                AppStrings.addBalanceToggleTitle,
                style: AppTextStyles.bodyMedium,
              ),
              subtitle: Text(
                AppStrings.addBalanceBothZero,
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
              value: addToPackage,
              onChanged: submitting ? null : onToggleAdd,
            ),
          ],
          if (allowsBalanceAdders && addToPackage) ...[
            const SizedBox(height: AppSizes.p4),
            TextField(
              controller: sessionBalanceCtrl,
              enabled: !submitting,
              keyboardType: TextInputType.number,
              decoration: dec('PT sessions to add', 'Leave empty to skip'),
            ),
            const SizedBox(height: AppSizes.p8),
            TextField(
              controller: tractionBalanceCtrl,
              enabled: !submitting,
              keyboardType: TextInputType.number,
              decoration: dec('Traction sessions to add', 'Leave empty to skip'),
            ),
          ],
          const SizedBox(height: AppSizes.p16),
          DebouncedElevatedButton(
            label: 'Confirm Payment',
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}
