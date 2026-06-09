import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/admin_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';

part 'doctor_applications_controller.g.dart';

/// Notifier resolving the roster of pending doctor registration applications.
@riverpod
class PendingDoctorApplications extends _$PendingDoctorApplications {
  @override
  Future<List<Staff>> build() async {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null || currentUser.role != UserRole.superAdmin) {
      throw const AuthException(
        code: 'security/permission-denied',
        message: 'Only super admins are authorized to view doctor applications.',
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

/// Notifier resolving the total audit tracker roster of all doctor applications.
@riverpod
class AllDoctorApplications extends _$AllDoctorApplications {
  @override
  Future<List<Staff>> build() async {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null || currentUser.role != UserRole.superAdmin) {
      throw const AuthException(
        code: 'security/permission-denied',
        message: 'Only super admins are authorized to view doctor applications.',
      );
    }

    final repo = ref.read(adminRepositoryProvider);
    final result = await repo.getAllDoctorApplications();
    return result.when(
      success: (data) => data,
      failure: (exception) => throw exception,
    );
  }

  /// Refreshes the complete applications roster.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    ref.invalidateSelf();
    await future;
  }
}

/// Controller managing approval and rejection actions for doctor applications.
@riverpod
class DoctorApplicationsAction extends _$DoctorApplicationsAction {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Approves a doctor registration application.
  Future<Result<void>> approveDoctor(String id) async {
    state = const AsyncValue.loading();
    final repo = ref.read(adminRepositoryProvider);
    final result = await repo.approveDoctor(id);

    state = result.when(
      success: (_) {
        ref.invalidate(pendingDoctorApplicationsProvider);
        ref.invalidate(allDoctorApplicationsProvider);
        return const AsyncValue.data(null);
      },
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );
    return result;
  }

  /// Rejects a doctor registration application, permanently deleting both auth and staff profiles.
  Future<Result<void>> rejectDoctor(String id, String userId) async {
    state = const AsyncValue.loading();
    final repo = ref.read(adminRepositoryProvider);
    final result = await repo.rejectDoctor(id: id, userId: userId);

    state = result.when(
      success: (_) {
        ref.invalidate(pendingDoctorApplicationsProvider);
        ref.invalidate(allDoctorApplicationsProvider);
        return const AsyncValue.data(null);
      },
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );
    return result;
  }
}
