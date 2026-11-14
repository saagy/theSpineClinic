import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/app_routes.dart';
import '../domain/billing_report_data.dart';
import 'billing_report_view.dart';
import 'billing_report_views.dart';

const _t = AppStrings.billingReports;

ReportColumn _count(String label, {ReportCellRole role = ReportCellRole.figure}) =>
    ReportColumn(label, width: AppSizes.reportSessionCountColumnWidth, numeric: true, role: role);

String _patientLocation(String patientId) => AppRoutes.patientLocation(patientId);

/// A count that needs attention when it is above zero.
ReportCell _pendingCell(int count) =>
    ReportCell('$count', tone: count > 0 ? ReportTone.warning : ReportTone.muted);

List<ReportCell> _visitCells(SessionVisit visit, bool singleDay) => [
  ReportCell.when(visit.at, timeOnly: singleDay),
  ReportCell.patient(visit.patientName, visit.fileNumber),
  ReportCell(visit.type.displayLabel),
];

List<ReportColumn> _visitColumns(bool singleDay) => [
  reportWhenColumn(singleDay: singleDay),
  ReportColumn(_t.colPatient, role: ReportCellRole.title),
  ReportColumn(
    _t.colType,
    width: AppSizes.reportSessionTypeColumnWidth,
    role: ReportCellRole.detail,
  ),
];

/// One doctor's checked-in sessions, oldest first.
ReportSheet _sessionSheet(List<DoctorSessionRow> lines, bool singleDay) {
  final bool shared = lines.any((line) => line.sharedWith.isNotEmpty);
  return ReportSheet(
    columns: [..._visitColumns(singleDay), if (shared) ReportColumn(_t.colSharedWith)],
    rows: [
      for (final line in lines)
        ReportRow([
          ..._visitCells(line.visit, singleDay),
          if (shared) ReportCell(line.sharedWith.join(', '), tone: ReportTone.muted),
        ], location: _patientLocation(line.visit.patientId)),
    ],
  );
}

ReportSection _pendingSection(DoctorSessionsReport report, bool singleDay) => ReportSection(
  title: _t.sectionPending,
  note: _t.sectionPendingNote,
  sheet: ReportSheet(
    columns: [..._visitColumns(singleDay), ReportColumn(_t.colDoctors)],
    rows: [
      for (final row in report.pending)
        ReportRow([
          ..._visitCells(row.visit, singleDay),
          ReportCell(row.doctors.join(', ')),
        ], location: _patientLocation(row.visit.patientId)),
    ],
  ),
);

ReportFigure _pendingFigure(int count) => ReportFigure(
  _t.notCheckedIn,
  '$count',
  tone: count > 0 ? ReportTone.warning : ReportTone.normal,
);

/// Sessions per doctor and type for doctor pay. For all doctors the screen
/// shows one row per doctor that opens their sessions, and the print adds
/// each doctor's sessions on a page of its own.
ReportView doctorSessionsReportView(DoctorSessionsReport report, {bool singleDay = false}) =>
    report.forDoctor ? _oneDoctor(report, singleDay) : _allDoctors(report, singleDay);

ReportView _oneDoctor(DoctorSessionsReport report, bool singleDay) => ReportView(
  figures: [
    ReportFigure(_t.checkedInSessions, '${report.credits}'),
    ReportFigure(_t.colPtSessions, '${report.ptSessions}'),
    ReportFigure(_t.colAssessments, '${report.assessments}'),
    ReportFigure(_t.colReassessments, '${report.reassessments}'),
    _pendingFigure(report.pendingCount),
  ],
  sections: [
    ReportSection(
      title: _t.sectionSessions,
      sheet: _sessionSheet(report.lines, singleDay),
      emptyMessage: _t.noDoctorSessions,
    ),
    _pendingSection(report, singleDay),
  ],
);

ReportView _allDoctors(DoctorSessionsReport report, bool singleDay) {
  final bool pending = report.rows.any((row) => row.pending > 0);
  int sum(int Function(DoctorSessionsRow row) pick) =>
      report.rows.fold(0, (total, row) => total + pick(row));
  final summary = ReportSheet(
    columns: [
      ReportColumn(_t.colDoctor, role: ReportCellRole.title),
      _count(_t.colPtSessions),
      _count(_t.colAssessments),
      _count(_t.colReassessments),
      if (pending) _count(_t.notCheckedIn),
      _count(_t.total, role: ReportCellRole.lead),
    ],
    detailHints: (show: _t.showSessions, hide: _t.hideSessions),
    rows: [
      for (final row in report.rows)
        ReportRow([
          ReportCell(row.name),
          ReportCell.count(row.ptSessions),
          ReportCell.count(row.assessments),
          ReportCell.count(row.reassessments),
          if (pending) _pendingCell(row.pending),
          ReportCell('${row.total}', tone: row.total == 0 ? ReportTone.muted : ReportTone.normal),
        ], detail: row.total == 0 ? null : _sessionSheet(report.linesOf(row.doctorId), singleDay)),
    ],
    footer: [
      ReportCell(_t.totalRow),
      ReportCell.count(sum((row) => row.ptSessions)),
      ReportCell.count(sum((row) => row.assessments)),
      ReportCell.count(sum((row) => row.reassessments)),
      // Per-doctor pending counts repeat shared appointments; the figure
      // above has the real number, so this column has no total.
      if (pending) const ReportCell(''),
      ReportCell.count(report.credits),
    ],
  );
  return ReportView(
    figures: [
      ReportFigure(_t.checkedInSessions, '${report.sessions}'),
      ReportFigure(_t.doctorsWorked, '${report.doctorCount}'),
      if (report.shared > 0) ReportFigure(_t.sharedSessions, '${report.shared}'),
      _pendingFigure(report.pendingCount),
    ],
    sections: [
      ReportSection(
        title: _t.sectionSessionDoctors,
        note: report.shared > 0 ? _t.sectionSharedNote : null,
        sheet: summary,
      ),
      _pendingSection(report, singleDay),
      for (final row in report.rows)
        if (row.total > 0)
          ReportSection(
            title: _t.doctorStatement(row.name),
            note: _t.statementNote(row.total, row.ptSessions, row.assessments, row.reassessments),
            sheet: _sessionSheet(report.linesOf(row.doctorId), singleDay),
            printOnly: true,
            newPage: true,
          ),
    ],
  );
}
