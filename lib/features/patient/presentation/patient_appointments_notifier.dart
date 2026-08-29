import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_appointment_sort_option.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_appointments_state.dart';

part 'patient_appointments_notifier.g.dart';

@riverpod
class PatientAppointments extends _$PatientAppointments {
  int _generation = 0;
  static const int _pageSize = 30;

  @override
  PatientAppointmentsState build(String patientId) {
    Future.microtask(() => _fetchFirstPage());
    return const PatientAppointmentsState(isLoading: true);
  }

  Future<void> _fetchFirstPage({bool silent = false}) async {
    _generation++;
    final int currentGen = _generation;

    if (!silent || state.appointments.isEmpty) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    final AppointmentRepository repo = ref.read(appointmentRepositoryProvider);
    final countResult = await repo.countAppointmentsForPatient(
      patientId: patientId,
      statusFilter: state.statusFilter,
      typeFilter: state.typeFilter,
      dateFrom: state.dateFrom,
      dateTo: state.dateTo,
      doctorId: state.doctorId,
      usePackageFilter: state.usePackageFilter,
    );

    int totalCount = 0;
    countResult.when(
      success: (count) => totalCount = count,
      failure: (_) => totalCount = 0,
    );

    final result = await repo.getAppointmentsForPatientPaginated(
      patientId: patientId,
      offset: 0,
      limit: _pageSize,
      statusFilter: state.statusFilter,
      typeFilter: state.typeFilter,
      dateFrom: state.dateFrom,
      dateTo: state.dateTo,
      doctorId: state.doctorId,
      usePackageFilter: state.usePackageFilter,
      ascending: state.sort == PatientAppointmentSortOption.dateOldest,
    );

    if (currentGen != _generation) return;

    result.when(
      success: (List<AppointmentWithPatient> appointments) {
        state = state.copyWith(
          appointments: appointments,
          isLoading: false,
          totalCount: totalCount,
          hasMore: appointments.length < totalCount,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.message,
        );
      },
    );
  }

  void changeStatus(String appointmentId, AppointmentStatus newStatus) {
    final List<AppointmentWithPatient> updated = state.appointments
        .map(
          (AppointmentWithPatient item) =>
              item.appointment.id == appointmentId
                  ? AppointmentWithPatient(
                      appointment: item.appointment.copyWith(status: newStatus),
                      patient: item.patient,
                    )
                  : item,
        )
        .toList();
    state = state.copyWith(appointments: updated);
  }

  void _reloadDebounced() {
    _generation++;
    final int currentGen = _generation;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (currentGen == _generation) {
        _fetchFirstPage();
      }
    });
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    final AppointmentRepository repo = ref.read(appointmentRepositoryProvider);
    final offset = state.appointments.length;
    final result = await repo.getAppointmentsForPatientPaginated(
      patientId: patientId,
      offset: offset,
      limit: _pageSize,
      statusFilter: state.statusFilter,
      typeFilter: state.typeFilter,
      dateFrom: state.dateFrom,
      dateTo: state.dateTo,
      doctorId: state.doctorId,
      usePackageFilter: state.usePackageFilter,
      ascending: state.sort == PatientAppointmentSortOption.dateOldest,
    );

    result.when(
      success: (List<AppointmentWithPatient> newAppointments) {
        final all = [...state.appointments, ...newAppointments];
        state = state.copyWith(
          appointments: all,
          isLoadingMore: false,
          hasMore: all.length < state.totalCount,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: error.message,
        );
      },
    );
  }

  Future<void> refresh({bool silent = true}) async {
    await _fetchFirstPage(silent: silent);
  }

  void setStatusFilter(Set<AppointmentStatus>? status) {
    state = state.copyWith(statusFilter: status);
    _reloadDebounced();
  }

  void setTypeFilter(Set<AppointmentType>? type) {
    state = state.copyWith(typeFilter: type);
    _reloadDebounced();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(dateFrom: from, dateTo: to);
    _reloadDebounced();
  }

  void setDoctorFilter(String? doctorId) {
    state = state.copyWith(doctorId: doctorId);
    _reloadDebounced();
  }

  void setUsePackageFilter(bool? usePackage) {
    state = state.copyWith(usePackageFilter: usePackage);
    _reloadDebounced();
  }

  void setSort(PatientAppointmentSortOption sort) {
    state = state.copyWith(sort: sort);
    _reloadDebounced();
  }

  void clearFilters() {
    state = state.copyWith(
      statusFilter: null,
      typeFilter: null,
      dateFrom: null,
      dateTo: null,
      doctorId: null,
      usePackageFilter: null,
    );
    _fetchFirstPage();
  }
}
