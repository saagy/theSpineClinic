import '../../patient/domain/clinic_location.dart';
import 'invoice_detail.dart';
import 'invoice_draft.dart';

/// A discount on an issued invoice, with the same arithmetic as
/// `invoice_record_discount`, so the figures staff review are the figures
/// that get recorded. The invoice keeps its number and its receipts.
class DiscountDraft {
  const DiscountDraft({
    required this.invoice,
    required this.kind,
    required this.value,
    required this.branch,
    this.method,
    this.reason = '',
  });

  final InvoiceDetail invoice;
  final DiscountKind kind;

  /// Basis points (10000 = 100%) for a percentage, piasters for an amount.
  final int value;

  /// Where the discount is recorded and any money is handed back.
  final ClinicLocation branch;

  /// How money is paid back; only used when [paybackMinor] is above zero.
  final PaymentMethod? method;
  final String reason;

  /// A percentage is of the invoice value now, after earlier reductions.
  int get discountMinor => switch (kind) {
    DiscountKind.none => 0,
    DiscountKind.percent => InvoiceDraft.percentOf(invoice.valueMinor, value),
    DiscountKind.amount => value,
  };

  bool get hasDiscount => discountMinor > 0;
  int get newValueMinor => invoice.valueMinor - discountMinor;

  /// Money comes back only when the patient has paid more than the new value.
  int get paybackMinor {
    final int excess = invoice.collectedMinor - newValueMinor;
    return excess > 0 ? excess : 0;
  }

  int get dueAfterMinor => newValueMinor - (invoice.collectedMinor - paybackMinor);

  Map<String, Object?> toBody() => {
    'discount': {'kind': kind.name, 'value': value},
    'payback_minor': paybackMinor,
    'payback_method': paybackMinor > 0 ? method?.name : null,
    'branch': branch.dbValue,
    'reason': reason.trim(),
  };
}
