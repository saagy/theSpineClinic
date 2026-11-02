import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/profile_editor_form.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/form_page_skeleton.dart';

/// Account editing is addressable and restores directly from the active session.
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key, this.passwordOnly = false});
  final bool passwordOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user.hasError && !user.hasValue) {
      return _frame(
        ErrorView(
          exception: user.error is AppException
              ? user.error! as AppException
              : const UnknownException(
                  message: AppStrings.errorDatabaseQueryFailed,
                ),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      );
    }
    return user.when(
      loading: () => _frame(const FormPageSkeleton()),
      error: (Object error, StackTrace _) => _frame(
        ErrorView(
          exception: error is AppException
              ? error
              : const UnknownException(
                  message: AppStrings.errorDatabaseQueryFailed,
                ),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
      data: (staff) {
        if (staff == null) {
          return _frame(
            EmptyState(
              icon: Icons.person_outline,
              message: AppStrings.errorAuthSessionExpired,
              actionLabel: AppStrings.signIn,
              onActionPressed: () => context.go(AppRoutes.login),
            ),
          );
        }
        if (!staff.isActive) {
          return _frame(
            const ErrorView(
              exception: UnknownException(
                message: AppStrings.errorDatabasePermissionDenied,
              ),
            ),
          );
        }
        return ProfileEditorForm(
          key: ValueKey((staff.id, passwordOnly)),
          staff: staff,
          passwordOnly: passwordOnly,
        );
      },
    );
  }

  Widget _frame(Widget child) => Scaffold(
    appBar: AppBar(
      title: Text(
        passwordOnly ? AppStrings.changePassword : AppStrings.editProfile,
      ),
    ),
    body: child,
  );
}
