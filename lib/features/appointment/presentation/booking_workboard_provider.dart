import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/bulk_doctor_replacement_result.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_state.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

part 'booking_workboard_provider.g.dart';

@riverpod
class BookingWorkboard extends _$BookingWorkboard {
  late ClinicLocation? _clinic;
  int _refreshGeneration = 0;

  @override
  BookingWorkboardState build() {
    final user = ref.watch(currentUserProvider).value;
    final activeBranch = ref.watch(activeBranchProvider);
    final adminBranch = ref.watch(adminBranchFilterProvider);
    _clinic = user == null
        ? null
        : user.role == UserRole.superAdmin
        ? ClinicLocation.values
              .where((branch) => branch.dbValue == adminBranch)
              .firstOrNull
        : activeBranch;
    final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
    final BookingWorkboardState initial = BookingWorkboardState(
      date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
    );
    if (_clinic != null) Future.microtask(refresh);
    return initial;
  }

  Future<void> setDoctorFilter(String? doctorId) async {
    _refreshGeneration++;
    state = doctorId == null
        ? state.copyWith(clearDoctor: true)
        : state.copyWith(doctorId: doctorId);
    await refresh();
  }

  Future<void> selectDate(DateTime date) async {
    state = state.copyWith(date: DateTime(date.year, date.month, date.day));
    await refresh();
  }

  void selectView(BookingWorkboardView view) {
    state = state.copyWith(view: view);
  }

  Future<void> refresh() async {
    final ClinicLocation? clinic = _clinic;
    if (clinic == null) {
      state = state.copyWith(
        duePatients: const [],
        schedule: const [],
        dueLoading: false,
        scheduleLoading: false,
        clearDueError: true,
        clearScheduleError: true,
      );
      return;
    }

    final int generation = ++_refreshGeneration;
    final DateTime date = state.date;
    state = state.copyWith(
      dueLoading: true,
      scheduleLoading: true,
      clearDueError: true,
      clearScheduleError: true,
    );
    await Future.wait([
      _loadDue(generation, date, state.doctorId, clinic),
      _loadSchedule(generation, date, state.doctorId, clinic),
    ]);
  }

  Future<void> _loadDue(
    int generation,
    DateTime date,
    String? doctorId,
    ClinicLocation clinic,
  ) async {
    final result = await ref
        .read(patientRepositoryProvider)
        .getDuePatients(date: date, doctorId: doctorId, clinic: clinic);
    if (!ref.mounted || generation != _refreshGeneration) return;
    if (result case Failure<List<Patient>>(:final exception)) {
      state = state.copyWith(dueError: exception, dueLoading: false);
    } else {
      state = state.copyWith(
        duePatients: (result as Success<List<Patient>>).data,
        dueLoading: false,
      );
    }
  }

  Future<void> _loadSchedule(
    int generation,
    DateTime date,
    String? doctorId,
    ClinicLocation clinic,
  ) async {
    final result = await ref
        .read(appointmentRepositoryProvider)
        .getAllAppointments(
          dateFrom: date,
          dateTo: date.add(const Duration(days: 1)),
          doctorId: doctorId,
          clinic: clinic.dbValue,
          offset: 0,
          limit: 500,
          ascending: true,
        );
    if (!ref.mounted || generation != _refreshGeneration) return;
    if (result case Failure<List<AppointmentWithPatient>>(:final exception)) {
      state = state.copyWith(scheduleError: exception, scheduleLoading: false);
    } else {
      state = state.copyWith(
        schedule: (result as Success<List<AppointmentWithPatient>>).data,
        scheduleLoading: false,
      );
    }
  }

  Future<Result<void>> updateNextVisit(String patientId, DateTime? date) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null ||
        !user.isActive ||
        (user.role != UserRole.receptionist &&
            user.role != UserRole.superAdmin)) {
      return Result.failure(
        const DatabaseException(
          code: 'db/permission-denied',
          message: 'Access denied.',
          userMessageKey: 'error_database_permission_denied',
        ),
      );
    }
    final result = await ref
        .read(patientRepositoryProvider)
        .updateNextVisitDate(patientId, date);
    if (result is Success<void>) await refresh();
    return result;
  }

  Future<Result<BulkDoctorReplacementResult>> replaceDoctor({
    required List<String> replacementDoctorIds,
    required List<String> appointmentIds,
  }) async {
    final user = ref.read(currentUserProvider).value;
    final String? absentDoctorId = state.doctorId;
    if (user == null ||
        !user.isActive ||
        (user.role != UserRole.receptionist &&
            user.role != UserRole.superAdmin) ||
        absentDoctorId == null) {
      return Result.failure(
        const DatabaseException(
          code: 'db/permission-denied',
          message: 'Access denied.',
          userMessageKey: 'error_database_permission_denied',
        ),
      );
    }
    final result = await ref
        .read(appointmentRepositoryProvider)
        .bulkReplaceDoctor(
          absentDoctorId: absentDoctorId,
          replacementDoctorIds: replacementDoctorIds,
          appointmentIds: appointmentIds,
          day: state.date,
        );
    if (result is Success<BulkDoctorReplacementResult>) await refresh();
    return result;
  }
}
