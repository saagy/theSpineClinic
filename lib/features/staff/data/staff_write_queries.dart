import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

Future<Result<void>> createStaffAccount(
  SupabaseService service, {
  required String fullName,
  required String email,
  required UserRole role,
  required String password,
  required bool canManagePayments,
  String? phone,
  ClinicLocation? branch,
}) async {
  try {
    await service.guardQuery(
      () => service.rpc(
        'create_staff_user',
        params: {
          'new_email': email,
          'new_password': password,
          'new_full_name': fullName,
          'new_role': role.dbValue,
          'new_phone': phone,
          'new_can_manage_payments':
              role == UserRole.receptionist && canManagePayments,
          'new_branch': role == UserRole.receptionist ? branch?.dbValue : null,
        },
      ),
    );
    return const Result.success(null);
  } on AppException catch (e) {
    return Result.failure(e);
  } on Exception catch (e) {
    return Result.failure(AppException.fromSupabaseException(e));
  }
}

Future<Result<void>> updateStaffAccount(
  SupabaseService service, {
  required Staff staff,
  String? newPassword,
}) async {
  try {
    if (staff.userId == service.currentUserId && !staff.isActive) {
      return const Result.failure(
        AuthException(
          code: 'auth/self-deactivation',
          message: AppStrings.selfDeactivationError,
        ),
      );
    }
    if (newPassword != null && newPassword.isNotEmpty) {
      final failure = await _updatePassword(service, staff, newPassword);
      if (failure != null) return failure;
    }
    await service.guardQuery(
      () => service.from('staff').update(_row(staff)).eq('id', staff.id),
    );
    return const Result.success(null);
  } on AppException catch (e) {
    return Result.failure(e);
  } on Exception catch (e) {
    return Result.failure(AppException.fromSupabaseException(e));
  }
}

Map<String, Object?> _row(Staff staff) => {
  'full_name': staff.fullName,
  'email': staff.email,
  'phone': staff.phone,
  'role': staff.role.dbValue,
  'is_active': staff.isActive,
  'can_manage_payments':
      staff.role == UserRole.receptionist && staff.canManagePayments,
  'branch': staff.role == UserRole.receptionist ? staff.branch?.dbValue : null,
  'deactivated_at': staff.isActive
      ? null
      : staff.deactivatedAt?.toUtc().toIso8601String() ??
            DateTime.now().toUtc().toIso8601String(),
};

Future<Result<void>?> _updatePassword(
  SupabaseService service,
  Staff staff,
  String password,
) async {
  if (staff.userId == null) {
    return const Result.failure(
      AuthException(
        code: 'auth/no-user-id',
        message: AppStrings.staffPasswordMissingUserId,
      ),
    );
  }
  await service.guardQuery(
    () => service.rpc(
      'update_user_password',
      params: {'target_user_id': staff.userId, 'new_password': password},
    ),
  );
  return null;
}
