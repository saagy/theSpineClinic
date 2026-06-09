import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';

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
        message: 'Only super admins are authorized to view staff accounts.',
      );
    }

    final repo = ref.read(staffRepositoryProvider);
    final result = await repo.getAllStaff();
    return result.when(
      success: (data) => data,
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

/// Provider for the selected role filter on the staff list screen.
@riverpod
class StaffFilter extends _$StaffFilter {
  @override
  String build() => 'All';

  /// Sets the active role filter.
  void setFilter(String filter) => state = filter;
}

/// Computes the filtered roster of clinic staff members based on the selected filter.
@riverpod
Future<List<Staff>> filteredStaff(Ref ref) async {
  final filter = ref.watch(staffFilterProvider);
  final list = await ref.watch(staffListProvider.future);
  if (filter == 'All') return list;
  if (filter == 'super_admin') {
    return list.where((s) => s.role == UserRole.superAdmin).toList();
  }
  if (filter == 'receptionist') {
    return list.where((s) => s.role == UserRole.receptionist).toList();
  }
  if (filter == 'doctor') {
    return list.where((s) => s.role == UserRole.doctor).toList();
  }
  return list;
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
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(staffRepositoryProvider);
    final result = await repo.createStaff(
      fullName: fullName,
      email: email,
      role: role,
      password: password,
      phone: phone,
    );

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
    state = const AsyncValue.loading();
    final repo = ref.read(staffRepositoryProvider);
    final result = await repo.updateStaff(
      staff: staff,
      newPassword: newPassword,
    );

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
}
