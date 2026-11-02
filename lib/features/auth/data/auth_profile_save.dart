part of 'auth_repository_impl.dart';

extension _ProfileSave on AuthRepositoryImpl {
  Future<Result<void>> _changeOwnPassword(String password) async {
    try {
      await _service.updatePassword(password);
      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(
        AppException.fromSupabaseException(error, stackTrace: stackTrace),
      );
    }
  }

  Future<Result<void>> _saveProfile(Staff staff) async {
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

      return const Result.success(null);
    } catch (error, stackTrace) {
      return Result.failure(
        AppException.fromSupabaseException(error, stackTrace: stackTrace),
      );
    }
  }
}
