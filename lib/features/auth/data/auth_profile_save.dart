part of 'auth_repository_impl.dart';

extension _ProfileSave on AuthRepositoryImpl {
  Future<Result<void>> _saveProfile(Staff staff, String? newPassword) async {
    bool profileSaved = false;
    try {
      await _service.guardQuery(
        () => _service
            .from(AuthRepositoryImpl._staffTable)
            .update({
              'full_name': staff.fullName,
              'email': staff.email,
              'phone': staff.phone,
              'branch': staff.branch?.dbValue,
            })
            .eq('id', staff.id)
            .select('id')
            .single(),
      );

      profileSaved = true;
      if (newPassword != null && newPassword.isNotEmpty) {
        // Self password change — use Supabase Auth API directly.
        // The RPC requires super_admin; the Auth API lets any
        // authenticated user change their own password.
        if (staff.userId == _service.currentUserId) {
          await _service.updatePassword(newPassword);
        } else {
          // Admin-initiated password change for another user — uses RPC.
          await _service.guardQuery(
            () => _service.rpc(
              'update_user_password',
              params: {
                'target_user_id': staff.userId,
                'new_password': newPassword,
              },
            ),
          );
        }
      }

      return const Result.success(null);
    } catch (error, stackTrace) {
      final normalized = AppException.fromSupabaseException(
        error,
        stackTrace: stackTrace,
      );
      return Result.failure(
        profileSaved
            ? const AuthException(
                code: 'auth/profile-saved-password-unconfirmed',
                message: 'Profile saved; password update unconfirmed.',
                userMessageKey: 'profile_saved_password_unconfirmed',
              )
            : normalized,
      );
    }
  }
}
