final class BillingStrings {
  const BillingStrings();
  final String title = 'Billing';
  final String subtitle = 'Service invoices and collections';
  final String catalog = 'Service catalog';
  final String catalogSubtitle = 'Manage the services available for invoicing.';
  final String newService = 'Add service';
  final String editService = 'Edit service';
  final String searchServices = 'Search services';
  final String serviceName = 'Service name';
  final String unitPrice = 'Unit price (EGP)';
  final String active = 'Available for billing';
  final String inactive = 'Archived';
  final String noServices = 'No matching services';
  final String newInvoice = 'New invoice';
  final String searchInvoices = 'Search patient, ID number, invoice or doctor';
  final String noInvoices = 'No matching invoices';
  final String invoice = 'Invoice';
  final String draft = 'Draft';
  final String editDraft = 'Edit draft';
  final String saveDraft = 'Save draft';
  final String review = 'Review and issue';
  final String issue = 'Issue invoice';
  final String issueHelp =
      'Check the patient, services, and total before issuing. Corrections after issuance are recorded as returns.';
  final String branch = 'Branch';
  final String allBranches = 'All branches';
  final String allStatuses = 'All statuses';
  final String serviceDate = 'Service date';
  final String dateRange = 'Date range';
  final String clearDates = 'Clear dates';
  final String patient = 'Patient';
  final String file = 'ID number';
  final String doctor = 'Invoice doctor';
  final String consultant = 'Examining senior doctor';
  final String optional = 'Optional';
  final String pickPatient = 'Choose patient';
  final String pickDoctor = 'Choose doctor';
  final String pickConsultant = 'Choose senior doctor';
  final String inactiveSenior =
      'Choose an active senior doctor or clear the examining doctor.';
  final String searchPatient = 'Search name, phone or ID number';
  final String noActiveServices = 'No active services are available';
  final String askAdminForService =
      'Ask an admin to add or activate a service in the catalog.';
  final String allServicesSelected = 'No other active services are available';
  final String searchDoctor = 'Search doctors';
  final String noMatches = 'No matches found';
  final String services = 'Services';
  final String addService = 'Add service line';
  final String quantity = 'Quantity';
  final String remove = 'Remove service';
  final String discount = 'Invoice discount (%)';
  final String discountAmount = 'Discount amount';
  final String subtotal = 'Subtotal';
  final String total = 'Invoice total';
  final String collected = 'Collected';
  final String credited = 'Returned';
  final String refunded = 'Refunded';
  final String outstanding = 'Outstanding';
  final String refundable = 'Available to refund';
  final String settled = 'Settled';
  final String partialReturn = 'Partly returned';
  final String fullReturn = 'Fully returned';
  final String movements = 'Transaction history';
  final String noMovements = 'No receipts, returns, or refunds yet.';
  final String collect = 'Record receipt';
  final String credit = 'Issue return';
  final String refund = 'Record refund';
  final String receipt = 'Receipt';
  final String returnDocument = 'Return invoice';
  final String refundDocument = 'Refund';
  final String amount = 'Amount (EGP)';
  final String method = 'Payment method';
  final String cash = 'Cash';
  final String visa = 'Visa';
  final String reason = 'Reason';
  final String returnHelp =
      'Enter the quantity to return for each service. The return reduces outstanding debt first.';
  final String refundHelp =
      'Record the amount already paid back to the patient.';
  final String receiptHelp =
      'Record the amount actually received from the patient.';
  final String debtReduced = 'Applied to outstanding debt';
  final String number = 'Number';
  final String document = 'Document';
  final String recordedAt = 'Recorded at';
  final String recordedBy = 'Recorded by';
  final String print = 'Print / PDF';
  final String exportInvoices = 'Export invoices (CSV)';
  final String exportCollections = 'Export collections (CSV)';
  final String checkSave = 'Check save status';
  final String checking = 'Checking whether this was saved';
  final String noPending = 'No pending save was found.';
  final String cancelled =
      'The earlier save did not complete. Review and submit again.';
  final String stale =
      'This record changed. Refresh and review it before trying again.';
  final String catalogChanged =
      'A service changed or was archived. Review the latest catalog prices.';
  final String invalid = 'Check the invoice details and try again.';
  final String receiptLimit =
      'The receipt cannot exceed the outstanding balance.';
  final String refundLimit =
      'The refund cannot exceed the amount available to refund.';
  final String returnLimit =
      'The return cannot exceed the remaining service quantities.';
  final String exportLimit =
      'Narrow the filters before exporting more than 10,000 records.';
  final String busy = 'Another billing save is in progress.';
  final String invalidFields =
      'Check the highlighted fields before continuing.';
  final String positiveAmount = 'Enter a valid amount greater than zero.';
  final String nameRequired = 'Enter a service name.';
  final String quantityError = 'Enter a quantity from 1 to 1,000.';
  final String returnQuantityError =
      'Enter a quantity within the remaining amount.';
  final String discountError = 'Enter a percentage from 0 to 100.';
  final String reasonRequired = 'Enter a reason.';
  final String requiredDetails =
      'Choose a patient and doctor and add at least one service.';
  final String saved = 'Saved';
  final String saving = 'Saving…';
  final String partiallyPaid = 'Partially paid';
  final String previous = 'Previous';
  final String next = 'Next';
  final String page = 'Page';
  final String refreshPrices = 'Review latest prices';
  final String savedDraftNotice =
      'Save your changes before opening the issue review.';
  final String leaveTitle = 'Discard unsaved edits?';
  final String leaveHelp = 'Edits since your last save will be lost.';
  final String discard = 'Discard edits';
  final String keepEditing = 'Keep editing';
  final String unavailable = 'Billing is unavailable for this account.';
  final String awaiting = 'Awaiting payment';
  final String invoiceReference = 'Original invoice';
  final String issuedOn = 'Issued on';
  final String returnedQuantity = 'Returned quantity';
  final String service = 'Service';
  final String lineTotal = 'Line total';
  final String noItemsSelected =
      'Choose at least one service quantity to return.';
  final String currency = 'EGP';
  final String includeArchived = 'Include archived services';
  final String resultCount = 'records on this page';
  final String invalidDate = 'Choose a valid date';
  final String creditPreview = 'Return total';
  final String potentialRefund = 'Added to refundable balance';
  final String nothingToExport = 'There are no matching records to export.';
  final String reopen = 'Open saved invoice';
  final String pricesUpdated =
      'Catalog prices refreshed. Review the invoice before saving.';
  final String printRetry = 'The document is saved. Try printing again.';
  final String recoveryHelp =
      'Check the earlier save before starting a new one.';
}
