import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../../../../core/utils/money.dart';
import '../../../patient/domain/clinic_location.dart';
import '../../domain/invoice_action.dart';
import '../../domain/invoice_detail.dart';
import '../../domain/service_catalog_item.dart';

/// Form state for one refundable invoice line.
class RefundLineInput {
  RefundLineInput(this.line);
  final InvoiceLineDetail line;
  int sessions = 0;
  final TextEditingController value = TextEditingController();

  /// Null when the typed value is not a valid amount; empty means zero.
  int? get valueMinor => value.text.trim().isEmpty ? 0 : Money.parseMinor(value.text);
}

/// Where a refund or discount is recorded, how any money goes back and why.
abstract interface class PaybackDetailsInput {
  ClinicLocation get branch;
  set branch(ClinicLocation value);
  PaymentMethod? get method;
  set method(PaymentMethod? value);
  TextEditingController get reason;
}

/// Everything the refund form holds.
class RefundFormInput implements PaybackDetailsInput {
  RefundFormInput({required this.invoice, required this.branch, required this.balances})
    : method = invoice.mainPaymentMethod,
      lines = [
        for (final line in invoice.lines)
          if (line.isRefundable) RefundLineInput(line),
      ];

  final InvoiceDetail invoice;
  final List<RefundLineInput> lines;

  /// The patient's unused sessions by type. Sessions already used cannot be
  /// cancelled, whichever invoice they came from.
  final Map<ServiceType, int> balances;
  @override
  ClinicLocation branch;
  /// Starts as the way the invoice was paid; staff can change it.
  @override
  PaymentMethod? method;
  @override
  final TextEditingController reason = TextEditingController();

  /// How many sessions [input] may cancel: what its line still holds, capped
  /// by the unused balance not already claimed by the other lines.
  int sessionLimit(RefundLineInput input) {
    final int claimed = lines
        .where((other) => other != input && other.line.type == input.line.type)
        .fold(0, (sum, other) => sum + other.sessions);
    final int unused = (balances[input.line.type] ?? 0) - claimed;
    return math.max(0, math.min(input.line.sessionsLeft, unused));
  }

  bool get isPristine =>
      reason.text.trim().isEmpty &&
      method == invoice.mainPaymentMethod &&
      lines.every((line) => line.sessions == 0 && line.value.text.trim().isEmpty);

  RefundDraft draft() => RefundDraft(
    invoice: invoice,
    branch: branch,
    method: method,
    reason: reason.text,
    lines: [
      for (final line in lines)
        RefundLineDraft(line: line.line, sessions: line.sessions, valueMinor: line.valueMinor ?? 0),
    ],
  );

  void addListener(VoidCallback listener) {
    reason.addListener(listener);
    for (final line in lines) {
      line.value.addListener(listener);
    }
  }

  void dispose() {
    reason.dispose();
    for (final line in lines) {
      line.value.dispose();
    }
  }
}
