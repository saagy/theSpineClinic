import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/auth_repository.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';

part 'profile_editor_controller.g.dart';

class ProfileEditorState {
  const ProfileEditorState({this.isSaving = false, this.errorMessage});
  final bool isSaving;
  final String? errorMessage;

  ProfileEditorState copyWith({
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) => ProfileEditorState(
    isSaving: isSaving ?? this.isSaving,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

/// Every active role may edit its own account; drafts never supply privileges.
@Riverpod(keepAlive: true)
class ProfileEditorController extends _$ProfileEditorController {
  @override
  ProfileEditorState build(String staffId, {bool passwordOnly = false}) =>
      const ProfileEditorState();

  void clearError() {
    if (!state.isSaving) state = state.copyWith(clearError: true);
  }

  Future<bool> saveDetails({
    required String fullName,
    required String email,
    required String phone,
  }) => _save(
    (AuthRepository repository, Staff actor) => repository.updateStaffProfile(
      staff: actor.copyWith(
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim().isEmpty ? null : phone.trim(),
      ),
    ),
  );

  Future<bool> changePassword(String password) => _save(
    (AuthRepository repository, Staff actor) =>
        repository.changeOwnPassword(password),
  );

  Future<bool> _save(
    Future<Result<void>> Function(AuthRepository, Staff) operation,
  ) async {
    if (state.isSaving) return false;
    final session = ref.read(currentUserProvider);
    final Staff? actor = session.hasError ? null : session.value;
    if (actor == null || !actor.isActive || actor.id != staffId) {
      state = state.copyWith(
        errorMessage: AppStrings.errorDatabasePermissionDenied,
      );
      return false;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    Result<void> result;
    try {
      result = await operation(ref.read(authRepositoryProvider), actor);
    } catch (error, stackTrace) {
      result = Result.failure(
        AppException.fromSupabaseException(error, stackTrace: stackTrace),
      );
    }
    if (!ref.mounted) return false;
    if (result case Failure<void>(:final exception)) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: AppStrings.fromKey(exception.userMessageKey),
      );
      return false;
    }
    state = state.copyWith(isSaving: false);
    if (!passwordOnly) {
      ref.invalidate(currentUserProvider);
      ref.invalidate(staffProfileProvider(staffId));
    }
    return true;
  }
}
