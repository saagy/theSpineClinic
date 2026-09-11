import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/payments/domain/patient_payment_summary.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_payment_entry.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_tab_header.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

class WorkspacePayments extends ConsumerWidget {
  const WorkspacePayments({super.key, required this.patientId, this.dueOnly = false});
  final String patientId;
  final bool dueOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = patientPaymentsProvider(patientId);
    final canPay = ref.watch(currentUserProvider).value?.canHandlePayments ?? false;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkspaceTabHeader(
          title: dueOnly ? AppStrings.totalOutstanding : AppStrings.payments,
          actionLabel: canPay && !dueOnly ? AppStrings.recordPayment : null,
          onAction: canPay && !dueOnly
              ? () {
                  if (ref.read(currentUserProvider).value?.canHandlePayments != true) return;
                  context.push(AppRoutes.recordPayment.replaceFirst(':id', patientId));
                }
              : null,
        ),
        const SizedBox(height: AppSizes.p14),
        RecordAsync(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          data: (records) {
            final summary = PatientPaymentSummary(records);
            final shown = dueOnly ? summary.outstanding : records;
            if (shown.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSizes.p24),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                  border: Border.all(color: cs.outlineVariant.withAlpha(80)),
                ),
                child: RecordMessage(
                  message: dueOnly ? AppStrings.noOutstandingPayments : AppStrings.noPaymentsRecorded,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!dueOnly) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: AppStrings.totalOutstanding,
                          amount: summary.totalDue,
                          isDue: true,
                        ),
                      ),
                      const SizedBox(width: AppSizes.p10),
                      Expanded(
                        child: _StatCard(
                          label: AppStrings.totalPaid,
                          amount: summary.totalPaid,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p14),
                ],
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                    border: Border.all(color: cs.outlineVariant.withAlpha(80)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < shown.length; i++) ...[
                        WorkspacePaymentEntry(payment: shown[i]),
                        if (i < shown.length - 1) const Divider(height: AppSizes.borderWidth),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.amount, this.isDue = false});
  final String label;
  final double amount;
  final bool isDue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final warningColor = Theme.of(context).extension<ClinicColors>()?.warning ?? cs.error;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(
          color: isDue && amount > 0 ? warningColor.withAlpha(120) : cs.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: AppSizes.p4),
          Text(
            Formatters.formatCurrency(amount),
            style: AppTextStyles.headingSmall.copyWith(
              color: isDue && amount > 0 ? warningColor : cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
