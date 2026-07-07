import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_form_body.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

class StaffFormScreen extends ConsumerWidget {
  const StaffFormScreen({super.key, this.staff});

  final Staff? staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);
    return asyncUser.when(
      loading: () => _LoadingScaffold(),
      error: (error, _) => _ErrorScaffold(
        error: error,
        onRetry: () => ref.invalidate(currentUserProvider),
      ),
      data: (currentUser) {
        if (currentUser == null || currentUser.role != UserRole.superAdmin) {
          return const _BlockedScaffold();
        }
        return StaffFormBody(staff: staff, currentUser: currentUser);
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ErrorView(
      exception: error is AppException
          ? error as AppException
          : const UnknownException(
              message: AppStrings.errorDatabaseQueryFailed,
            ),
      onRetry: onRetry,
    ),
  );
}

class _BlockedScaffold extends StatelessWidget {
  const _BlockedScaffold();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: ErrorView(
      exception: UnknownException(
        message: AppStrings.errorDatabasePermissionDenied,
        code: 'security/blocked',
      ),
    ),
  );
}
