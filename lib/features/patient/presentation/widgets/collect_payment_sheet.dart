/// Bottom sheet for the Quick Action "Collect Payment" — amount,
/// reason chips, package toggle, and confirm button.
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

/// Bottom sheet for collecting a payment with reason selection and
/// optional package balance increment.
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
  final _packageCtrl = TextEditingController();
  String _reason = 'Session';
  bool _addToPackage = false;
  bool _submitting = false;

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
    _packageCtrl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _err(String msg) => AppSnackbar.show(context, message: msg, variant: AppSnackbarVariant.error);

  Future<void> _submit() async {
    final amtText = _amountCtrl.text.trim();
    if (amtText.isEmpty) return _err('Please enter an amount.');
    final double? amount = double.tryParse(amtText);
    if (amount == null || amount <= 0) return _err(AppStrings.amountMustBePositive);
    final reason = _reason == 'Other' ? _reasonCtrl.text.trim() : _reason;
    if (reason.isEmpty) return _err('Please enter a reason.');
    int? packageDelta;
    if (_addToPackage) {
      final pkg = int.tryParse(_packageCtrl.text.trim());
      if (pkg == null || pkg <= 0) return _err('Enter a valid package amount.');
      packageDelta = pkg;
    }
    final confirmMsg = packageDelta != null
        ? 'Record ${amount.toCurrencyString()} for $reason and add $packageDelta to package?'
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
        .submitPayment(patientId: widget.patient.id, amount: amount, reason: reason);
    if (!mounted) return;
    if (result is Failure) {
      setState(() => _submitting = false);
      return _err(result.exception.message);
    }
    if (packageDelta != null) {
      final patient = ref.read(patientDetailProvider(widget.patient.id)).value;
      if (patient != null) {
        await ref.read(patientRepositoryProvider).updatePatient(
          patient.copyWith(packageBalance: patient.packageBalance + packageDelta),
        );
      }
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSizes.p24, AppSizes.p24, AppSizes.p24, AppSizes.p24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Collect Payment', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSizes.p20),
          TextField(
            controller: _amountCtrl, focusNode: _amountFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !_submitting, decoration: _dec('Amount', '0.00'),
          ),
          const SizedBox(height: AppSizes.p16),
          Text('Reason', style: AppTextStyles.captionMedium
              .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSizes.p8),
          Wrap(
            spacing: AppSizes.p8,
            children: ['Session', 'Package', 'Other'].map((r) => ChoiceChip(
                  label: Text(r), selected: _reason == r,
                  selectedColor: AppColors.primaryLight,
                  labelStyle: AppTextStyles.captionMedium.copyWith(
                    color: _reason == r ? AppColors.primary : AppColors.textSecondary,
                  ),
                  onSelected: (val) {
                    if (val) { setState(() {
                      _reason = r; _reasonCtrl.clear();
                      _addToPackage = r == 'Package';
                    }); }
                  },
                )).toList(),
          ),
          if (_reason == 'Other') ...[
            const SizedBox(height: AppSizes.p12),
            TextField(controller: _reasonCtrl, enabled: !_submitting,
                decoration: _dec('Specify reason')),
          ],
          const SizedBox(height: AppSizes.p12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Add to package balance', style: AppTextStyles.bodyMedium),
            value: _addToPackage,
            onChanged: _submitting ? null : (v) => setState(() => _addToPackage = v),
          ),
          if (_addToPackage) ...[
            const SizedBox(height: AppSizes.p4),
            TextField(controller: _packageCtrl, keyboardType: TextInputType.number,
                enabled: !_submitting, decoration: _dec('Package amount', 'e.g. 5')),
          ],
          const SizedBox(height: AppSizes.p16),
          DebouncedElevatedButton(
            label: 'Confirm Payment',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}