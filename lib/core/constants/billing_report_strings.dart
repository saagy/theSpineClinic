/// Text for the Billing tab reports.
final class BillingReportStrings {
  const BillingReportStrings();

  final String title = 'Billing reports';
  final String subtitle = 'Money, revenue, doctors, balances and services';

  // Reports
  final String money = 'Daily money';
  final String revenue = 'Revenue';
  final String doctor = 'Doctor revenue';
  final String doctors = 'Doctors summary';
  final String outstanding = 'Outstanding';
  final String services = 'Services';
  final String moneyHelp =
      'Money received and paid back, dated by when it changed hands.';
  final String revenueHelp =
      'Collected money by service. Refund payback is shown as a negative amount.';
  final String doctorHelp =
      'One doctor\'s share of collected money. A line\'s money is split equally among its doctors.';
  final String doctorsHelp = 'Collected money credited to each doctor.';
  final String outstandingHelp = 'Unpaid invoice balances as of now.';
  final String servicesHelp =
      'Services on invoices dated in this period. Collected is the money received for them to date.';
  final String reportMenu = 'Report';

  // Toolbar
  final String period = 'Period';
  final String today = 'Today';
  final String yesterday = 'Yesterday';
  final String last7Days = 'Last 7 days';
  final String thisMonth = 'This month';
  final String lastMonth = 'Last month';
  final String customRange = 'Custom range';
  final String customRangeHelp = 'Choose up to one year';
  final String rangeTooLong = 'Choose a period of one year or less.';
  final String branch = 'Branch';
  final String allBranches = 'All branches';
  final String doctorFilter = 'Doctor';
  final String allDoctors = 'All doctors';
  final String chooseDoctor = 'Choose doctor';
  final String clearDoctor = 'Clear doctor';
  final String export = 'Export CSV';
  final String print = 'Print';
  final String more = 'Export and print';
  final String refresh = 'Refresh';
  final String asOfNow = 'As of now';
  String rangeLabel(String from, String to) => from == to ? from : '$from – $to';

  // Feedback
  final String exported = 'Report exported';
  final String exportFailed = 'The report could not be exported. Try again.';
  final String printFailed = 'The report could not be prepared for printing. Try again.';
  final String nothingToExport = 'There is nothing to export for this period.';
  String truncated(int shown, int total) =>
      'Showing the first $shown of $total rows. Totals include every row. '
      'Choose a shorter period to see the rest.';

  // Empty states
  final String empty = 'Nothing recorded for this period';
  final String emptyHelp = 'Try another period or branch.';
  final String emptyOutstanding = 'No outstanding balances';
  final String emptyOutstandingHelp = 'Every invoice is settled.';
  final String pickDoctor = 'Choose a doctor';
  final String pickDoctorHelp = 'Doctor revenue shows one doctor at a time.';
  final String noMovements = 'No money received or paid back.';
  final String noVoids = 'Nothing was voided.';

  // Sections
  final String sectionMovements = 'Receipts and paybacks';
  final String sectionStaff = 'By receptionist';
  final String sectionVoids = 'Voided documents';
  final String sectionVoidsNote = 'Listed on the day they were voided. Not counted in any total.';
  final String sectionAllocations = 'Collected by service';
  final String sectionDoctors = 'Doctors';
  final String sectionPatients = 'Patients';
  final String sectionServices = 'Services';

  // Figures
  final String netCash = 'Net cash';
  final String netVisa = 'Net Visa';
  final String received = 'Received';
  final String paidBack = 'Paid back';
  final String collected = 'Collected';
  final String cash = 'Cash';
  final String visa = 'Visa';
  final String moved = 'Reallocated';
  final String doctorShare = 'Doctor share';
  final String toDoctors = 'Credited to doctors';
  final String noDoctorCredit = 'No doctor credit';
  final String amountDue = 'Amount due';
  final String patients = 'Patients';
  final String openInvoices = 'Open invoices';
  final String unitsSold = 'Units sold';
  final String billed = 'Billed';
  final String uncollected = 'Not yet collected';

  // Columns
  final String colWhen = 'Date and time';
  final String colDocument = 'Document';
  final String colPatient = 'Patient';
  final String colPatientId = 'Patient ID';
  final String colInvoice = 'Invoice';
  final String colRecordedBy = 'Recorded by';
  final String colMethod = 'Method';
  final String colAmount = 'Amount';
  final String colService = 'Service';
  final String colDoctors = 'Doctors';
  final String colPrice = 'Price';
  final String colShare = 'Share';
  final String colDoctor = 'Doctor';
  final String colTotal = 'Total';
  final String colOldest = 'Oldest unpaid';
  final String colType = 'Type';
  final String colUnits = 'Units';
  final String colInvoices = 'Invoices';
  final String colDate = 'Invoice date';
  final String colQuantity = 'Qty';
  final String colReceptionist = 'Receptionist';
  final String colCashIn = 'Cash in';
  final String colVisaIn = 'Visa in';
  final String colCashOut = 'Cash out';
  final String colVisaOut = 'Visa out';
  final String colNet = 'Net';
  final String colVoidedAt = 'Voided';
  final String colVoidedBy = 'Voided by';
  final String colReason = 'Reason';
  final String colBranch = 'Branch';
  final String totalRow = 'Total';

  // Values
  final String receipt = 'Receipt';
  final String refund = 'Refund';
  final String invoice = 'Invoice';
  String document(String kind, String number) => '$kind $number';
  final String rowsLabel = 'rows';
  final String showDetail = 'Show invoices';
  final String hideDetail = 'Hide invoices';
  final String openRecord = 'Opens the record';
  String printedAt(String time) => 'Printed $time';
  String fileName(String report, String from, String to) => '$report-$from-to-$to';
}
