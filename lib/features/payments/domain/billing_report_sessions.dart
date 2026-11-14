part of 'billing_report_data.dart';

/// Checked-in sessions per doctor and type, from appointments, for doctor
/// pay. A session with two doctors counts once for each; [sessions] counts
/// each appointment once. [lines] may be capped; totals cover every row.
class DoctorSessionsReport extends BillingReportData {
  const DoctorSessionsReport({
    required super.rowCount,
    required this.sessions,
    required this.ptSessions,
    required this.assessments,
    required this.reassessments,
    required this.shared,
    required this.pendingCount,
    required this.doctorCount,
    required this.rows,
    required this.lines,
    required this.pending,
    required this.forDoctor,
  });

  factory DoctorSessionsReport.fromJson(Map<String, dynamic> json, {required bool forDoctor}) {
    final totals = json['totals'] as Map<String, dynamic>;
    return DoctorSessionsReport(
      rowCount: _int(totals['credits']),
      sessions: _int(totals['sessions']),
      ptSessions: _int(totals['pt_sessions']),
      assessments: _int(totals['assessments']),
      reassessments: _int(totals['reassessments']),
      shared: _int(totals['shared']),
      pendingCount: _int(totals['pending']),
      doctorCount: _int(totals['doctors']),
      rows: _list(json['rows'], DoctorSessionsRow.fromJson),
      lines: _list(json['sessions'], DoctorSessionRow.fromJson),
      pending: _list(json['pending'], PendingSessionRow.fromJson),
      forDoctor: forDoctor,
    );
  }

  /// Checked-in appointments, each counted once.
  final int sessions;
  final int ptSessions;
  final int assessments;
  final int reassessments;

  /// Checked-in appointments with more than one doctor.
  final int shared;

  /// Past appointments still not checked in.
  final int pendingCount;

  /// Doctors with at least one checked-in session.
  final int doctorCount;
  final List<DoctorSessionsRow> rows;
  final List<DoctorSessionRow> lines;
  final List<PendingSessionRow> pending;

  /// The report was asked for one doctor.
  final bool forDoctor;

  /// Session credits: a shared session counts for each of its doctors.
  int get credits => rowCount;

  List<DoctorSessionRow> linesOf(String doctorId) =>
      lines.where((line) => line.doctorId == doctorId).toList();

  @override
  int get shownCount => lines.length;

  @override
  bool get isEmpty => rows.isEmpty;
}
