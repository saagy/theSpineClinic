import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_assignments.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_details.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_details_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_account_status.dart';

import 'staff_form_state.dart';

part 'staff_management_controller.g.dart';

/// Notifier providing the reactive list of all clinic staff members (including doctors).
/// Super admins and head receptionists may read it.
@riverpod
class StaffList extends _$StaffList {
  @override
  Future<List<Staff>> build() async {
    final currentUser = ref.watch(currentUserProvider).value;
    if (!canViewStaffRecords(currentUser)) {
      throw const AuthException(
        code: 'security/permission-denied',
        message: AppStrings.staffAdminPermissionDenied,
      );
    }

    final repo = ref.read(staffRepositoryProvider);
    final result = await repo.getAllStaff();
    return result.when(
      success: (data) => data.where((s) => !s.isPendingApplication).toList(),
      failure: (exception) => throw exception,
    );
  }

  /// Force-refresh the staff roster from the database.
  Future<void> refreshStaff() async {
    state = const AsyncValue.loading();
    ref.invalidateSelf();
    await future;
  }
}

/// Controller managing staff account registration and modifications.
@Riverpod(keepAlive: true)
class StaffFormController extends _$StaffFormController {
  @override
  StaffFormState build() => const StaffFormState();

  void clearError() {
    if (!state.isLoading) state = state.copyWith(clearError: true);
  }

  void reportFailure(AppException error) =>
      state = state.copyWith(isLoading: false, error: error);

  Future<Result<void>> createStaff({
    required String fullName,
    required String email,
    required UserRole role,
    required String password,
    required bool canManagePayments,
    bool isSenior = false,
    String? phone,
    ClinicLocation? branch,
    StaffDetails? details,
    StaffSchedule? schedule,
  }) => _save(
    () => ref
        .read(staffRepositoryProvider)
        .createStaff(
          fullName: fullName,
          email: email,
          role: role,
          password: password,
          canManagePayments: canManagePayments,
          isSenior: role == UserRole.doctor && isSenior,
          phone: phone,
          branch: branch,
          details: details,
          schedule: schedule,
        ),
  );

  Future<Result<void>> updateStaff({
    required Staff staff,
    String? newPassword,
    StaffDetails? details,
    StaffSchedule? schedule,
  }) {
    final Staff? actor = ref.read(currentUserProvider).value;
    if (actor?.id == staff.id &&
        (staff.role != actor?.role || !staff.isActive)) {
      const AppException error = AuthException(
        code: 'security/self-access',
        message: AppStrings.staffOwnRoleHelp,
        userMessageKey: 'error_database_permission_denied',
      );
      reportFailure(error);
      return Future.value(const Result.failure(error));
    }
    return _save(
      () => ref
          .read(staffRepositoryProvider)
          .updateStaff(staff: staff, newPassword: newPassword, details: details, schedule: schedule),
      updated: staff,
    );
  }

  Future<Result<int>> deactivationAppointments(Staff staff) async {
    final AppException? blocked = _permissionError();
    if (blocked != null) {
      reportFailure(blocked);
      return Result.failure(blocked);
    }
    if (staff.role != UserRole.doctor) return const Result.success(0);
    final Result<int> result = await ref
        .read(staffRepositoryProvider)
        .countUpcomingAppointments(staff.id);
    if (!ref.mounted) return result;
    if (result case Failure<int>(:final exception)) {
      reportFailure(exception);
    }
    return result;
  }

  /// Upcoming visits [staff] has at each of [branches], for the warning
  /// shown before a doctor's branch is removed. Branches with none are left
  /// out.
  Future<Result<Map<ClinicLocation, int>>> upcomingAtBranches(
    Staff staff,
    Iterable<ClinicLocation> branches,
  ) async {
    final AppException? blocked = _permissionError();
    if (blocked != null) {
      reportFailure(blocked);
      return Result.failure(blocked);
    }
    final Map<ClinicLocation, int> counts = {};
    if (staff.role != UserRole.doctor) return Result.success(counts);
    for (final ClinicLocation branch in branches) {
      final Result<int> result = await ref.read(staffRepositoryProvider).countUpcomingAtBranch(staff.id, branch);
      if (!ref.mounted) return Result.success(counts);
      switch (result) {
        case Failure<int>(:final exception):
          reportFailure(exception);
          return Result.failure(exception);
        case Success<int>(:final data):
          if (data > 0) counts[branch] = data;
      }
    }
    return Result.success(counts);
  }

  Future<Result<void>> _save(
    Future<Result<void>> Function() operation, {
    Staff? updated,
  }) async {
    final AppException? blocked = _permissionError();
    if (blocked != null) {
      reportFailure(blocked);
      return Result.failure(blocked);
    }
    if (state.isLoading) {
      return const Result.failure(
        UnknownException(message: AppStrings.savingChanges),
      );
    }
    state = state.copyWith(isLoading: true, clearError: true);
    Result<void> result;
    try {
      result = await operation();
    } catch (error, stackTrace) {
      result = Result.failure(
        AppException.fromSupabaseException(error, stackTrace: stackTrace),
      );
    }
    if (!ref.mounted) return result;
    if (result case Failure<void>(:final exception)) {
      reportFailure(exception);
    } else {
      state = state.copyWith(isLoading: false);
      ref.invalidate(staffListProvider);
      ref.invalidate(activeDoctorsProvider);
      ref.invalidate(allDoctorsForFilterProvider);
      ref.invalidate(staffAssignmentsProvider);
      if (updated != null) {
        ref.invalidate(staffProfileProvider(updated.id));
        ref.invalidate(staffDetailsProvider(updated.id));
        if (ref.read(currentUserProvider).value?.id == updated.id) {
          ref.invalidate(currentUserProvider);
        }
      }
    }
    return result;
  }

  AppException? _permissionError() {
    final session = ref.read(currentUserProvider);
    final Staff? actor = session.value;
    if (!session.hasError &&
        actor?.role == UserRole.superAdmin &&
        actor?.isActive == true) {
      return null;
    }
    return const AuthException(
      code: 'security/permission-denied',
      message: AppStrings.staffAdminPermissionDenied,
      userMessageKey: 'error_database_permission_denied',
    );
  }
}
