import 'package:flutter/widgets.dart';
import '../../../patient/domain/clinic_location.dart';
import '../../domain/invoice_action.dart';
import '../../domain/invoice_detail.dart';
import '../../domain/invoice_draft.dart';
import 'discount_fields.dart';
import 'refund_form_input.dart';

/// Everything the discount form holds. A percentage is of the invoice value
/// now, after any earlier refunds and discounts.
class DiscountFormInput with DiscountFields implements PaybackDetailsInput {
  DiscountFormInput({required this.invoice, required this.branch})
    : method = invoice.mainPaymentMethod;

  final InvoiceDetail invoice;
  @override
  ClinicLocation branch;
  /// Starts as the way the invoice was paid; staff can change it.
  @override
  PaymentMethod? method;
  @override
  final TextEditingController reason = TextEditingController();

  @override
  int get discountBaseMinor => invoice.valueMinor;

  bool get isPristine =>
      discountKind == DiscountKind.none &&
      method == invoice.mainPaymentMethod &&
      reason.text.trim().isEmpty;

  DiscountDraft draft() => DiscountDraft(
    invoice: invoice,
    kind: discountKind,
    value: discountValue ?? 0,
    branch: branch,
    method: method,
    reason: reason.text,
  );

  void addListener(VoidCallback listener) {
    for (final controller in [discountPercent, discountAmount, reason]) {
      controller.addListener(listener);
    }
  }

  void dispose() {
    for (final controller in [discountPercent, discountAmount, reason]) {
      controller.dispose();
    }
  }
}
