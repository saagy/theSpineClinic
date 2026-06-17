import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'patient_appointment_sort_option.dart';

part 'patient_appointments_state.freezed.dart';

@freezed
abstract class PatientAppointmentsState with _$PatientAppointmentsState {
  const factory PatientAppointmentsState({
    @Default([]) List<Appointment> appointments,
    @Default(true) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasMore,
    @Default(0) int totalCount,
    String? errorMessage,
    Set<AppointmentStatus>? statusFilter,
    Set<AppointmentType>? typeFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? doctorId,
    bool? usePackageFilter,
    @Default(PatientAppointmentSortOption.dateNewest) PatientAppointmentSortOption sort,
  }) = _PatientAppointmentsState;
}
