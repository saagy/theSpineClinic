import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';

/// What happened to a visit: booked, a status change, or deleted.
enum AppointmentEventKind {
  booked,
  status,
  deleted;

  static AppointmentEventKind fromDb(Object? value) =>
      values.firstWhere((kind) => kind.name == value, orElse: () => status);
}

AppointmentStatus? _status(Object? value) {
  for (final AppointmentStatus status in AppointmentStatus.values) {
    if (status.dbValue == value) return status;
  }
  return null;
}

/// One row of `appointment_events`, the visit's permanent history.
class AppointmentEvent {
  const AppointmentEvent({
    required this.kind,
    required this.at,
    this.fromStatus,
    this.toStatus,
    this.reason,
    this.actorName,
  });

  factory AppointmentEvent.fromJson(Map<String, dynamic> json) => AppointmentEvent(
    kind: AppointmentEventKind.fromDb(json['kind']),
    at: DateTime.parse(json['at'] as String),
    fromStatus: _status(json['from_status']),
    toStatus: _status(json['to_status']),
    reason: json['reason'] as String?,
    actorName: json['actor_name'] as String?,
  );

  final AppointmentEventKind kind;
  final DateTime at;
  final AppointmentStatus? fromStatus;
  final AppointmentStatus? toStatus;
  final String? reason;

  /// Null for changes made by the system (seeds, maintenance).
  final String? actorName;
}
