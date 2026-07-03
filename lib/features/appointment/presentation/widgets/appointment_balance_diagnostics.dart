import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          color: ClinicColors.of(context).infoContainer,
          border: Border.all(color: ClinicColors.of(context).info, width: AppSizes.borderWidthMedium),
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: ClinicColors.of(context).info),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Text(
                AppStrings.assessmentPaidSeparatelyCaption,
                style: AppTextStyles.bodySecondary.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ],
        ),
      );
    }

    final bool isPt = appointmentType == AppointmentType.normalPtSession;
    final String bucketLabel = isPt
        ? AppStrings.ptSessionsBucket
        : AppStrings.tractionSessionsBucket;

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
        context,
        Theme.of(context).colorScheme.surface,
        Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }
    if (hasError) {
      return _wrapContainer(
        context,
        Theme.of(context).colorScheme.surface,
        Text(
          AppStrings.errorLoadingPackageMetrics,
          style: AppTextStyles.bodySecondary.copyWith(color: Theme.of(context).colorScheme.error),
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

    final Color cardBorderColor = isDeficit ? Theme.of(context).colorScheme.error : ClinicColors.of(context).success;
    final Color cardBgColor = isDeficit ? Theme.of(context).colorScheme.errorContainer : ClinicColors.of(context).successContainer;
    final Color statusTextColor = isDeficit ? Theme.of(context).colorScheme.error : ClinicColors.of(context).success;
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
                  '${AppStrings.liveLedgerPreview} — $bucketLabel',
                  style: AppTextStyles.bodyBold.copyWith(color: statusTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          _buildRow(context, AppStrings.currentBucket, '$baseline'),
          _buildRow(context, AppStrings.upcomingInBucket, '-$futureCommitments'),
          _buildRow(context, AppStrings.netAvailableLabel, '$netAvailable', isBold: true),
          _buildRow(context, AppStrings.thisOrderCount, '$requestedCount',
              valueColor: requestedCount > 0 ? ClinicColors.of(context).warning : Theme.of(context).colorScheme.onSurfaceVariant,
              isBold: requestedCount > 0),
          const SizedBox(height: AppSizes.p8),
          Text(
            isDeficit
                ? AppStrings.packageDeficitMessage(requestedCount - netAvailable)
                : AppStrings.projectedLeftoverMessage(leftover),
            style: AppTextStyles.bodySecondary.copyWith(
              color: isDeficit ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (baseline < 0) ...[
            const SizedBox(height: AppSizes.p8),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: AppSizes.iconSmall, color: ClinicColors.of(context).warning),
                const SizedBox(width: AppSizes.p8),
                Expanded(
                  child: Text(
                    AppStrings.negativeBalanceOutstanding,
                    style: AppTextStyles.bodySecondary
                        .copyWith(color: ClinicColors.of(context).warning),
                  ),
                ),
              ],
            ),
          ],
          if (isDeficit && requestedCount > 0) ...[
            const SizedBox(height: AppSizes.p8),
            Text(
              AppStrings.insufficientPackageBalance,
              style: AppTextStyles.bodySecondary
                  .copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _wrapContainer(BuildContext context, Color bg, Widget child) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: child,
    );
  }

  Widget _buildRow(
    BuildContext context,
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
            style: AppTextStyles.bodySecondary.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: (isBold ? AppTextStyles.bodyBold : AppTextStyles.bodySecondary).copyWith(
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
