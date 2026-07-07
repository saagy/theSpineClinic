import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/admin_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_management_controller.dart';

part 'staff_applications_controller.g.dart';

/// Notifier resolving the roster of pending staff registration applications.
@riverpod
class PendingStaffApplications extends _$PendingStaffApplications {
  @override
  Future<List<Staff>> build() async {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null || currentUser.role != UserRole.superAdmin) {
      throw const AuthException(
        code: 'security/permission-denied',
        message: AppStrings.staffAdminPermissionDenied,
      );
    }

    final repo = ref.read(adminRepositoryProvider);
    final result = await repo.getPendingDoctorApplications();
    return result.when(
      success: (data) => data,
      failure: (exception) => throw exception,
    );
  }

  /// Refreshes the pending applications roster.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    ref.invalidateSelf();
    await future;
  }
}

/// Controller managing approval and rejection actions for staff applications.
@riverpod
class StaffApplicationsAction extends _$StaffApplicationsAction {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Approves a staff registration application.
  Future<Result<void>> approveStaff(String id) async {
    final blocked = _adminGuard();
    if (blocked != null) return blocked;

    state = const AsyncValue.loading();
    final repo = ref.read(adminRepositoryProvider);
    final result = await repo.approveDoctor(id);
    if (!ref.mounted) return result;

    state = result.when(
      success: (_) {
        ref.invalidate(pendingStaffApplicationsProvider);
        ref.invalidate(staffListProvider);
        return const AsyncValue.data(null);
      },
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );
    return result;
  }

  /// Rejects a staff registration application and deletes its auth/profile rows.
  Future<Result<void>> rejectStaff(String id, String userId) async {
    final blocked = _adminGuard();
    if (blocked != null) return blocked;

    state = const AsyncValue.loading();
    final repo = ref.read(adminRepositoryProvider);
    final result = await repo.rejectDoctor(id: id, userId: userId);
    if (!ref.mounted) return result;

    state = result.when(
      success: (_) {
        ref.invalidate(pendingStaffApplicationsProvider);
        return const AsyncValue.data(null);
      },
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );
    return result;
  }

  Result<void>? _adminGuard() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser?.role == UserRole.superAdmin) return null;
    return const Result.failure(
      AuthException(
        code: 'security/permission-denied',
        message: AppStrings.staffAdminPermissionDenied,
      ),
    );
  }
}
