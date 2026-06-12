import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/admin/presentation/analytics_providers.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/analytics_filter_bar.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/appointments_summary_section.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/financial_summary_section.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/patient_summary_section.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/staff_summary_section.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Full analytics dashboard with independent section loading.
/// Rendered inside [AppShell] — no standalone Scaffold or AppBar.
/// Protected: only [UserRole.superAdmin] can access.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);

    return asyncUser.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, _) => ErrorView(
        exception: error is AppException ? error : const UnknownException(message: AppStrings.errorDatabaseQueryFailed),
        onRetry: () => ref.invalidate(currentUserProvider),
      ),
      data: (user) {
        if (user == null || user.role != UserRole.superAdmin) {
          return const ErrorView(
            exception: UnknownException(message: AppStrings.errorDatabasePermissionDenied, code: 'security/blocked'),
          );
        }
        return const _AnalyticsBody();
      },
    );
  }
}

/// Scrollable body containing the filter bar and four independent sections.
class _AnalyticsBody extends ConsumerWidget {
  const _AnalyticsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const AnalyticsFilterBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(financialSummaryProvider);
              ref.invalidate(appointmentSummaryProvider);
              ref.invalidate(staffSummaryProvider);
              ref.invalidate(patientSummaryProvider);
            },
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.p16),
              children: [
                _SectionHeader(title: AppStrings.financialOverview),
                const SizedBox(height: AppSizes.p12),
                const FinancialSummarySection(),
                const SizedBox(height: AppSizes.p24),
                _SectionHeader(title: AppStrings.appointmentAnalytics),
                const SizedBox(height: AppSizes.p12),
                const AppointmentsSummarySection(),
                const SizedBox(height: AppSizes.p24),
                _SectionHeader(title: AppStrings.staffPerformance),
                const SizedBox(height: AppSizes.p12),
                const StaffSummarySection(),
                const SizedBox(height: AppSizes.p24),
                _SectionHeader(title: AppStrings.patientDemographics),
                const SizedBox(height: AppSizes.p12),
                const PatientSummarySection(),
                const SizedBox(height: AppSizes.p32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Section header with title text.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.headingSmall.copyWith(color: AppColors.textPrimary));
  }
}
