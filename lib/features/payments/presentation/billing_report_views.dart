import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/app_routes.dart';
import '../../../core/utils/money.dart';
import '../domain/billing_report_data.dart';
import '../domain/invoice_documents.dart';
import 'billing_report_revenue_views.dart';
import 'billing_report_session_views.dart';
import 'billing_report_summary_views.dart';
import 'billing_report_view.dart';

const _t = AppStrings.billingReports;

/// Turns a report into figures and tables for the screen and print. Rows
/// of a [singleDay] report show only their time.
ReportView buildReportView(BillingReportData report, {bool singleDay = false}) => switch (report) {
  MoneyReport() => _money(report, singleDay),
  RevenueReport() => revenueReportView(report, singleDay: singleDay),
  DoctorSessionsReport() => doctorSessionsReportView(report, singleDay: singleDay),
  OutstandingReport() => outstandingReportView(report),
  ServicesReport() => servicesReportView(report),
};

String reportInvoiceLocation(ReportParty party) =>
    AppRoutes.invoiceDetailLocation(party.patientId, party.invoiceId);

String reportMethodLabel(PaymentMethod? method) => switch (method) {
  PaymentMethod.cash => _t.cash,
  PaymentMethod.visa => _t.visa,
  null => _t.movedShort,
};

/// Receipt, Refund or Discount, with its number beneath.
ReportCell reportDocument(ReportDocumentKind kind, String number) => ReportCell(switch (kind) {
  ReportDocumentKind.receipt => _t.receipt,
  ReportDocumentKind.refund => _t.refund,
  ReportDocumentKind.discount => _t.discount,
  ReportDocumentKind.invoice => _t.invoice,
}, sub: number);

/// The first column of rows dated by when something happened.
ReportColumn reportWhenColumn({required bool singleDay}) => singleDay
    ? ReportColumn(_t.colTime, width: AppSizes.reportClockColumnWidth)
    : ReportColumn(_t.colWhen, width: AppSizes.reportDateColumnWidth);

ReportColumn reportAmountColumn(String label, {ReportCellRole role = ReportCellRole.figure}) =>
    ReportColumn(label, width: AppSizes.reportAmountColumnWidth, numeric: true, role: role);

ReportView _money(MoneyReport report, bool singleDay) {
  final movements = ReportSheet(
    columns: [
      reportWhenColumn(singleDay: singleDay),
      ReportColumn(_t.colPatient, role: ReportCellRole.title),
      ReportColumn(
        _t.colDocument,
        width: AppSizes.reportDocumentColumnWidth,
        role: ReportCellRole.detail,
      ),
      ReportColumn(_t.colReceivedBy),
      ReportColumn(
        _t.colMethod,
        width: AppSizes.reportMethodColumnWidth,
        role: ReportCellRole.detail,
      ),
      reportAmountColumn(_t.colAmount, role: ReportCellRole.lead),
    ],
    rows: [
      for (final row in report.rows)
        ReportRow([
          ReportCell.when(row.at, timeOnly: singleDay),
          ReportCell.patient(row.party.patientName, row.party.fileNumber),
          reportDocument(row.kind, row.number),
          ReportCell(row.recordedBy),
          ReportCell(reportMethodLabel(row.method)),
          ReportCell.money(row.signedMinor),
        ], location: reportInvoiceLocation(row.party)),
    ],
  );
  final staff = ReportSheet(
    columns: [
      ReportColumn(_t.colReceptionist, role: ReportCellRole.title),
      reportAmountColumn(_t.cash),
      reportAmountColumn(_t.visa),
      reportAmountColumn(_t.total, role: ReportCellRole.lead),
    ],
    rows: [
      for (final row in report.staff)
        ReportRow([
          ReportCell(row.name),
          ReportCell.money(row.cashInMinor - row.cashOutMinor),
          ReportCell.money(row.visaInMinor - row.visaOutMinor),
          ReportCell.money(row.netMinor),
        ]),
    ],
    footer: [
      ReportCell(_t.totalRow),
      ReportCell.money(report.netCashMinor),
      ReportCell.money(report.netVisaMinor),
      ReportCell.money(report.netCashMinor + report.netVisaMinor),
    ],
  );
  final voids = ReportSheet(
    columns: [
      reportWhenColumn(singleDay: singleDay),
      ReportColumn(_t.colPatient, role: ReportCellRole.title),
      ReportColumn(
        _t.colDocument,
        width: AppSizes.reportDocumentColumnWidth,
        role: ReportCellRole.detail,
      ),
      ReportColumn(_t.colVoidedBy),
      ReportColumn(_t.colReason, role: ReportCellRole.detail),
      reportAmountColumn(_t.colAmount, role: ReportCellRole.lead),
    ],
    rows: [
      for (final row in report.voids)
        ReportRow([
          ReportCell.when(row.voidedAt, timeOnly: singleDay),
          ReportCell.patient(row.party.patientName, row.party.fileNumber),
          reportDocument(row.kind, row.number),
          ReportCell(row.voidedBy),
          ReportCell(row.reason),
          ReportCell.money(row.amountMinor, tone: ReportTone.muted),
        ], location: reportInvoiceLocation(row.party)),
    ],
  );
  String inOut(int inMinor, int outMinor) =>
      _t.inOut(Money.format(inMinor), Money.format(outMinor));
  return ReportView(
    figures: [
      ReportFigure(
        _t.cash,
        Money.format(report.netCashMinor),
        caption: inOut(report.cashInMinor, report.cashOutMinor),
      ),
      ReportFigure(
        _t.visa,
        Money.format(report.netVisaMinor),
        caption: inOut(report.visaInMinor, report.visaOutMinor),
      ),
      ReportFigure(
        _t.total,
        Money.format(report.netCashMinor + report.netVisaMinor),
        caption: inOut(report.receivedMinor, report.paidBackMinor),
      ),
    ],
    sections: [
      ReportSection(title: _t.sectionMovements, sheet: movements, emptyMessage: _t.noMovements),
      // One receptionist's totals already are the figures above.
      if (report.staff.length > 1)
        ReportSection(title: _t.sectionStaff, note: _t.sectionStaffNote, sheet: staff),
      ReportSection(title: _t.sectionVoids, note: _t.sectionVoidsNote, sheet: voids),
    ],
  );
}
