/// Text for the invoice detail view and its payment, refund, void and
/// correction actions.
final class InvoiceDetailStrings {
  const InvoiceDetailStrings();

  // Detail view
  String title(String number) => 'Invoice $number';
  final String invoice = 'Invoice';
  final String notFound = 'This invoice is no longer available.';
  final String openInvoice = 'Open invoice';
  final String issuedBy = 'Issued by';
  final String branch = 'Branch';
  final String invoiceDate = 'Invoice date';
  final String note = 'Note';
  final String services = 'Services';
  final String noDoctors = 'No doctor credit';
  final String invoiceValue = 'Invoice value';
  final String refunded = 'Refunded';
  final String paid = 'Paid';
  final String due = 'Due';
  String quantityLine(int quantity, String price) => '$quantity × $price';
  String sessionsCancelled(int count) =>
      count == 1 ? '1 session cancelled' : '$count sessions cancelled';
  String afterRefund(String amount) => '$amount after refund';
  String corrects(String number) => 'Corrects $number';
  String correctedBy(String number) => 'Replaced by $number';
  String voidedBy(String name, String time) => 'Voided by $name on $time';
  final String voidedInvoice = 'This invoice is voided and excluded from all totals.';

  // Actions
  final String recordPayment = 'Record payment';
  final String refund = 'Refund';
  final String print = 'Print';
  final String printInvoice = 'Print invoice';
  final String correctInvoice = 'Correct invoice';
  final String voidInvoice = 'Void invoice';
  final String correct = 'Correct';
  final String voidAction = 'Void';
  final String printFailed = 'The document could not be prepared. Try again.';
  final String voidNeedsNoPayments = 'Void its payments and refunds first';
  final String correctNeedsNoRefunds = 'Void its refunds first';
  final String lockedByRefund = 'Void the later refund first';

  // Activity
  final String activity = 'Activity';
  final String created = 'Invoice created';
  String receipt(String number) => 'Receipt $number';
  String refundNumber(String number) => 'Refund $number';
  final String cash = 'Cash';
  final String visa = 'Visa';
  final String voided = 'Voided';
  final String corrected = 'Corrected';
  final String invoiceVoided = 'Invoice voided';
  String byOn(String name, String time) => '$name · $time';
  String paidBack(String amount, String method) => '$amount paid back in $method';
  final String noPayback = 'No money paid back';
  String reducedBy(String amount) => 'Invoice value reduced by $amount';
  String reasonLine(String reason) => 'Reason: $reason';

  // Payment dialog
  final String amount = 'Amount (EGP)';
  final String method = 'Method';
  final String receivedAt = 'Received at';
  String dueNow(String amount) => '$amount due';
  final String payFull = 'Full amount';
  final String amountRequired = 'Enter an amount above zero';
  String amountTooHigh(String amount) => 'Enter $amount or less';
  final String paymentRecorded = 'Payment recorded';
  final String correctReceipt = 'Correct receipt';
  final String correctReceiptHelp =
      'The receipt is voided and replaced. The replacement keeps the original time received.';
  final String saveCorrection = 'Save correction';
  final String receiptCorrected = 'Receipt corrected';

  // Void dialog
  final String reason = 'Reason';
  final String reasonHint = 'Shown on the record and in the void log';
  final String reasonRequired = 'Enter a reason';
  final String voidReceiptTitle = 'Void receipt';
  final String voidRefundTitle = 'Void refund';
  String voidReceiptHelp(String amount) =>
      'The $amount payment is removed from this invoice and from daily totals. The receipt stays on record as voided.';
  final String voidRefundHelp =
      'The invoice value, any money paid back and the cancelled sessions are restored.';
  final String voidInvoiceHelp =
      "The invoice is excluded from all totals and its sessions leave the patient's balance. Its number is not reused.";
  final String receiptVoided = 'Receipt voided';
  final String refundVoided = 'Refund voided';
  final String invoiceVoidedDone = 'Invoice voided';

