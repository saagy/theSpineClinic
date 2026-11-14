import '../../appointment/domain/appointment_type.dart';

int _int(Object? value) => (value as num?)?.toInt() ?? 0;
DateTime _time(Object? value) => DateTime.parse(value! as String);
List<String> _names(Object? value) => [for (final name in value as List? ?? const []) '$name'];
AppointmentType _type(Object? value) => AppointmentType.values.firstWhere(
  (type) => type.dbValue == value,
  orElse: () => AppointmentType.normalPtSession,
);

/// The patient and time of one appointment in the doctor sessions report.
class SessionVisit {
  const SessionVisit({
    required this.appointmentId,
    required this.type,
    required this.at,
    required this.patientId,
    required this.patientName,
    required this.fileNumber,
  });

  factory SessionVisit.fromJson(Map<String, dynamic> json) => SessionVisit(
    appointmentId: json['appointment_id'] as String,
    type: _type(json['type']),
    at: _time(json['scheduled_at']),
    patientId: json['patient_id'] as String,
    patientName: json['patient_name'] as String? ?? '',
    fileNumber: _int(json['file_number']),
  );

  final String appointmentId;
  final AppointmentType type;
  final DateTime at;
  final String patientId;
  final String patientName;
  final int fileNumber;
}

/// Checked-in sessions credited to one doctor, by type. [pending] counts
/// past appointments of theirs that are still not checked in.
class DoctorSessionsRow {
  const DoctorSessionsRow({
    required this.doctorId,
    required this.name,
    required this.ptSessions,
    required this.assessments,
    required this.reassessments,
    required this.total,
    required this.shared,
    required this.pending,
  });

  factory DoctorSessionsRow.fromJson(Map<String, dynamic> json) => DoctorSessionsRow(
    doctorId: json['doctor_id'] as String,
    name: json['doctor_name'] as String? ?? '',
    ptSessions: _int(json['pt_sessions']),
    assessments: _int(json['assessments']),
    reassessments: _int(json['reassessments']),
    total: _int(json['total']),
    shared: _int(json['shared']),
    pending: _int(json['pending']),
  );

  final String doctorId;
  final String name;
  final int ptSessions;
  final int assessments;
  final int reassessments;
  final int total;

  /// Sessions this doctor shared with another doctor.
  final int shared;
  final int pending;
}

/// One checked-in session credited to one doctor.
class DoctorSessionRow {
  const DoctorSessionRow({required this.doctorId, required this.visit, required this.sharedWith});

  factory DoctorSessionRow.fromJson(Map<String, dynamic> json) => DoctorSessionRow(
    doctorId: json['doctor_id'] as String,
    visit: SessionVisit.fromJson(json),
    sharedWith: _names(json['shared_with']),
  );

  final String doctorId;
  final SessionVisit visit;

  /// The other doctors on the same appointment.
  final List<String> sharedWith;
}

/// A past appointment that is still scheduled, with its doctors.
class PendingSessionRow {
  const PendingSessionRow({required this.visit, required this.doctors});

  factory PendingSessionRow.fromJson(Map<String, dynamic> json) =>
      PendingSessionRow(visit: SessionVisit.fromJson(json), doctors: _names(json['doctors']));

  final SessionVisit visit;
  final List<String> doctors;
}
