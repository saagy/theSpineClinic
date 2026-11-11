/// Text for the redesigned invoice workflow and its service catalog.
final class InvoiceStrings {
  const InvoiceStrings();

  final String billing = 'Billing';

  // Service catalog
  final String services = 'Services and prices';
  final String servicesSubtitle = 'Services and packages available on invoices';
  final String servicesShort = 'Services';
  final String addService = 'Add service';
  final String editService = 'Edit service';
  final String searchServices = 'Search services';
  final String show = 'Show';
  final String showActive = 'Active';
  final String showArchived = 'Archived';
  final String showAll = 'All services';
  final String archived = 'Archived';
  final String columnService = 'Service';
  final String columnSoldAs = 'Sold as';
  final String columnDoctors = 'Doctor credit';
  final String columnPrice = 'Price';
  final String singleSession = 'Single session';
  final String singleService = 'Single service';
  final String credited = 'Credited';
  final String notCredited = 'Not credited';
  final String noDoctorCredit = 'No doctor credit';
  final String noServices = 'No services yet';
  final String noServicesHelp =
      'Add the sessions, packages and other services the clinic sells.';
  final String noMatches = 'No services match';
  final String noArchived = 'No archived services';
  final String noActive = 'No active services. Show archived services to restore one.';
  final String clearSearch = 'Clear search';
  String packageOf(int sessions) => '$sessions-session package';
  String perSession(String amount) => '$amount per session';
  String countLabel(int count) => count == 1 ? '1 service' : '$count services';

  // Service types
  final String typePt = 'PT session';
  final String typeTraction = 'Spinal traction';
  final String typeInitial = 'Initial assessment';
  final String typeReassessment = 'Reassessment';
  final String typeOther = 'Other service';
  final String groupPt = 'Physical therapy';
  final String groupTraction = 'Spinal traction';
  final String groupAssessments = 'Assessments';
  final String groupOther = 'Other services';

  // Service form
  final String serviceFormHelp =
      'Services appear on new invoices. Issued invoices keep the name and price they were issued with.';
  final String sectionService = 'Service';
  final String name = 'Name';
  final String nameHint = 'For example, 6 PT sessions';
  final String nameRequired = 'Enter a service name';
  final String type = 'Type';
  final String sectionPrice = 'Price';
  final String soldAs = 'Sold as';
  final String package = 'Package';
  final String sessionsInPackage = 'Sessions in package';
  final String sessionsInvalid = 'Enter between 2 and 100 sessions';
  final String price = 'Price (EGP)';
  final String priceInvalid = 'Enter a price above zero';
  final String packageHelp =
      'Invoicing a package adds all its sessions to the patient balance.';
  final String priceChangeHelp =
      'A new price applies to new invoices only.';
  final String sectionCredit = 'Doctor credit';
  final String creditDoctors = 'Credit doctors for this service';
  final String creditHelp =
      "Doctors chosen on the invoice share this service's collected revenue. Turn this off for services done without a doctor, such as spinal traction.";
  final String sectionAvailability = 'Availability';
  final String availableOnInvoices = 'Available on new invoices';
  final String availabilityHelp =
      'Archived services stay on existing invoices and in reports.';
  final String serviceNotFound = 'This service is no longer available.';
  final String serviceSaved = 'Service saved';
  final String serviceAdded = 'Service added';

  // Patient Payments tab
  final String amountDue = 'Amount due';
  final String paid = 'Paid';
  final String ptSessionsLeft = 'PT sessions left';
  final String tractionSessionsLeft = 'Traction sessions left';
  final String invoices = 'Invoices';
  final String newInvoice = 'New invoice';
  final String noInvoices = 'No invoices yet';
  final String noInvoicesHelp =
      'Create an invoice for the services this patient receives. Payment can be recorded now or later.';
  final String columnInvoice = 'Invoice';
  final String columnServices = 'Services';
  final String columnTotal = 'Total';
  final String columnDue = 'Due';
  final String columnStatus = 'Status';
  final String statusPaid = 'Paid';
  final String statusPartial = 'Partly paid';
  final String statusUnpaid = 'Unpaid';
  final String statusRefunded = 'Refunded';
  final String statusVoided = 'Voided';
  String totalPaidLine(String total, String paid) => 'Total $total · Paid $paid';
  String dueLabel(String amount) => '$amount due';

