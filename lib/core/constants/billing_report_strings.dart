/// Text for the Billing tab reports. Front-desk staff are not native English
/// speakers: keep words short, common and free of finance jargon.
final class BillingReportStrings {
  const BillingReportStrings();

  final String title = 'Billing reports';
  final String subtitle =
      'Payments and refunds, revenue, doctor sessions, services and balances due';

  // Reports
  final String money = 'Payments & refunds';
  final String revenue = 'Revenue';
  final String sessions = 'Doctor sessions';
  final String services = 'Services';
  final String outstanding = 'Balances due';
  final String moneyHelp = 'Every payment received and every refund paid back.';
  final String revenueHelp =
      'What the money paid for, by service and doctor. The total matches Payments & refunds.';
  String doctorHelp(String name) =>
      'Money paid for $name\'s services. A service with two doctors is split equally.';
  final String sessionsHelp = 'Checked-in sessions each doctor did. Use it to work out doctor pay.';
  final String outstandingHelp = 'Patients who still owe money.';
  final String servicesHelp =
      'Services on invoices dated in this period, and how much is paid for them.';
  final String reportMenu = 'Report';

  // Toolbar
  final String period = 'Period';
  final String today = 'Today';
  final String yesterday = 'Yesterday';
  final String last7Days = 'Last 7 days';
  final String thisMonth = 'This month';
  final String lastMonth = 'Last month';
  final String customRange = 'Choose dates';
  final String customRangeHelp = 'Choose up to one year';
  final String rangeTooLong = 'Choose a period of one year or less.';
  final String branch = 'Branch';
  final String allBranches = 'All branches';
  final String doctorFilter = 'Doctor';
  final String allDoctors = 'All doctors';
  final String chooseDoctor = 'Choose doctor';
  final String clearDoctor = 'Show all doctors';
  final String print = 'Print';
  final String more = 'Refresh and print';
  final String refresh = 'Refresh';
  final String asOfNow = 'As of now';
  String rangeLabel(String from, String to) => from == to ? from : '$from – $to';

  // Feedback
  final String printFailed = 'The report could not be printed. Try again.';
  String truncated(int shown, int total) =>
      'Showing the first $shown of $total rows. Totals include every row. '
      'Choose a shorter period to see the rest.';

  // Empty states
  final String empty = 'Nothing in this period';
  final String emptyHelp = 'Try another period or branch.';
  final String emptyHelpPeriod = 'Try another period.';
  final String emptyOutstanding = 'No balances due';
  final String emptyOutstandingHelp = 'Every invoice is fully paid.';
  final String noMovements = 'No payments or refunds.';
  final String noDoctorSessions = 'No checked-in sessions in this period.';

  // Sections
  final String sectionMovements = 'All payments and refunds';
  final String sectionStaff = 'By receptionist';
  final String sectionStaffNote = 'Money received minus money paid back.';
  final String sectionVoids = 'Cancelled';
  final String sectionVoidsNote = 'Cancelled by mistake. Not counted in any total.';
  final String sectionByDoctor = 'By doctor';
  final String sectionByDoctorNote =
      'A service with two doctors is split equally. Tap a doctor to see their payments.';
  final String sectionAllocations = 'All payments';
  final String sectionPatients = 'Patients';
  final String sectionServices = 'Services';
  final String sectionSessionDoctors = 'Sessions by doctor';
  final String sectionSharedNote =
      'A session with two doctors counts once for each of them, so this total can be '
      'higher than the checked-in sessions above.';
  final String sectionSessions = 'Sessions';
  final String sectionPending = 'Not checked in yet';
  final String sectionPendingNote =
      'Past appointments still marked as scheduled. They are not counted. Check in the '
      'ones that happened and cancel the rest before working out pay.';
  String doctorStatement(String name) => 'Sessions · $name';
  String statementNote(int total, int pt, int assessments, int reassessments) =>
      'Total $total  ·  PT sessions $pt  ·  Assessments $assessments  ·  '
      'Reassessments $reassessments';

  // Figures
  final String cash = 'Cash';
  final String visa = 'Visa';
  final String total = 'Total';
  final String received = 'Received';
  final String paidBack = 'Refunded';

  /// Two lines, so neither half wraps on its own.
  String inOut(String received, String refunded) => 'Received $received\nRefunded $refunded';
  final String totalRevenue = 'Total revenue';
  final String doctorShare = 'Doctor\'s share';
  final String moved = 'Refund adjustments';
  final String movedShort = 'Refund adjustment';
  final String noDoctor = 'No doctor';
  final String amountDue = 'Balance due';
  final String patients = 'Patients';
  final String openInvoices = 'Open invoices';
  final String unitsSold = 'Quantity';
  final String totalPrice = 'Total price';
  final String paid = 'Paid';
  final String notPaidYet = 'Balance due';
  final String checkedInSessions = 'Checked-in sessions';
  final String doctorsWorked = 'Doctors';
  final String sharedSessions = 'Shared sessions';
  final String notCheckedIn = 'Not checked in';

  // Columns
  final String colWhen = 'Date';
  final String colTime = 'Time';
  final String colDocument = 'Document';
  final String colPatient = 'Patient';
  final String colInvoice = 'Invoice';
  final String colReceivedBy = 'Received by';
  final String colMethod = 'Method';
  final String colAmount = 'Amount';
  final String colService = 'Service';
  final String colDoctors = 'Doctor';
  final String colPrice = 'Total price';
  final String colShare = 'Share';
  final String colDoctor = 'Doctor';
  final String colOldest = 'Due since';
  final String colType = 'Type';
  final String colDate = 'Invoice date';
  final String colQuantity = 'Qty';
  final String colReceptionist = 'Receptionist';
  final String colPtSessions = 'PT sessions';
  final String colAssessments = 'Assessments';
  final String colReassessments = 'Reassessments';
  final String colSharedWith = 'Shared with';
  final String colVoidedBy = 'Cancelled by';
  final String colReason = 'Reason';
  final String totalRow = 'Total';
  String splitBetween(int doctors) => 'Split between $doctors doctors';

  // Values
  final String receipt = 'Receipt';
  final String refund = 'Refund';
  final String invoice = 'Invoice';
  final String rowsLabel = 'rows';
  final String showDetail = 'Show invoices';
  final String hideDetail = 'Hide invoices';
  final String showSessions = 'Show sessions';
  final String hideSessions = 'Hide sessions';
  final String openRecord = 'Opens the record';
  final String showDoctor = 'Shows this doctor\'s payments';
  String printedAt(String time) => 'Printed $time';
  String fileName(String report, String from, String to) => '$report-$from-to-$to';
}
