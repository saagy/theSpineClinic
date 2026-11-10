import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/record_action_menu.dart';
import '../../../shared/widgets/record_menu_select.dart';
import '../domain/billing_invoice.dart';
import '../domain/billing_money.dart';
import '../domain/billing_repository.dart';
import 'billing_editor_fields.dart';
import 'billing_providers.dart';
import 'billing_ui.dart';

part 'billing_movement_fields.dart';

class BillingMovementDialog extends ConsumerStatefulWidget {
  const BillingMovementDialog({
    super.key,
    required this.invoice,
    required this.action,
  });
  final BillingInvoice invoice;
  final BillingAction action;

  @override
  ConsumerState<BillingMovementDialog> createState() =>
      _BillingMovementDialogState();
}

class _BillingMovementDialogState extends ConsumerState<BillingMovementDialog> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  final Map<String, int> _quantities = {};
  BillingMethod _method = BillingMethod.cash;
  String? _error;
  bool get _return => widget.action == BillingAction.credit;
  bool get _refund => widget.action == BillingAction.refund;
  int get _limit =>
      _refund ? widget.invoice.refundable : widget.invoice.outstanding;
  String get _title => _return
      ? billingText.credit
      : _refund
      ? billingText.refund
      : billingText.collect;

  @override
  void initState() {
    super.initState();
    if (!_return) _amount.text = billingDecimal(_limit);
  }

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(billingWriterProvider).busy;
    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        title: Text(_title, style: AppTextStyles.headingSmall),
        scrollable: true,
        content: SizedBox(
          width: AppSizes.formLayoutMaxWidth,
          child: IgnorePointer(
            ignoring: busy,
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    billingPartyLabel(widget.invoice.patient),
                    style: AppTextStyles.bodyBold,
                  ),
                  const SizedBox(height: AppSizes.p8),
                  Text(
                    _return
                        ? billingText.returnHelp
                        : _refund
                        ? billingText.refundHelp
                        : billingText.receiptHelp,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: AppSizes.p12),
                  if (_return) ..._returnFields() else ..._paymentFields(),
                  if (_return || _refund)
                    TextFormField(
                      controller: _reason,
                      maxLength: 500,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        labelText: billingText.reason,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? billingText.reasonRequired
                          : null,
                    ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: AppTextStyles.body.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          if (_error != null)
            TextButton(
              onPressed: busy ? null : _recover,
              child: Text(billingText.checkSave),
            ),
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: busy ? null : _submit,
            child: Text(busy ? billingText.saving : _title),
          ),
        ],
      ),
    );
  }

  void _update(VoidCallback change) => setState(change);

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final BillingCommand command;
    if (_return) {
      final quantities = Map<String, int>.of(_quantities)
        ..removeWhere((_, quantity) => quantity <= 0);
      if (quantities.isEmpty) {
        _show(billingText.noItemsSelected);
        return;
      }
      command = BillingCommand.credit(
        widget.invoice,
        quantities,
        _reason.text.trim(),
      );
    } else {
      command = BillingCommand.money(
        widget.action,
        widget.invoice,
        parseBillingMinor(_amount.text)!,
        _method,
        _refund ? _reason.text.trim() : null,
      );
    }
    final commit = await submitBilling(context, ref, command, onMessage: _show);
    if (mounted && commit != null) Navigator.pop(context);
  }

  void _show(String message) {
    if (mounted) setState(() => _error = message);
  }

  Future<void> _recover() async {
    final commit = await recoverBilling(
      context,
      ref,
      widget.action,
      widget.invoice.id,
      onMessage: _show,
    );
    if (mounted && commit != null) Navigator.pop(context);
  }
}
