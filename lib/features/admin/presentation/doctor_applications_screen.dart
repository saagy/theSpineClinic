import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/all_tab_view.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/pending_tab_view.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Screen displaying self-registered doctor applications for administrator review.
/// Enforces Super Admin role-based protection on mount.
class DoctorApplicationsScreen extends ConsumerWidget {
  /// Creates a [DoctorApplicationsScreen] instance.
  const DoctorApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);

    return asyncUser.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: ErrorView(
          exception: error is AppException
              ? error
              : const UnknownException(message: AppStrings.errorDatabaseQueryFailed),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
      data: (user) {
        if (user == null || user.role != UserRole.superAdmin) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: ErrorView(
              exception: UnknownException(
                message: AppStrings.errorDatabasePermissionDenied,
                code: 'security/blocked',
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              elevation: 0,
              title: const Text(AppStrings.doctorApplications),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
              bottom: TabBar(
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                tabs: const [
                  Tab(text: AppStrings.pending),
                  Tab(text: AppStrings.allApplications),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                PendingTabView(),
                AllTabView(),
              ],
            ),
          ),
        );
      },
    );
  }
}
