import '../../patient/domain/clinic_location.dart';
import 'invoice_detail.dart';
import 'invoice_draft.dart';
import 'service_catalog_item.dart';

/// Commands on an existing invoice, matching `execute_invoice_command` kinds.
enum InvoiceActionKind {
  receiptCreate('receipt_create', needsManage: false),
  receiptCorrect('receipt_correct'),
  receiptVoid('receipt_void'),
  refundCreate('refund_create'),
  refundVoid('refund_void'),
  invoiceVoid('invoice_void'),
  invoiceCorrect('invoice_correct');

  const InvoiceActionKind(this.dbValue, {this.needsManage = true});
  final String dbValue;

  /// Everything except recording a payment needs the manage capability.
  final bool needsManage;
}

/// One command against an invoice. It carries the invoice version it was
/// prepared from, so the database rejects it if the invoice changed since.
class InvoiceAction {
  const InvoiceAction._(this.kind, this.invoice, this._body, {String? document})
    : subject = document ?? '';

  factory InvoiceAction.recordPayment(
    InvoiceDetail invoice, {
    required int amountMinor,
    required PaymentMethod method,
    required ClinicLocation branch,
  }) => InvoiceAction._(InvoiceActionKind.receiptCreate, invoice, {
    'amount_minor': amountMinor,
    'method': method.name,
    'branch': branch.dbValue,
  });

  factory InvoiceAction.correctReceipt(
    InvoiceDetail invoice,
    InvoiceReceipt receipt, {
    required int amountMinor,
    required PaymentMethod method,
    required ClinicLocation branch,
    required String reason,
  }) => InvoiceAction._(InvoiceActionKind.receiptCorrect, invoice, {
    'receipt_id': receipt.id,
    'amount_minor': amountMinor,
    'method': method.name,
    'branch': branch.dbValue,
    'reason': reason.trim(),
  }, document: receipt.id);

  factory InvoiceAction.voidReceipt(InvoiceDetail invoice, InvoiceReceipt receipt, String reason) =>
      InvoiceAction._(InvoiceActionKind.receiptVoid, invoice, {
        'receipt_id': receipt.id,
        'reason': reason.trim(),
      }, document: receipt.id);

  factory InvoiceAction.refund(RefundDraft draft) =>
      InvoiceAction._(InvoiceActionKind.refundCreate, draft.invoice, draft.toBody());

  factory InvoiceAction.voidRefund(InvoiceDetail invoice, InvoiceRefund refund, String reason) =>
      InvoiceAction._(InvoiceActionKind.refundVoid, invoice, {
        'refund_id': refund.id,
        'reason': reason.trim(),
      }, document: refund.id);

  factory InvoiceAction.voidInvoice(InvoiceDetail invoice, String reason) =>
      InvoiceAction._(InvoiceActionKind.invoiceVoid, invoice, {'reason': reason.trim()});

  /// Voids [invoice] and issues [replacement] in its place. Active receipts
  /// move to the replacement, so its payments section is not sent.
  factory InvoiceAction.correctInvoice(InvoiceDetail invoice, InvoiceDraft replacement, String reason) =>
      InvoiceAction._(InvoiceActionKind.invoiceCorrect, invoice, {
        'reason': reason.trim(),
        'invoice': replacement.toPayload()..remove('payments'),
      });

  final InvoiceActionKind kind;
  final InvoiceDetail invoice;
  final Map<String, Object?> _body;

  /// The receipt or refund this command targets, or empty for the invoice.
  final String subject;

  Map<String, Object?> toPayload() => {'id': invoice.id, 'version': invoice.version, ..._body};
}

/// Sessions and value to take off one invoice line.
class RefundLineDraft {
  const RefundLineDraft({required this.line, this.sessions = 0, this.valueMinor = 0});
  final InvoiceLineDetail line;
  final int sessions;
  final int valueMinor;

  bool get isEmpty => sessions == 0 && valueMinor == 0;
}

/// A refund with the same arithmetic as the database, so the figures staff
/// review are the figures that get recorded.
class RefundDraft {
  const RefundDraft({
    required this.invoice,
    required this.lines,
    required this.branch,
    this.method,
    this.reason = '',
  });

  final InvoiceDetail invoice;
  final List<RefundLineDraft> lines;

  /// Where the refund is recorded and any money is handed back.
  final ClinicLocation branch;

  /// How money is paid back; only used when [paybackMinor] is above zero.
  final PaymentMethod? method;
  final String reason;

  Iterable<RefundLineDraft> get _used => lines.where((line) => !line.isEmpty);

  int get refundValueMinor => _used.fold(0, (sum, line) => sum + line.valueMinor);
  int get newValueMinor => invoice.valueMinor - refundValueMinor;

  /// Money comes back only when the patient has paid more than the new value.
  int get paybackMinor {
    final int excess = invoice.collectedMinor - newValueMinor;
    return excess > 0 ? excess : 0;
  }

  int get dueAfterMinor => newValueMinor - (invoice.collectedMinor - paybackMinor);
  bool get hasLines => _used.isNotEmpty;

  int sessionsOf(ServiceType type) =>
      _used.where((line) => line.line.type == type).fold(0, (sum, line) => sum + line.sessions);

  Map<String, Object?> toBody() => {
    'lines': [
      for (final line in _used)
        {'line_id': line.line.id, 'sessions': line.sessions, 'value_minor': line.valueMinor},
    ],
    'payback_minor': paybackMinor,
    'payback_method': paybackMinor > 0 ? method?.name : null,
    'branch': branch.dbValue,
    'reason': reason.trim(),
  };
}
