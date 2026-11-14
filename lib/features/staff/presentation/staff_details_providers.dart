import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/provider_retry.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_assignments.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_details.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';

part 'staff_details_providers.g.dart';

/// Who may open the staff directory and profiles: active super admins, and
/// head receptionists (receptionists who manage payments), read-only.
bool canViewStaffRecords(Staff? user) => user?.canViewStaffRecords ?? false;

bool canEditStaffRecords(Staff? user) => user != null && user.isActive && user.role == UserRole.superAdmin;

/// One staff member's employment details. Row-level security returns
/// nothing for colleagues a head receptionist does not share a branch with,
/// which reads as empty. Only transient failures retry in the background.
@Riverpod(retry: retryTransientErrors)
Future<StaffDetails> staffDetails(Ref ref, String staffId) async {
  if (!canViewStaffRecords(ref.watch(currentUserProvider).value)) {
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

/// Every staff member's branches and weekly shifts. Pickers, filters and
/// booking warnings read it; it is reloaded after a staff save.
@Riverpod(keepAlive: true, retry: retryTransientErrors)
Future<StaffAssignments> staffAssignments(Ref ref) async {
  final Staff? user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isActive) return StaffAssignments.none;
  return (await ref.watch(staffRepositoryProvider).getStaffAssignments()).when(
    success: (assignments) => assignments,
    failure: (error) => throw error,
  );
}

/// The branches the signed-in person belongs to; empty when they have none
/// or while the assignments load (branches only order and default lists,
/// so a missing value never hides anything).
@riverpod
List<ClinicLocation> myBranches(Ref ref) {
  final Staff? user = ref.watch(currentUserProvider).value;
  if (user == null) return const [];
  return (ref.watch(staffAssignmentsProvider).value ?? StaffAssignments.none).branchesOf(user.id);
}
