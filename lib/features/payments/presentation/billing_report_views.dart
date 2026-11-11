import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/app_routes.dart';
import '../../../core/utils/money.dart';
import '../domain/billing_report_data.dart';
import '../domain/invoice_documents.dart';
import 'billing_report_summary_views.dart';
import 'billing_report_view.dart';

const _t = AppStrings.billingReports;

/// Turns a report into figures and tables for the screen, CSV and print.
ReportView buildReportView(BillingReportData report) => switch (report) {
  MoneyReport() => _money(report),
  RevenueReport() => _revenue(report),
  DoctorsReport() => doctorsReportView(report),
  OutstandingReport() => outstandingReportView(report),
  ServicesReport() => servicesReportView(report),
};

String reportInvoiceLocation(ReportParty party) =>
    AppRoutes.invoiceDetailLocation(party.patientId, party.invoiceId);

String reportMethodLabel(PaymentMethod? method) => switch (method) {
  PaymentMethod.cash => _t.cash,
  PaymentMethod.visa => _t.visa,
  null => _t.moved,
};

String reportDocumentLabel(ReportDocumentKind kind, String number) => _t.document(
  switch (kind) {
    ReportDocumentKind.receipt => _t.receipt,
    ReportDocumentKind.refund => _t.refund,
    ReportDocumentKind.invoice => _t.invoice,
  },
  number,
);

ReportCell reportPatientId(int fileNumber) =>
    ReportCell(AppStrings.patientIdLabel(fileNumber), csv: '$fileNumber');

ReportView _money(MoneyReport report) {
  final movements = ReportSheet(
    columns: [
      ReportColumn(_t.colWhen, width: AppSizes.reportTimeColumnWidth),
      ReportColumn(_t.colDocument, width: AppSizes.reportDocumentColumnWidth),
      ReportColumn(_t.colPatient, role: ReportCellRole.title),
      ReportColumn(_t.colPatientId, width: AppSizes.reportCodeColumnWidth),
      ReportColumn(_t.colInvoice, exportOnly: true),
      ReportColumn(_t.colBranch, exportOnly: true),
      ReportColumn(_t.colRecordedBy),
      ReportColumn(_t.colMethod, width: AppSizes.reportMethodColumnWidth),
      ReportColumn(_t.colAmount,
          width: AppSizes.reportAmountColumnWidth, numeric: true, role: ReportCellRole.lead),
    ],
    rows: [
      for (final row in report.rows)
        ReportRow([
          ReportCell.time(row.at),
          ReportCell(reportDocumentLabel(row.kind, row.number)),
          ReportCell(row.party.patientName),
          reportPatientId(row.party.fileNumber),
          ReportCell(row.party.invoiceNumber),
          ReportCell(row.branch.displayLabel),
          ReportCell(row.recordedBy),
          ReportCell(reportMethodLabel(row.method)),
          ReportCell.money(row.signedMinor),
        ], location: reportInvoiceLocation(row.party)),
    ],
  );
  final staff = ReportSheet(
    columns: [
      ReportColumn(_t.colReceptionist, role: ReportCellRole.title),
      for (final label in [_t.colCashIn, _t.colVisaIn, _t.colCashOut, _t.colVisaOut])
        ReportColumn(label,
            width: AppSizes.reportAmountColumnWidth, numeric: true, role: ReportCellRole.figure),
      ReportColumn(_t.colNet,
          width: AppSizes.reportAmountColumnWidth, numeric: true, role: ReportCellRole.lead),
    ],
    rows: [
      for (final row in report.staff)
        ReportRow([
          ReportCell(row.name),
          ReportCell.money(row.cashInMinor),
          ReportCell.money(row.visaInMinor),
          ReportCell.money(row.cashOutMinor),
          ReportCell.money(row.visaOutMinor),
          ReportCell.money(row.netMinor),
        ]),
    ],
    footer: report.staff.length < 2
        ? null
        : [
            ReportCell(_t.totalRow),
            ReportCell.money(report.cashInMinor),
            ReportCell.money(report.visaInMinor),
            ReportCell.money(report.cashOutMinor),
            ReportCell.money(report.visaOutMinor),
            ReportCell.money(report.netCashMinor + report.netVisaMinor),
          ],
  );
  final voids = ReportSheet(
    columns: [
      ReportColumn(_t.colVoidedAt, width: AppSizes.reportTimeColumnWidth),
      ReportColumn(_t.colDocument, width: AppSizes.reportDocumentColumnWidth),
      ReportColumn(_t.colPatient, role: ReportCellRole.title),
      ReportColumn(_t.colVoidedBy),
      ReportColumn(_t.colReason),
      ReportColumn(_t.colAmount,
          width: AppSizes.reportAmountColumnWidth, numeric: true, role: ReportCellRole.lead),
    ],
    rows: [
      for (final row in report.voids)
        ReportRow([
          ReportCell.time(row.voidedAt),
          ReportCell(reportDocumentLabel(row.kind, row.number)),
          ReportCell(row.party.patientName),
          ReportCell(row.voidedBy),
          ReportCell(row.reason),
          ReportCell.money(row.amountMinor, tone: ReportTone.muted),
        ], location: reportInvoiceLocation(row.party)),
    ],
  );
  return ReportView(
    figures: [
      ReportFigure(_t.netCash, Money.format(report.netCashMinor)),
      ReportFigure(_t.netVisa, Money.format(report.netVisaMinor)),
      ReportFigure(_t.received, Money.format(report.receivedMinor)),
      ReportFigure(_t.paidBack, Money.format(report.paidBackMinor)),
    ],
    sections: [
      ReportSection(title: _t.sectionMovements, sheet: movements, emptyMessage: _t.noMovements),
      ReportSection(title: _t.sectionStaff, sheet: staff),
      ReportSection(
        title: _t.sectionVoids,
        note: _t.sectionVoidsNote,
        sheet: voids,
        emptyMessage: _t.noVoids,
      ),
    ],
    export: movements,
  );
}

