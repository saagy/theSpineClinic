import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

/// A high-density live ledger preview card displaying package metrics and warnings.
class AppointmentBalanceDiagnostics extends ConsumerWidget {
  /// Creates an [AppointmentBalanceDiagnostics].
  const AppointmentBalanceDiagnostics({
    super.key,
    required this.patientId,
    required this.requestedCount,
  });

  /// The patient ID.
  final String patientId;

  /// Proposed package count (P).
  final int requestedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientDetailProvider(patientId));
    final commitmentsAsync = ref.watch(futureScheduledAppointmentsCountProvider(patientId));
    final availableAsync = ref.watch(availablePackageBalanceProvider(patientId));

    final bool isLoading = patientAsync.isLoading || commitmentsAsync.isLoading || availableAsync.isLoading;
    final bool hasError = patientAsync.hasError || commitmentsAsync.hasError || availableAsync.hasError;

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.p16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (hasError) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.p16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
        ),
        child: Text(
          'Error loading package metrics.',
          style: AppTextStyles.bodySecondary.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      );
    }

    final int currentBalance = patientAsync.value?.packageBalance ?? 0;
    final int futureCommitments = commitmentsAsync.value ?? 0;
    final int netAvailable = availableAsync.value ?? 0;
    final bool isDeficit = requestedCount > netAvailable;
    final int leftover = netAvailable - requestedCount;

    final Color cardBorderColor = isDeficit ? AppColors.error : AppColors.success;
    final Color cardBgColor = isDeficit ? AppColors.errorBg : AppColors.successBg;
    final Color statusTextColor = isDeficit ? AppColors.error : AppColors.success;
    final IconData statusIcon = isDeficit ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        border: Border.all(color: cardBorderColor, width: 1.5),
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
      ),
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusTextColor),
              const SizedBox(width: AppSizes.p8),
              Text(
                'Live Ledger Preview',
                style: AppTextStyles.bodyBold.copyWith(color: statusTextColor),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          _buildRow('Current Package Balance', '$currentBalance'),
          _buildRow('Upcoming Booked Sessions', '-$futureCommitments'),
          _buildRow('Net Available Balance', '$netAvailable', isBold: true),
          const Divider(height: AppSizes.p16, thickness: 1, color: AppColors.border),
          _buildRow(
            'This Current Order Count',
            '$requestedCount',
            valueColor: requestedCount > 0 ? AppColors.warning : AppColors.textSecondary,
            isBold: requestedCount > 0,
          ),
          const SizedBox(height: AppSizes.p8),
          if (isDeficit)
            Text(
              'Package Deficit: ${requestedCount - netAvailable} session(s) overdrawn. Allocation is locked.',
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.error),
            )
          else
            Text(
              'Projected Leftover Balance: $leftover session(s).',
              style: AppTextStyles.bodySecondary.copyWith(color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySecondary.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: (isBold ? AppTextStyles.bodyBold : AppTextStyles.bodySecondary).copyWith(
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
