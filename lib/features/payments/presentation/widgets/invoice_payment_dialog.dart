import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/labeled_form_field.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../patient/domain/clinic_location.dart';
import '../../domain/invoice_action.dart';
import '../../domain/invoice_detail.dart';
import 'invoice_action_dialog.dart';
import 'invoice_branch_field.dart';
import 'invoice_timeline.dart';
import 'service_form_controls.dart';

const _t = AppStrings.invoiceDetail;

/// Records money received against an invoice, or, with [correcting], replaces
/// a receipt that was entered wrongly.
class InvoicePaymentDialog extends ConsumerStatefulWidget {
  const InvoicePaymentDialog({super.key, required this.invoice, this.correcting});
  final InvoiceDetail invoice;
  final InvoiceReceipt? correcting;

  @override
  ConsumerState<InvoicePaymentDialog> createState() => _InvoicePaymentDialogState();
}

class _InvoicePaymentDialogState extends ConsumerState<InvoicePaymentDialog> {
  late final TextEditingController _amount;
  final TextEditingController _reason = TextEditingController();
  late PaymentMethod _method;
  late ClinicLocation _branch;

  InvoiceReceipt? get _old => widget.correcting;

  /// Correcting frees the old receipt's amount before the new one is taken.
  int get _limit => widget.invoice.dueMinor + (_old?.amountMinor ?? 0);

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: Money.editable(_old?.amountMinor ?? _limit));
    _method = _old?.method ?? PaymentMethod.cash;
    // Money is counted where the person recording it works.
    _branch = _old?.branch ?? ref.read(currentUserProvider).value?.branch ?? widget.invoice.branch;
  }

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  InvoiceAction? _action() {
    final int? amount = Money.parseMinor(_amount.text);
    if (amount == null) return null;
    final InvoiceReceipt? old = _old;
    return old == null
        ? InvoiceAction.recordPayment(
            widget.invoice,
            amountMinor: amount,
            method: _method,
            branch: _branch,
          )
        : InvoiceAction.correctReceipt(
            widget.invoice,
            old,
            amountMinor: amount,
            method: _method,
            branch: _branch,
            reason: _reason.text,
          );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final InvoiceReceipt? old = _old;
    return InvoiceActionDialog(
      title: old == null ? _t.recordPayment : _t.correctReceipt,
      help: old == null ? null : _t.correctReceiptHelp,
      confirmLabel: old == null ? _t.recordPayment : _t.saveCorrection,
      buildAction: _action,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            old == null
                ? '${widget.invoice.patientName} · ${_t.dueNow(Money.format(_limit))}'
                : '${_t.receipt(old.displayNumber)} · ${_t.receivedAt} '
                      '${Formatters.formatDateTime(old.receivedAt)}',
            style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSizes.p20),
          ServiceTextInput(
            label: _t.amount,
            controller: _amount,
            enabled: true,
            numeric: true,
            decimal: true,
            maxLength: 13,
            validator: (text) {
              final int? amount = Money.parseMinor(text);
              if (amount == null || amount <= 0) return _t.amountRequired;
              return amount > _limit ? _t.amountTooHigh(Money.format(_limit)) : null;
            },
          ),
          const SizedBox(height: AppSizes.p20),
          LabeledFormField(
            label: _t.method,
            child: SegmentedButton<PaymentMethod>(
              segments: [
                for (final method in PaymentMethod.values)
                  ButtonSegment(value: method, label: Text(paymentMethodLabel(method))),
              ],
              selected: {_method},
              showSelectedIcon: false,
              style: const ButtonStyle(
                textStyle: WidgetStatePropertyAll(AppTextStyles.captionBold),
                minimumSize: WidgetStatePropertyAll(
                  Size(AppSizes.tappableMin, AppSizes.tappableMin),
                ),
              ),
              onSelectionChanged: (methods) => setState(() => _method = methods.first),
            ),
          ),
          const SizedBox(height: AppSizes.p20),
          InvoiceBranchField(
            value: _branch,
            onChanged: (branch) => setState(() => _branch = branch),
          ),
          if (old != null) ...[
            const SizedBox(height: AppSizes.p20),
            ServiceTextInput(
              label: _t.reason,
              hint: _t.reasonHint,
              controller: _reason,
              enabled: true,
              maxLength: 500,
              validator: (text) => text.isEmpty ? _t.reasonRequired : null,
            ),
          ],
        ],
      ),
    );
  }
}
