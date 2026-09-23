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

/// Payment entry that adapts to the width of its enclosing list.
class WorkspacePaymentEntry extends ConsumerWidget {
  const WorkspacePaymentEntry({super.key, required this.payment});
  final PaymentRecord payment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final warning =
        Theme.of(context).extension<ClinicColors>()?.warning ?? colors.error;
    final canManage =
        ref.watch(currentUserProvider).value?.canHandlePayments ?? false;
    final recorderAsync = payment.recordedBy == null
        ? null
        : ref.watch(staffProfileProvider(payment.recordedBy!));
    final Widget metadata = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Formatters.formatDateMedium(payment.recordedAt),
          style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
        ),
        if (recorderAsync != null) ...[
          const SizedBox(height: AppSizes.p2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: recorderAsync.when(
              data: (staff) => Text(
                staff.fullName,
                key: ValueKey('recorder_${staff.id}'),
                style: AppTextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              loading: () => const SkeletonBox(
                key: ValueKey('recorder_skeleton'),
                width: AppSizes.paymentRecorderSkeletonWidth,
                height: AppSizes.p12,
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ],
    );
    final Widget title = Text(
      payment.reason,
      style: AppTextStyles.bodyBold.copyWith(color: colors.onSurface),
    );
    final Widget amount = Text(
      Formatters.formatCurrency(payment.amount),
      style: AppTextStyles.bodyBold.copyWith(color: colors.onSurface),
    );
    final Widget? due = payment.hasOutstandingDue
        ? Text(
            '${AppStrings.patientDue}: ${Formatters.formatCurrency(payment.remainingDue)}',
            style: AppTextStyles.captionBold.copyWith(color: warning),
          )
        : null;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.p16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= AppSizes.paymentEntryWideBreakpoint) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: AppSizes.p4),
                      metadata,
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.p16),
                SizedBox(
                  width: AppSizes.paymentAmountColumnWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [amount, if (due != null) due],
                  ),
                ),
                if (canManage) ...[
                  if (payment.hasOutstandingDue) ...[
                    const SizedBox(width: AppSizes.p8),
                    WorkspaceCollectDueButton(payment: payment),
                  ],
                  WorkspacePaymentMenu(payment: payment),
                ],
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: title),
                  if (canManage) WorkspacePaymentMenu(payment: payment),
                ],
              ),
              const SizedBox(height: AppSizes.p8),
              Wrap(
                spacing: AppSizes.p16,
                runSpacing: AppSizes.p4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [amount, if (due != null) due],
              ),
              const SizedBox(height: AppSizes.p8),
              metadata,
              if (canManage && payment.hasOutstandingDue) ...[
                const SizedBox(height: AppSizes.p8),
                WorkspaceCollectDueButton(payment: payment),
              ],
            ],
          );
        },
      ),
    );
  }
}
