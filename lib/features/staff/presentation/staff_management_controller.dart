import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_account_status.dart';

part 'staff_management_controller.g.dart';

/// Notifier providing the reactive list of all clinic staff members (including doctors).
/// Enforces Super Admin role-based access check on build.
@riverpod
class StaffList extends _$StaffList {
  @override
  Future<List<Staff>> build() async {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null || currentUser.role != UserRole.superAdmin) {
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
@riverpod
class StaffFormController extends _$StaffFormController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Creates a new staff user and profile.
  Future<Result<void>> createStaff({
    required String fullName,
    required String email,
    required UserRole role,
    required String password,
    required bool canManagePayments,
    String? phone,
    ClinicLocation? branch,
  }) async {
    final blocked = _adminGuard();
    if (blocked != null) return blocked;

    state = const AsyncValue.loading();
    final repo = ref.read(staffRepositoryProvider);
    final result = await repo.createStaff(
      fullName: fullName,
      email: email,
      role: role,
      password: password,
      canManagePayments: canManagePayments,
      phone: phone,
      branch: branch,
    );
    if (!ref.mounted) return result;

    state = result.when(
      success: (_) {
        ref.invalidate(staffListProvider);
        return const AsyncValue.data(null);
      },
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );
    return result;
  }

  /// Updates an existing staff profile, and optionally their authentication password.
  Future<Result<void>> updateStaff({
    required Staff staff,
    String? newPassword,
  }) async {
    final blocked = _adminGuard();
    if (blocked != null) return blocked;

    state = const AsyncValue.loading();
    final repo = ref.read(staffRepositoryProvider);
    final result = await repo.updateStaff(
      staff: staff,
      newPassword: newPassword,
    );
    if (!ref.mounted) return result;

    state = result.when(
      success: (_) {
        ref.invalidate(staffListProvider);
        final currentUser = ref.read(currentUserProvider).value;
        if (currentUser != null && currentUser.id == staff.id) {
          ref.invalidate(currentUserProvider);
        }
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
