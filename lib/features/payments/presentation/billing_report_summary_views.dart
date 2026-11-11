import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/app_routes.dart';
import '../../../core/utils/money.dart';
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

ReportView doctorsReportView(DoctorsReport report) {
  final bool moved = report.movedMinor != 0 || report.rows.any((row) => row.movedMinor != 0);
  final sheet = ReportSheet(
    columns: [
      ReportColumn(_t.colDoctor, role: ReportCellRole.title),
      _amount(_t.cash),
      _amount(_t.visa),
      if (moved) _amount(_t.moved),
      _amount(_t.colTotal, role: ReportCellRole.lead),
    ],
    rows: [
      for (final row in report.rows)
        ReportRow([
          ReportCell(
            row.doctorId == null ? _t.noDoctorCredit : row.name ?? '',
            tone: row.doctorId == null ? ReportTone.muted : ReportTone.normal,
          ),
          ReportCell.money(row.cashMinor),
          ReportCell.money(row.visaMinor),
          if (moved) ReportCell.money(row.movedMinor),
          ReportCell.money(row.shareMinor),
        ]),
    ],
    footer: [
      ReportCell(_t.totalRow),
      ReportCell.money(report.cashMinor),
      ReportCell.money(report.visaMinor),
      if (moved) ReportCell.money(report.movedMinor),
      ReportCell.money(report.totalMinor),
    ],
  );
  return ReportView(
    figures: [
      ReportFigure(_t.collected, Money.format(report.totalMinor)),
      ReportFigure(_t.toDoctors, Money.format(report.totalMinor - report.clinicOnlyMinor)),
      ReportFigure(_t.noDoctorCredit, Money.format(report.clinicOnlyMinor)),
    ],
    sections: [ReportSection(title: _t.sectionDoctors, sheet: sheet)],
    export: sheet,
  );
}

ReportView outstandingReportView(OutstandingReport report) {
  final sheet = ReportSheet(
    columns: [
      ReportColumn(_t.colPatient, role: ReportCellRole.title),
      ReportColumn(_t.colPatientId, width: AppSizes.reportCodeColumnWidth),
      ReportColumn(_t.colOldest, width: AppSizes.reportDateColumnWidth),
      ReportColumn(_t.openInvoices,
          width: AppSizes.reportAmountColumnWidth, numeric: true, role: ReportCellRole.figure),
      _amount(_t.amountDue, role: ReportCellRole.lead),
    ],
    rows: [
      for (final row in report.rows)
        ReportRow([
          ReportCell(row.patientName),
          reportPatientId(row.fileNumber),
          ReportCell.day(row.oldestDate),
          ReportCell.count(row.openInvoices),
          ReportCell.money(row.dueMinor, tone: ReportTone.warning),
        ], location: AppRoutes.patientDetail.replaceFirst(':id', Uri.encodeComponent(row.patientId))),
    ],
  );
  return ReportView(
    figures: [
      ReportFigure(_t.amountDue, Money.format(report.dueMinor),
          tone: report.dueMinor > 0 ? ReportTone.warning : ReportTone.normal),
      ReportFigure(_t.patients, '${report.rowCount}'),
      ReportFigure(_t.openInvoices, '${report.openInvoices}'),
    ],
    sections: [ReportSection(title: _t.sectionPatients, sheet: sheet)],
    export: sheet,
  );
}

ReportView servicesReportView(ServicesReport report) {
  final saleColumns = [
    ReportColumn(_t.colDate, width: AppSizes.reportDateColumnWidth),
    ReportColumn(_t.colInvoice, width: AppSizes.reportCodeColumnWidth),
    ReportColumn(_t.colPatient, role: ReportCellRole.title),
    ReportColumn(_t.colPatientId, width: AppSizes.reportCodeColumnWidth),
    _count(_t.colQuantity),
    _amount(_t.billed),
    _amount(_t.collected, role: ReportCellRole.lead),
  ];
  List<ReportCell> sale(ServiceSaleRow line) => [
    ReportCell.day(line.invoiceDate),
    ReportCell(line.party.invoiceNumber),
    ReportCell(line.party.patientName),
    reportPatientId(line.party.fileNumber),
    ReportCell.count(line.quantity),
    ReportCell.money(line.billedMinor),
    ReportCell.money(line.collectedMinor),
  ];
  final summary = ReportSheet(
    columns: [
      ReportColumn(_t.colService, role: ReportCellRole.title),
      ReportColumn(_t.colType),
      _count(_t.colUnits),
      _count(_t.colInvoices),
      _amount(_t.billed),
      _amount(_t.collected, role: ReportCellRole.lead),
    ],
    rows: [
      for (final row in report.rows)
        ReportRow(
          [
            ReportCell(row.name),
            ReportCell(ServiceType.fromDb(row.serviceType).label),
            ReportCell.count(row.units),
            ReportCell.count(row.invoiceCount),
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
      const ReportCell(''),
      ReportCell.money(report.billedMinor),
      ReportCell.money(report.collectedMinor),
    ],
  );
  final names = {for (final row in report.rows) row.serviceId: row.name};
  return ReportView(
    figures: [
      ReportFigure(_t.billed, Money.format(report.billedMinor)),
      ReportFigure(_t.collected, Money.format(report.collectedMinor)),
      ReportFigure(_t.uncollected, Money.format(report.billedMinor - report.collectedMinor)),
      ReportFigure(_t.unitsSold, '${report.units}'),
    ],
    sections: [ReportSection(title: _t.sectionServices, sheet: summary)],
    export: ReportSheet(
      columns: [ReportColumn(_t.colService), ...saleColumns],
      rows: [
        for (final line in report.lines)
          ReportRow([ReportCell(names[line.serviceId] ?? ''), ...sale(line)]),
      ],
    ),
  );
}
