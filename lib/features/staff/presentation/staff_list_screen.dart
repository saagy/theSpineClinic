import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_management_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Screen listing all non-doctor staff members.
/// Enforces Super Admin role-based protection on mount.
class StaffListScreen extends ConsumerWidget {
  /// Creates a [StaffListScreen].
  const StaffListScreen({super.key});

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

        return const _StaffListScaffold();
      },
    );
  }
}

class _StaffListScaffold extends ConsumerWidget {
  const _StaffListScaffold();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredStaffAsync = ref.watch(filteredStaffProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(AppStrings.staffManagement),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(staffListProvider.notifier).refreshStaff(),
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              child: filteredStaffAsync.when(
                data: (staffList) {
                  if (staffList.isEmpty) {
                    return const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: EmptyState(
                            message: AppStrings.noStaff,
                            icon: Icons.people_alt_rounded,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: staffList.length,
                    itemBuilder: (context, index) {
                      final staff = staffList[index];
                      return _StaffRow(staff: staff);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, _) => ErrorView(
                  exception: error is AppException ? error : AppException.fromSupabaseException(error),
                  onRetry: () => ref.read(staffListProvider.notifier).refreshStaff(),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.staffForm),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(staffFilterProvider);

    final filters = [
      {'label': AppStrings.all, 'value': 'All'},
      {'label': AppStrings.superAdmin, 'value': 'super_admin'},
      {'label': AppStrings.receptionist, 'value': 'receptionist'},
      {'label': AppStrings.doctor, 'value': 'doctor'},
    ];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p12,
      ),
      child: Row(
        children: filters.map((f) {
          final isSelected = selectedFilter == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: AppSizes.p8),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              selectedColor: AppColors.primaryLight,
              labelStyle: AppTextStyles.captionMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: AppSizes.borderWidth,
              ),
              showCheckmark: false,
              onSelected: (val) {
                if (val) {
                  ref.read(staffFilterProvider.notifier).setFilter(f['value']!);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({required this.staff});

  final Staff staff;

  @override
  Widget build(BuildContext context) {
    final String roleLabel;
    final Color roleTextColor;
    final Color roleBgColor;

    switch (staff.role) {
      case UserRole.superAdmin:
        roleLabel = AppStrings.superAdmin;
        roleTextColor = AppColors.primary;
        roleBgColor = AppColors.primaryLight;
        break;
      case UserRole.receptionist:
        roleLabel = AppStrings.receptionist;
        roleTextColor = AppColors.success;
        roleBgColor = AppColors.successBg;
        break;
      case UserRole.doctor:
        roleLabel = AppStrings.doctor;
        roleTextColor = AppColors.info;
        roleBgColor = AppColors.infoBg;
        break;
    }

    return DataListTile(
      title: staff.fullName,
      subtitle: staff.email,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBadge(
            label: roleLabel,
            textColor: roleTextColor,
            backgroundColor: roleBgColor,
          ),
          const SizedBox(width: AppSizes.p8),
          AppBadge(
            label: staff.isActive ? 'Active' : 'Inactive',
            textColor: staff.isActive ? AppColors.success : AppColors.error,
            backgroundColor: staff.isActive ? AppColors.successBg : AppColors.errorBg,
          ),
        ],
      ),
      onTap: () => context.push(AppRoutes.staffForm, extra: staff),
    );
  }
}
