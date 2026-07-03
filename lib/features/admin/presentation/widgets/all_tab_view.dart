import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/admin/presentation/doctor_applications_controller.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Tab body rendering a read-only audit ledger of all registered doctors.
class AllTabView extends ConsumerWidget {
  /// Creates an [AllTabView] instance.
  const AllTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allApplicationsAsync = ref.watch(allDoctorApplicationsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(allDoctorApplicationsProvider.notifier).refresh(),
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: allApplicationsAsync.when(
        data: (applications) {
          if (applications.isEmpty) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: AppSizes.emptyStateTopOffset),
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
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final doctor = applications[index];
              return DataListTile(
                title: doctor.fullName,
                subtitle: '${doctor.email} • ${doctor.phone != null ? Formatters.formatPhone(doctor.phone!) : 'No phone'} • Reg: ${doctor.createdAt.toShortDateString()}',
                leading: AppAvatar(
                  name: doctor.fullName,
                  color: doctor.isActive ? ClinicColors.of(context).success : ClinicColors.of(context).warning,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBadge(
                      label: doctor.role == UserRole.doctor
                          ? AppStrings.doctorRoleLabel
                          : AppStrings.receptionistRoleLabel,
                      textColor: Theme.of(context).colorScheme.primary,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    const SizedBox(width: AppSizes.p8),
                    AppBadge(
                      label: doctor.isActive ? AppStrings.completed : AppStrings.scheduled,
                      textColor: doctor.isActive ? ClinicColors.of(context).success : ClinicColors.of(context).warning,
                      backgroundColor: doctor.isActive ? ClinicColors.of(context).successContainer : ClinicColors.of(context).warningContainer,
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
        ),
        error: (error, _) => ErrorView(
          exception: error is AppException ? error : AppException.fromSupabaseException(error),
          onRetry: () => ref.read(allDoctorApplicationsProvider.notifier).refresh(),
        ),
      ),
    );
  }
}
