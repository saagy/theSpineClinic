import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_applications_controller.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_applications_tab.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_directory_tab.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Screen managing clinic staff roster and onboarding registration requests.
/// Protected view restricted to Super Admin role.
class StaffListScreen extends ConsumerWidget {
  /// Creates a [StaffListScreen] instance.
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);
    return asyncUser.when(
      loading: () => _LoadingScaffold(),
      error: (error, _) => _ErrorScaffold(
        error: error,
        onRetry: () => ref.invalidate(currentUserProvider),
      ),
      data: (user) {
        if (user == null || user.role != UserRole.superAdmin) {
          return const _BlockedScaffold();
        }

        final pendingAsync = ref.watch(pendingStaffApplicationsProvider);
        final pendingCount = pendingAsync.value?.length ?? 0;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              elevation: 0,
              title: const Text(AppStrings.staffManagement),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
              bottom: TabBar(
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
                tabs: [
                  const Tab(text: AppStrings.staff),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(AppStrings.pending),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 6),
                          Badge(
                            label: Text(
                              '$pendingCount',
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                StaffDirectoryTab(),
                StaffApplicationsTab(),
              ],
            ),
          ),
        );
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
