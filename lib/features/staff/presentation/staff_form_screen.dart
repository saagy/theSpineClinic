import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_form_body.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/form_page_skeleton.dart';

class StaffFormScreen extends ConsumerWidget {
  const StaffFormScreen({super.key, this.staff});
  final Staff? staff;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
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
      data: (Staff? currentUser) {
        if (currentUser == null) {
          return _frame(
            EmptyState(
              icon: Icons.person_outline,
              message: AppStrings.errorAuthSessionExpired,
              actionLabel: AppStrings.signIn,
              onActionPressed: () => context.go(AppRoutes.login),
            ),
          );
        }
        if (currentUser.role != UserRole.superAdmin || !currentUser.isActive) {
          return _frame(
            const ErrorView(
              exception: AuthException(
                code: 'security/blocked',
                message: AppStrings.staffAdminPermissionDenied,
                userMessageKey: 'error_database_permission_denied',
              ),
            ),
          );
        }
        return StaffFormBody(staff: staff, currentUser: currentUser);
      },
    );
  }

  Widget _frame(Widget child) => Scaffold(
    appBar: AppBar(
      title: Text(staff == null ? AppStrings.addStaff : AppStrings.editStaff),
    ),
    body: child,
  );
}
