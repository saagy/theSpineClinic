import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_assignments.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_details.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_details_providers.dart';
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
        final Staff? existing = staff;
        if (existing == null) {
          return StaffFormBody(
            currentUser: currentUser,
            details: StaffDetails.empty,
            schedule: StaffSchedule.empty,
          );
        }
        // The form opens only with the saved details and schedule, so a save
        // never replaces them with blanks.
        final AsyncValue<StaffDetails> details = ref.watch(staffDetailsProvider(existing.id));
        final AsyncValue<StaffAssignments> assignments = ref.watch(staffAssignmentsProvider);
        if (details.hasError || assignments.hasError) {
          final Object? error = details.error ?? assignments.error;
          return _frame(
            ErrorView(
              exception: error is AppException
                  ? error
                  : UnknownException(message: AppStrings.staffDetails.loadFailed),
              onRetry: () {
                ref.invalidate(staffDetailsProvider(existing.id));
                ref.invalidate(staffAssignmentsProvider);
              },
            ),
          );
        }
        if (!details.hasValue || !assignments.hasValue) return _frame(const FormPageSkeleton());
        return StaffFormBody(
          staff: existing,
          currentUser: currentUser,
          details: details.requireValue,
          schedule: assignments.requireValue.scheduleOf(existing.id),
        );
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
