import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/money.dart';
import '../domain/billing_report_data.dart';
import 'billing_report_view.dart';
import 'billing_report_views.dart';

const _t = AppStrings.billingReports;

/// Revenue for all doctors (the split by doctor above every payment line)
/// or for one doctor (their lines with price, paid and their share).
ReportView revenueReportView(RevenueReport report, {required bool singleDay}) {
  final DoctorTotals? byDoctor = report.byDoctor;
  // A refund's adjustments add up to zero across the clinic, so the total
  // figure appears only where it is not zero (one doctor's share); the By
  // doctor column appears whenever a doctor gained or lost by them.
  final bool moved = report.movedMinor != 0;
  final bool movedByDoctor = byDoctor?.rows.any((row) => row.movedMinor != 0) ?? false;
  return ReportView(
    figures: [
      ReportFigure(
        byDoctor == null ? _t.doctorShare : _t.totalRevenue,
        Money.format(report.totalMinor),
      ),
      ReportFigure(_t.cash, Money.format(report.cashMinor)),
      ReportFigure(_t.visa, Money.format(report.visaMinor)),
      if (moved) ReportFigure(_t.moved, Money.format(report.movedMinor)),
    ],
    sections: [
      if (byDoctor != null)
        ReportSection(
          title: _t.sectionByDoctor,
          note: _t.sectionByDoctorNote,
          sheet: _doctorSheet(byDoctor, moved: movedByDoctor),
        ),
      ReportSection(
        title: _t.sectionAllocations,
        sheet: _lineSheet(report, singleDay: singleDay),
      ),
    ],
  );
}

ReportSheet _doctorSheet(DoctorTotals totals, {required bool moved}) => ReportSheet(
  columns: [
    ReportColumn(_t.colDoctor, role: ReportCellRole.title),
    reportAmountColumn(_t.cash),
    reportAmountColumn(_t.visa),
    if (moved) reportAmountColumn(_t.movedShort),
    reportAmountColumn(_t.total, role: ReportCellRole.lead),
  ],
  rows: [
    for (final row in totals.rows)
      ReportRow([
        ReportCell(
          row.doctorId == null ? _t.noDoctor : row.name ?? '',
          tone: row.doctorId == null ? ReportTone.muted : ReportTone.normal,
        ),
        ReportCell.money(row.cashMinor),
        ReportCell.money(row.visaMinor),
        if (moved) ReportCell.money(row.movedMinor),
        ReportCell.money(row.shareMinor),
      ], doctor: row.doctorId == null ? null : (id: row.doctorId!, name: row.name ?? '')),
  ],
  footer: [
    ReportCell(_t.totalRow),
    ReportCell.money(totals.cashMinor),
    ReportCell.money(totals.visaMinor),
    if (moved) ReportCell.money(totals.movedMinor),
    ReportCell.money(totals.totalMinor),
  ],
);

ReportSheet _lineSheet(RevenueReport report, {required bool singleDay}) {
  final bool one = report.forDoctor;
  return ReportSheet(
    columns: [
      reportWhenColumn(singleDay: singleDay),
      ReportColumn(_t.colPatient, role: ReportCellRole.title),
      ReportColumn(_t.colService, role: ReportCellRole.detail),
      if (!one) ReportColumn(_t.colDoctors, role: ReportCellRole.detail),
      ReportColumn(_t.colMethod, width: AppSizes.reportMethodColumnWidth),
      reportAmountColumn(_t.colPrice),
      reportAmountColumn(_t.paid, role: one ? ReportCellRole.figure : ReportCellRole.lead),
      if (one) reportAmountColumn(_t.colShare, role: ReportCellRole.lead),
    ],
    rows: [
      for (final row in report.rows)
        ReportRow([
          ReportCell.when(row.at, timeOnly: singleDay),
          ReportCell.patient(row.party.patientName, row.party.fileNumber),
          ReportCell(
            row.serviceName,
            sub: one && row.doctorCount > 1 ? _t.splitBetween(row.doctorCount) : null,
          ),
          if (!one)
            row.doctors.isEmpty
                ? ReportCell(_t.noDoctor, tone: ReportTone.muted)
                : ReportCell(row.doctors.join(', ')),
          ReportCell(reportMethodLabel(row.method)),
          ReportCell.money(row.priceMinor),
          ReportCell.money(row.amountMinor),
          if (one) ReportCell.money(row.shareMinor ?? 0),
        ], location: reportInvoiceLocation(row.party)),
    ],
  );
}