  // Refund form
  final String refundTitle = 'Refund';
  final String refundHelp =
      'Reduce what this invoice is worth. Money is paid back only when the patient has paid more than the new value.';
  final String refundLines = 'What to refund';
  String lineValue(String amount) => 'Value $amount';
  final String sessionsToCancel = 'Sessions to cancel';
  final String refundValue = 'Refund value (EGP)';
  String sessionsAvailable(int count) =>
      count == 1 ? '1 unused session can be cancelled' : '$count unused sessions can be cancelled';
  final String noSessionsAvailable = 'No unused sessions to cancel';
  String valueTooHigh(String amount) => 'Enter $amount or less';
  final String refundEmpty = 'Enter a refund value or sessions to cancel.';
  final String refundDetails = 'Refund details';
  final String paybackMethod = 'Pay back by';
  final String paybackMethodRequired = 'Choose how the money is paid back.';
  final String paybackNone =
      'No money is paid back. This refund only reduces what the patient owes.';
  final String refundSummary = 'Refund summary';
  final String currentValue = 'Invoice value now';
  final String newValue = 'New invoice value';
  final String payBack = 'Pay back to patient';
  final String leftToPay = 'Left to pay';
  final String sessionsRemoved = 'Removed from session balance';
  final String recordRefund = 'Record refund';
  final String refundRecorded = 'Refund recorded';
  final String decreaseSessions = 'Cancel one session fewer';
  final String increaseSessions = 'Cancel one more session';

  // Invoice correction
  String correctTitle(String number) => 'Correct $number';
  String correctHelp(String number) =>
      'Saving voids $number and issues a corrected invoice with a new number. Payments already received move to it. Services use current catalog prices.';
  String droppedServices(String names) =>
      'No longer sold and left out: $names. Add a replacement service if needed.';
  final String alreadyPaid = 'Already paid';
  final String correctionReason = 'Reason for correction';
  String belowPaid(String amount) =>
      'The corrected total must cover the $amount already paid. Void a payment first to go lower.';
  final String sessionsOnInvoice = 'Sessions on corrected invoice';
  final String issueCorrection = 'Issue corrected invoice';

  // Printed documents
  final String clinicDetails = 'Clinic address · Phone · Tax registration number';
  final String docReceipt = 'Receipt';
  final String docRefund = 'Refund';
  final String billedTo = 'Billed to';
  String fileNumber(int number) => 'File no. $number';
  final String forInvoice = 'For invoice';
  final String columnQty = 'Qty';
  final String columnUnitPrice = 'Unit price';
  final String columnAmount = 'Amount';
  final String columnDoctors = 'Doctors';
  final String columnSessions = 'Sessions cancelled';
  final String amountReceived = 'Amount received';
  final String balanceAfter = 'Invoice balance';
  final String recordedBy = 'Recorded by';
  final String paymentsReceived = 'Payments';
  final String voidWatermark = 'VOID';
  String page(int page, int pages) => 'Page $page of $pages';

  // Command errors returned by execute_invoice_command.
  Map<String, String> get errorKeys => const {
    'invoice_reason_required': 'Enter a reason of up to 500 characters.',
    'invoice_already_voided': 'This was already voided. The latest record is shown.',
    'invoice_has_payments': 'Void the payments and refunds on this invoice first.',
    'invoice_invoice_voided': 'This invoice is voided and cannot be changed.',
    'invoice_refund_limit':
        'A refund value or session count is more than the invoice line has left.',
    'invoice_refund_after':
        'A later refund depends on this record. Void that refund first.',
    'invoice_has_refunds': 'Void the refunds on this invoice before correcting it.',
    'invoice_correction_below_paid':
        'The corrected total is less than the money already received.',
    'invoice_sessions_in_use':
        'Some of these sessions are already used or booked. Cancel the future package bookings first.',
  };
}
