import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Central dashboard hub for clinic administrators.
/// Enforces Super Admin role-based protection on mount.
class AdminHubScreen extends ConsumerWidget {
  /// Creates an [AdminHubScreen].
  const AdminHubScreen({super.key});

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

        return const _AdminHubBody();
      },
    );
  }
}

class _AdminHubBody extends StatelessWidget {
  const _AdminHubBody();

  @override
  Widget build(BuildContext context) {
    final destinations = [
      {
        'title': AppStrings.staffManagement,
        'subtitle': AppStrings.manageStaffLabel,
        'icon': Icons.people_alt_rounded,
        'route': AppRoutes.staffList,
      },
      {
        'title': AppStrings.doctorApplications,
        'subtitle': AppStrings.manageDoctorsLabel,
        'icon': Icons.assignment_ind_rounded,
        'route': AppRoutes.doctorApplications,
      },
      {
        'title': AppStrings.clinicSettings,
        'subtitle': AppStrings.configureClinicLabel,
        'icon': Icons.settings_rounded,
        'route': AppRoutes.clinicSettings,
      },
      {
        'title': AppStrings.reportsAndAnalytics,
        'subtitle': AppStrings.viewReportsLabel,
        'icon': Icons.analytics_rounded,
        'route': AppRoutes.reports,
      },
    ];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.p16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: AppSizes.p16,
        mainAxisSpacing: AppSizes.p16,
        childAspectRatio: 0.85,
        children: destinations.map((d) {
          return _HubCard(
            title: d['title'] as String,
            subtitle: d['subtitle'] as String,
            icon: d['icon'] as IconData,
            onTap: () => context.push(d['route'] as String),
          );
        }).toList(),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
        child: SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: AppSizes.iconLarge,
              ),
              const SizedBox(height: AppSizes.p12),
              Text(
                title,
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSizes.p4),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
