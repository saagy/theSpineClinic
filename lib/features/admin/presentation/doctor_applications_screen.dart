import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
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
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorView(
          exception: error is AppException
              ? error
              : const UnknownException(message: AppStrings.errorDatabaseQueryFailed),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
      data: (user) {
        if (user == null || user.role != UserRole.superAdmin) {
          return const Scaffold(
            backgroundColor: AppColors.background,
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
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              title: const Text(AppStrings.doctorApplications),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
              bottom: const TabBar(
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: [
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