ReportView _revenue(RevenueReport report) {
  final bool doctor = report.forDoctor;
  final sheet = ReportSheet(
    columns: [
      ReportColumn(_t.colWhen, width: AppSizes.reportTimeColumnWidth),
      ReportColumn(_t.colDocument, exportOnly: true),
      ReportColumn(_t.colPatient, role: ReportCellRole.title),
      ReportColumn(_t.colPatientId, width: AppSizes.reportCodeColumnWidth),
      ReportColumn(_t.colInvoice, exportOnly: true),
      ReportColumn(_t.colService),
      ReportColumn(_t.colDoctors, exportOnly: doctor),
      ReportColumn(_t.colMethod, width: AppSizes.reportMethodColumnWidth),
      ReportColumn(_t.colPrice,
          width: AppSizes.reportAmountColumnWidth,
          numeric: true,
          role: ReportCellRole.figure,
          exportOnly: doctor),
      ReportColumn(_t.collected,
          width: AppSizes.reportAmountColumnWidth,
          numeric: true,
          role: doctor ? ReportCellRole.figure : ReportCellRole.lead),
      if (doctor)
        ReportColumn(_t.colShare,
            width: AppSizes.reportAmountColumnWidth, numeric: true, role: ReportCellRole.lead),
    ],
    rows: [
      for (final row in report.rows)
        ReportRow([
          ReportCell.time(row.at),
          ReportCell(row.kind == ReportDocumentKind.refund ? _t.refund : _t.receipt),
          ReportCell(row.party.patientName),
          reportPatientId(row.party.fileNumber),
          ReportCell(row.party.invoiceNumber),
          ReportCell(row.serviceName),
          ReportCell(row.doctors.join(', ')),
          ReportCell(reportMethodLabel(row.method)),
          ReportCell.money(row.priceMinor),
          ReportCell.money(row.amountMinor),
          if (doctor) ReportCell.money(row.shareMinor ?? 0),
        ], location: reportInvoiceLocation(row.party)),
    ],
  );
  return ReportView(
    figures: [
      ReportFigure(doctor ? _t.doctorShare : _t.collected, Money.format(report.totalMinor)),
      ReportFigure(_t.cash, Money.format(report.cashMinor)),
      ReportFigure(_t.visa, Money.format(report.visaMinor)),
      if (report.movedMinor != 0) ReportFigure(_t.moved, Money.format(report.movedMinor)),
    ],
    sections: [ReportSection(title: _t.sectionAllocations, sheet: sheet)],
    export: sheet,
  );
}
