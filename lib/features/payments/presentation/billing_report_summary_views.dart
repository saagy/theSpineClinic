import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/app_routes.dart';
import '../../../core/utils/money.dart';
import '../../patient/presentation/patient_workspace_tab.dart';
import '../domain/billing_report_data.dart';
import '../domain/service_catalog_item.dart';
import 'billing_report_view.dart';
import 'billing_report_views.dart';
import 'widgets/service_catalog_labels.dart';

const _t = AppStrings.billingReports;

ReportColumn _amount(String label, {ReportCellRole role = ReportCellRole.figure}) =>
    ReportColumn(label, width: AppSizes.reportAmountColumnWidth, numeric: true, role: role);

ReportColumn _count(String label) => ReportColumn(
  label,
  width: AppSizes.reportCountColumnWidth,
  numeric: true,
  role: ReportCellRole.figure,
);

ReportView outstandingReportView(OutstandingReport report) {
  final sheet = ReportSheet(
    columns: [
      ReportColumn(_t.colPatient, role: ReportCellRole.title),
      // A figure, so stacked rows say what the date means.
      ReportColumn(
        _t.colOldest,
        width: AppSizes.reportDateColumnWidth,
        role: ReportCellRole.figure,
      ),
      ReportColumn(
        _t.openInvoices,
        width: AppSizes.reportAmountColumnWidth,
        numeric: true,
        role: ReportCellRole.figure,
      ),
      _amount(_t.amountDue, role: ReportCellRole.lead),
    ],
    rows: [
      for (final row in report.rows)
        ReportRow(
          [
            ReportCell.patient(row.patientName, row.fileNumber),
            ReportCell.day(row.oldestDate),
            ReportCell.count(row.openInvoices),
            ReportCell.money(row.dueMinor, tone: ReportTone.warning),
          ],
          // An unpaid balance opens on the patient's invoices.
          location: AppRoutes.patientLocation(
            row.patientId,
            tab: PatientWorkspaceTab.payments.name,
          ),
        ),
    ],
  );
  return ReportView(
    figures: [
      ReportFigure(
        _t.amountDue,
        Money.format(report.dueMinor),
        tone: report.dueMinor > 0 ? ReportTone.warning : ReportTone.normal,
      ),
      ReportFigure(_t.patients, '${report.rowCount}'),
      ReportFigure(_t.openInvoices, '${report.openInvoices}'),
    ],
    sections: [ReportSection(title: _t.sectionPatients, sheet: sheet)],
  );
}

ReportView servicesReportView(ServicesReport report) {
  final saleColumns = [
    ReportColumn(_t.colDate, width: AppSizes.reportDateColumnWidth),
    ReportColumn(_t.colInvoice, width: AppSizes.reportCodeColumnWidth),
    ReportColumn(_t.colPatient, role: ReportCellRole.title),
    _count(_t.colQuantity),
    _amount(_t.colPrice),
    _amount(_t.paid, role: ReportCellRole.lead),
  ];
  List<ReportCell> sale(ServiceSaleRow line) => [
    ReportCell.day(line.invoiceDate),
    ReportCell(line.party.invoiceNumber),
    ReportCell.patient(line.party.patientName, line.party.fileNumber),
    ReportCell.count(line.quantity),
    ReportCell.money(line.billedMinor),
    ReportCell.money(line.collectedMinor),
  ];
  final summary = ReportSheet(
    columns: [
      ReportColumn(_t.colService, role: ReportCellRole.title),
      ReportColumn(_t.colType, role: ReportCellRole.detail),
      _count(_t.unitsSold),
      _amount(_t.totalPrice),
      _amount(_t.paid, role: ReportCellRole.lead),
    ],
    rows: [
      for (final row in report.rows)
        ReportRow(
          [
            ReportCell(row.name),
            ReportCell(ServiceType.fromDb(row.serviceType).label),
            ReportCell.count(row.units),
            ReportCell.money(row.billedMinor),
            ReportCell.money(row.collectedMinor),
          ],
          detail: ReportSheet(
            columns: saleColumns,
            rows: [
              for (final line in report.linesOf(row.serviceId))
                ReportRow(sale(line), location: reportInvoiceLocation(line.party)),
            ],
          ),
        ),
    ],
    footer: [
      ReportCell(_t.totalRow),
      const ReportCell(''),
      ReportCell.count(report.units),
      ReportCell.money(report.billedMinor),
      ReportCell.money(report.collectedMinor),
    ],
  );
  return ReportView(
    figures: [
      ReportFigure(_t.totalPrice, Money.format(report.billedMinor)),
      ReportFigure(_t.paid, Money.format(report.collectedMinor)),
      ReportFigure(
        _t.notPaidYet,
        Money.format(report.billedMinor - report.collectedMinor),
        tone: report.billedMinor > report.collectedMinor ? ReportTone.warning : ReportTone.normal,
      ),
      ReportFigure(_t.unitsSold, '${report.units}'),
    ],
    sections: [ReportSection(title: _t.sectionServices, sheet: summary)],
  );
}