  // New invoice form
  final String invoiceDetails = 'Invoice details';
  final String branch = 'Branch';
  final String invoiceDate = 'Invoice date';
  final String chooseService = 'Choose a service';
  final String addLine = 'Add service';
  final String linesRequired = 'Add at least one service.';
  final String quantity = 'Quantity';
  String each(String amount) => '$amount each';
  final String decrease = 'Decrease quantity';
  final String increase = 'Increase quantity';
  final String removeLine = 'Remove service';
  final String doctors = 'Doctors';
  final String doctorsHelp =
      "Optional. Selected doctors share this service's collected revenue equally.";
  final String noActiveServices =
      'No services are available. A payment receptionist can add them in Services and prices.';
  final String sectionDiscount = 'Discount';
  final String discountNone = 'No discount';
  final String discountPercent = 'Percentage';
  final String discountAmount = 'Fixed amount';
  final String discountPercentLabel = 'Discount (%)';
  final String discountAmountLabel = 'Discount (EGP)';
  final String discountPercentInvalid = 'Enter a percentage from 0.01 to 100';
  final String discountAmountInvalid = 'Enter an amount up to the subtotal';
  final String freeHint = 'A 100% discount records free sessions.';
  final String sectionPayment = 'Payment now';
  final String paymentHelp =
      'Optional. Record money received with this invoice. Anything left stays due.';
  final String cash = 'Cash (EGP)';
  final String visa = 'Visa (EGP)';
  final String payInFull = 'Pay full amount in cash';
  final String amountInvalid = 'Enter a valid amount';
  final String paymentTooHigh = 'Payments are more than the invoice total.';
  final String note = 'Note';
  final String noteHint = 'Optional';
  final String summary = 'Summary';
  final String subtotal = 'Subtotal';
  final String discount = 'Discount';
  final String total = 'Total';
  final String paidNow = 'Paid now';
  final String dueAfter = 'Left to pay';
  final String sessionsAdded = 'Added to session balance';
  String ptSessions(int count) => count == 1 ? '1 PT session' : '$count PT sessions';
  String tractionSessions(int count) =>
      count == 1 ? '1 traction session' : '$count traction sessions';
  final String createInvoice = 'Create invoice';
  final String invoiceCreated = 'Invoice created';

  // Command errors returned by execute_invoice_command.
  final String errorDuplicate = 'Another service already has this name.';
  final String errorStale =
      'This record changed on another device. Reopen it to see the latest version.';
  final String errorInvalid = 'Check the details and try again.';
  final String errorCancelled =
      'The earlier attempt did not go through. Save again.';
  final String errorBusy = 'A save is already in progress.';
  final String errorDenied = 'Your account cannot make this change.';

  final String errorCatalogChanged =
      'A service price or availability changed. The latest prices are loaded; review the services and try again.';
  final String errorDiscountNotAllowed = 'Only payment receptionists can give discounts.';
  final String errorInvalidDoctors = 'A selected doctor is no longer available. Review the doctors.';
  final String errorInvalidDiscount = 'Check the discount.';
  final String errorInvalidInvoice = 'Check the invoice date and services.';
  final String errorReceiptLimit = 'A payment is more than the amount due.';

  Map<String, String> get errorKeys => {
    'invoice_catalog_changed': errorCatalogChanged,
    'invoice_discount_not_allowed': errorDiscountNotAllowed,
    'invoice_invalid_doctors': errorInvalidDoctors,
    'invoice_invalid_discount': errorInvalidDiscount,
    'invoice_invalid_invoice': errorInvalidInvoice,
    'invoice_receipt_limit': errorReceiptLimit,
    'invoice_duplicate': errorDuplicate,
    'invoice_stale': errorStale,
    'invoice_invalid_request': errorInvalid,
    'invoice_cancelled': errorCancelled,
    'invoice_busy': errorBusy,
    'invoice_denied': errorDenied,
  };
}
