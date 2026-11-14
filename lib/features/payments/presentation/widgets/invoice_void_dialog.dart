import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/invoice_action.dart';
import 'invoice_action_dialog.dart';
import 'service_form_controls.dart';

const _t = AppStrings.invoiceDetail;

/// Asks for the reason before cancelling an invoice, receipt or refund. The
/// reason is kept on the record and shown wherever the cancellation appears.
class InvoiceVoidDialog extends StatefulWidget {
  const InvoiceVoidDialog({
    super.key,
    required this.title,
    required this.help,
    required this.action,
    this.confirmLabel,
  });
  final String title;

  /// Defaults to [title].
  final String? confirmLabel;
  final String help;
  final InvoiceAction Function(String reason) action;

  @override
  State<InvoiceVoidDialog> createState() => _InvoiceVoidDialogState();
}

class _InvoiceVoidDialogState extends State<InvoiceVoidDialog> {
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InvoiceActionDialog(
    title: widget.title,
    help: widget.help,
    confirmLabel: widget.confirmLabel ?? widget.title,
    dismissLabel: _t.keepIt,
    destructive: true,
    buildAction: () => widget.action(_reason.text),
    child: ServiceTextInput(
      label: _t.reason,
      hint: _t.reasonHint,
      controller: _reason,
      enabled: true,
      maxLength: 500,
      validator: (text) => text.isEmpty ? _t.reasonRequired : null,
    ),
  );
}
