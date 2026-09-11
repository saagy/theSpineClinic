import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_payment_actions.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Single payment record row with smooth recorder resolution.
class WorkspacePaymentEntry extends ConsumerWidget {
  const WorkspacePaymentEntry({super.key, required this.payment});
  final PaymentRecord payment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final recorderAsync = payment.recordedBy == null
        ? null
        : ref.watch(staffProfileProvider(payment.recordedBy!));

    return Padding(
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.reason, style: AppTextStyles.bodyBold.copyWith(color: colors.onSurface)),
                const SizedBox(height: AppSizes.p4),
                Text(
                  Formatters.formatDateMedium(payment.recordedAt),
                  style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                ),
                if (payment.recordedBy != null) ...[
                  const SizedBox(height: AppSizes.p2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: recorderAsync?.when(
                      data: (staff) => Text(
                        staff.fullName,
                        key: ValueKey('recorder_${staff.id}'),
                        style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                      ),
                      loading: () => const SkeletonBox(
                        key: ValueKey('recorder_skeleton'),
                        width: 80,
                        height: 12,
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ) ?? const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrency(payment.amount),
                  style: AppTextStyles.bodyBold.copyWith(color: colors.onSurface),
                ),
                if (payment.remainingDue > 0)
                  Text(
                    '${AppStrings.patientDue}: ${Formatters.formatCurrency(payment.remainingDue)}',
                    style: AppTextStyles.captionBold.copyWith(
                      color: Theme.of(context).extension<ClinicColors>()?.warning ?? colors.error,
                    ),
                  ),
              ],
            ),
          ),
          if (ref.watch(currentUserProvider).value?.canHandlePayments == true) ...[
            const SizedBox(width: AppSizes.p8),
            WorkspacePaymentActions(payment: payment),
          ],
        ],
      ),
    );
  }
}
