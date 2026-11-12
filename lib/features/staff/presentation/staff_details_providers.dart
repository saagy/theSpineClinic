import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/provider_retry.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_details.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';

part 'staff_details_providers.g.dart';

bool _isAdmin(Staff? user) => user != null && user.isActive && user.role == UserRole.superAdmin;

/// One staff member's reference details for the editor. Only transient
/// network failures retry in the background; others show Retry at once.
@Riverpod(retry: retryTransientErrors)
Future<StaffDetails> staffDetails(Ref ref, String staffId) async {
  if (!_isAdmin(ref.watch(currentUserProvider).value)) {
    throw const AuthException(
      code: 'security/permission-denied',
      message: AppStrings.staffAdminPermissionDenied,
      userMessageKey: 'error_database_permission_denied',
    );
  }
  return (await ref.watch(staffRepositoryProvider).getStaffDetails(staffId)).when(
    success: (details) => details,
    failure: (error) => throw error,
  );
}

/// Working days and hours by staff ID for the directory. Empty for anyone
/// but super admins, and on failure the directory simply omits them.
@riverpod
Future<Map<String, StaffDetails>> staffSchedules(Ref ref) async {
  if (!_isAdmin(ref.watch(currentUserProvider).value)) return const {};
  return (await ref.watch(staffRepositoryProvider).getStaffSchedules()).when(
    success: (schedules) => schedules,
    failure: (_) => const {},
  );
}
