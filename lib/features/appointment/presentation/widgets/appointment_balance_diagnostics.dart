import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

/// A live ledger preview card scoped to a single bucket (PT or Traction).
///
/// Renders an "assessments are paid separately" caption for assessment
/// types. For session types it shows the bucket's current balance minus
/// ONLY future-scheduled appointments of that same bucket.
class AppointmentBalanceDiagnostics extends ConsumerWidget {
  /// Creates an [AppointmentBalanceDiagnostics].
  const AppointmentBalanceDiagnostics({
    super.key,
    required this.patientId,
    required this.appointmentType,
    required this.requestedCount,
  });

  /// The patient ID.
  final String patientId;

  /// The currently selected appointment type — drives the bucket.
  final AppointmentType appointmentType;

  /// Proposed count of bookings for this slot (per single booking).
  final int requestedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!appointmentType.affectsPackageBalance) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.p16),
        decoration: BoxDecoration(
          color: AppColors.infoBg,
          border: Border.all(color: AppColors.info, width: AppSizes.borderWidthMedium),
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.info),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Text(
                AppStrings.assessmentPaidSeparatelyCaption,
                style: AppTextStyles.bodySecondary.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    final bool isPt = appointmentType == AppointmentType.normalPtSession;
    final String bucketLabel = isPt ? 'PT Sessions' : 'Traction Sessions';

    final patientAsync = ref.watch(patientDetailProvider(patientId));
    final bucketBalanceAsync = ref.watch(
      availableBalanceForTypeProvider((patientId: patientId, type: appointmentType)),
    );
    final futureForTypeAsync = ref.watch(
      futureScheduledAppointmentsCountForTypeProvider(
        (patientId: patientId, type: appointmentType),
      ),
    );

    final bool isLoading = patientAsync.isLoading ||
        bucketBalanceAsync.isLoading ||
        futureForTypeAsync.isLoading;
    final bool hasError = patientAsync.hasError ||
        bucketBalanceAsync.hasError ||
        futureForTypeAsync.hasError;

    if (isLoading) {
      return _wrapContainer(
        AppColors.surface,
        const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (hasError) {
      return _wrapContainer(
        AppColors.surface,
        Text(
          'Error loading package metrics.',
          style: AppTextStyles.bodySecondary.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      );
    }

    final int baseline = isPt
        ? (patientAsync.value?.sessionBalance ?? 0)
        : (patientAsync.value?.tractionBalance ?? 0);
    final int futureCommitments = futureForTypeAsync.value ?? 0;
    final int netAvailable = bucketBalanceAsync.value ?? baseline;
    final bool isDeficit = requestedCount > netAvailable;
    final int leftover = netAvailable - requestedCount;

    final Color cardBorderColor = isDeficit ? AppColors.error : AppColors.success;
    final Color cardBgColor = isDeficit ? AppColors.errorBg : AppColors.successBg;
    final Color statusTextColor = isDeficit ? AppColors.error : AppColors.success;
    final IconData statusIcon = isDeficit ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        border: Border.all(color: cardBorderColor, width: AppSizes.borderWidthMedium),
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
      ),
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusTextColor),
              const SizedBox(width: AppSizes.p8),
              Expanded(
                child: Text(
                  'Live Ledger Preview — $bucketLabel',
                  style: AppTextStyles.bodyBold.copyWith(color: statusTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          _buildRow('Current Bucket', '$baseline'),
          _buildRow('Upcoming in this bucket', '-$futureCommitments'),
          _buildRow('Net Available', '$netAvailable', isBold: true),
          _buildRow('This Order Count', '$requestedCount',
              valueColor: requestedCount > 0 ? AppColors.warning : AppColors.textSecondary,
              isBold: requestedCount > 0),
          const SizedBox(height: AppSizes.p8),
          Text(
            isDeficit
                ? 'Package Deficit: ${requestedCount - netAvailable} session(s) overdrawn.'
                : 'Projected Leftover Balance: $leftover session(s).',
            style: AppTextStyles.bodySecondary.copyWith(
              color: isDeficit ? AppColors.error : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapContainer(Color bg, Widget child) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
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
