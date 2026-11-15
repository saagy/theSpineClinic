/// Text for the invoice detail view and its payment, refund, cancel and
/// edit actions.
final class InvoiceDetailStrings {
  const InvoiceDetailStrings();

  // Detail view
  String title(String number) => 'Invoice $number';
  final String invoice = 'Invoice';
  final String notFound = 'This invoice is no longer available.';
  final String openInvoice = 'Open invoice';
  final String openPatientPayments = "Open the patient's payments";
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
  String valueNow(String amount) => 'Value now $amount';
  String corrects(String number) => 'Replaces $number';
  String correctedBy(String number) => 'Replaced by $number';
  String voidedBy(String name, String time) => 'Cancelled by $name on $time';
  final String voidedInvoice = 'This invoice is cancelled and is not counted in any total.';

  // Actions
  final String recordPayment = 'Record payment';
  final String refund = 'Refund';
  final String print = 'Print';
  final String printInvoice = 'Print invoice';
  final String correctInvoice = 'Edit invoice';
  final String voidInvoice = 'Cancel invoice';
  final String correct = 'Edit';
  final String voidAction = 'Cancel';
  final String printFailed = 'The document could not be prepared. Try again.';
  final String voidNeedsNoRefunds = 'Cancel its refunds and discounts first';
  final String correctNeedsNoRefunds = 'Cancel its refunds and discounts first';
  final String lockedByRefund = 'Cancel the later refund or discount first';

  // Activity
  final String activity = 'Activity';
  final String created = 'Invoice created';
  String receipt(String number) => 'Receipt $number';
  String refundNumber(String number) => 'Refund $number';
  final String cash = 'Cash';
  final String visa = 'Visa';
  final String voided = 'Cancelled';
  final String corrected = 'Replaced';
  final String invoiceVoided = 'Invoice cancelled';
  String byOn(String name, String time) => '$name · $time';
  String paidBack(String amount, String method) => '$amount paid back in $method';
  final String noPayback = 'No money paid back';
  String reducedBy(String amount) => 'Invoice value reduced by $amount';
  String reasonLine(String reason) => 'Reason: $reason';
  String voidReasonLine(String reason) => 'Reason for cancelling: $reason';

  // Payment dialog
  final String amount = 'Amount (EGP)';
  final String method = 'Method';
  final String receivedAt = 'Received at';
  String dueNow(String amount) => '$amount due';
  final String payFull = 'Full amount';
  final String amountRequired = 'Enter an amount above zero';
  String amountTooHigh(String amount) => 'Enter $amount or less';
  final String paymentRecorded = 'Payment recorded';
  final String correctReceipt = 'Edit receipt';
  /// Shown before changing money that was taken on an earlier day.
  String pastDayCancelNotice(String day) =>
      "This payment was taken on $day. Cancelling it changes that day's totals. "
      'If the money was given back, record a refund instead.';
  String pastDayCorrectNotice(String day) =>
      "This payment was taken on $day. Correcting it changes that day's totals.";
  String pastDayInvoiceNotice(String day) =>
      "This invoice has a payment taken on $day. Cancelling it changes that day's totals.";
  final String correctReceiptHelp =
      'The old receipt is cancelled and a new one takes its place, with the same time received.';
  final String saveCorrection = 'Save changes';
  final String receiptCorrected = 'Receipt updated';

  // Cancel dialog
  final String reason = 'Reason';
  final String keepIt = 'Go back';
  final String reasonHint = 'Shown on the record and in the daily report';
  final String refundReasonHint = 'Shown on the refund and its printed copy';
  final String reasonRequired = 'Enter a reason';
  final String voidReceiptTitle = 'Cancel receipt';
  final String voidRefundTitle = 'Cancel refund';
  String voidReceiptHelp(String amount) =>
      'The $amount payment is removed from this invoice and from daily totals. The receipt stays on record as cancelled.';
  final String voidRefundHelp =
      'The invoice value, any money paid back and the cancelled sessions are restored.';
  final String voidInvoiceHelp =
      "The invoice is excluded from all totals and its sessions leave the patient's balance. Its number is not reused.";
  final String receiptVoided = 'Receipt cancelled';
  final String refundVoided = 'Refund cancelled';
  final String invoiceVoidedDone = 'Invoice cancelled';

  // Cancelling a paid invoice
  String paidCancelQuestion(String amount) =>
      'The patient paid $amount on this invoice. Was this money given back to the patient?';
  final String paidCancelMistake = 'No, the payment was entered by mistake';
  final String paidCancelMistakeHelp =
      'Cancel the invoice and its payments together. Nothing is paid back.';
  final String paidCancelGivenBack = 'Yes, the patient got the money back';
  final String paidCancelGivenBackHelp =
      'Record a refund, so the money paid back shows in the daily report.';
  final String cancelWithPayments = 'Cancel invoice and payments';
  String cancelWithPaymentsHelp(String amount) =>
      "The invoice and the $amount paid on it are cancelled and left out of all totals. Its sessions leave the patient's balance.";

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

  // Invoice edit
  String correctTitle(String number) => 'Edit $number';
  String correctHelp(String number) =>
      'Use this to fix a mistake. Saving cancels $number and creates a new invoice with a new number. Payments already received move to the new invoice. Services use current prices. To lower the price, use Add discount instead.';
  String droppedServices(String names) =>
      'No longer sold and left out: $names. Add a replacement service if needed.';
  final String alreadyPaid = 'Already paid';
  final String correctionReason = 'Reason for the change';
  String belowPaid(String amount) =>
      'The new total must cover the $amount already paid. Cancel a payment first to go lower.';
  final String sessionsOnInvoice = 'Sessions on the new invoice';
  final String issueCorrection = 'Save new invoice';

  // Printed documents
  final String clinicDetails = 'Clinic address · Phone · Tax registration number';
  final String docReceipt = 'Receipt';
  final String docRefund = 'Refund';
  final String billedTo = 'Billed to';
  String fileNumber(int number) => 'File no. $number';
  final String forInvoice = 'For invoice';
  final String documentDate = 'Date';
  final String columnQty = 'Qty';
  final String columnUnitPrice = 'Unit price';
  final String columnAmount = 'Amount';
  final String columnDoctors = 'Doctors';
  final String columnSessions = 'Sessions cancelled';
  final String amountReceived = 'Amount received';
  final String balanceAfter = 'Invoice balance';
  final String recordedBy = 'Recorded by';
  final String paymentsReceived = 'Payments';
  final String voidWatermark = 'CANCELLED';
  String page(int page, int pages) => 'Page $page of $pages';

  // Command errors returned by execute_invoice_command.
  Map<String, String> get errorKeys => const {
    'invoice_reason_required': 'Enter a reason of up to 500 characters.',
    'invoice_already_voided': 'This was already cancelled. The latest record is shown.',
    'invoice_has_payments': 'Cancel the payments, refunds and discounts on this invoice first.',
    'invoice_refunds_first': 'Cancel the refunds and discounts on this invoice first.',
    'invoice_invoice_voided': 'This invoice is cancelled and cannot be changed.',
    'invoice_refund_limit':
        'A refund value or session count is more than the invoice line has left.',
    'invoice_refund_after':
        'A later refund or discount depends on this record. Cancel that one first.',
    'invoice_has_refunds': 'Cancel the refunds and discounts on this invoice before editing it.',
    'invoice_correction_below_paid': 'The new total is less than the money already received.',
    'invoice_sessions_in_use':
        'Some of these sessions are already used or booked. Cancel the future package bookings first.',
  };
}
