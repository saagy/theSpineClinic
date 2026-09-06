import 'package:flutter/foundation.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Encapsulates search and filter criteria for patient directory queries.
@immutable
class PatientFilters {
  const PatientFilters({
    this.clinic,
    this.doctorId,
    this.search,
  });

  final ClinicLocation? clinic;
  final String? doctorId;
  final String? search;

  bool get isEmpty =>
      clinic == null &&
      doctorId == null &&
      (search == null || search!.trim().isEmpty);

  bool get isNotEmpty => !isEmpty;

  PatientFilters copyWith({
    ClinicLocation? clinic,
    bool clearClinic = false,
    String? doctorId,
    bool clearDoctorId = false,
    String? search,
    bool clearSearch = false,
  }) {
    return PatientFilters(
      clinic: clearClinic ? null : (clinic ?? this.clinic),
      doctorId: clearDoctorId ? null : (doctorId ?? this.doctorId),
      search: clearSearch ? null : (search ?? this.search),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientFilters &&
          runtimeType == other.runtimeType &&
          clinic == other.clinic &&
          doctorId == other.doctorId &&
          search == other.search;

  @override
  int get hashCode => Object.hash(clinic, doctorId, search);

  @override
  String toString() =>
      'PatientFilters(clinic: , doctorId: , search: )';
}
