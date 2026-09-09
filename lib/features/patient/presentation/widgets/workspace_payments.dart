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
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';
import 'package:spine_clinic_app/features/payments/domain/patient_payment_summary.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_payment_actions.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

class WorkspacePayments extends ConsumerWidget {
  const WorkspacePayments({super.key, required this.patientId, this.dueOnly = false});
  final String patientId;
  final bool dueOnly;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = patientPaymentsProvider(patientId);
    final canPay = ref.watch(currentUserProvider).value?.canHandlePayments ?? false;
    return RecordSection(
      showTitle: dueOnly,
      primaryAction: true,
      title: dueOnly ? AppStrings.totalOutstanding : AppStrings.payments,
      action: canPay && !dueOnly ? AppStrings.recordPayment : null,
      onAction: () {
        if (ref.read(currentUserProvider).value?.canHandlePayments != true) return;
        context.push(AppRoutes.recordPayment.replaceFirst(':id', patientId));
      },
      child: RecordAsync(
        value: ref.watch(provider),
        onRetry: () => ref.invalidate(provider),
        data: (records) {
          final summary = PatientPaymentSummary(records);
          final shown = dueOnly ? summary.outstanding : records;
          if (shown.isEmpty) {
            return RecordMessage(
              message: dueOnly ? AppStrings.noOutstandingPayments : AppStrings.noPaymentsRecorded,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSizes.p40,
                runSpacing: AppSizes.p12,
                children: [
                  _Amount(label: AppStrings.totalOutstanding, amount: summary.totalDue, large: true),
                  if (!dueOnly) _Amount(label: AppStrings.totalPaid, amount: summary.totalPaid, large: true),
                ],
              ),
              const SizedBox(height: AppSizes.p24),
              for (final record in shown) _PaymentEntry(payment: record),
            ],
          );
        },
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.label, required this.amount, this.large = false});
  final String label;
  final double amount;
  final bool large;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: AppSizes.p6),
      Text(
        Formatters.formatCurrency(amount),
        style: (large ? AppTextStyles.numberLarge : AppTextStyles.number).copyWith(
          color: label == AppStrings.totalOutstanding && amount > 0
              ? Theme.of(context).extension<ClinicColors>()!.warning
              : null,
        ),
      ),
    ],
  );
}

class _PaymentEntry extends ConsumerWidget {
  const _PaymentEntry({required this.payment});
  final PaymentRecord payment;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final recorder = payment.recordedBy == null
        ? null
        : ref.watch(staffProfileProvider(payment.recordedBy!)).value;
    final description = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(payment.reason, style: AppTextStyles.bodyBold),
        const SizedBox(height: AppSizes.p6),
        Text(
          Formatters.formatDateMedium(payment.recordedAt),
          style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
        ),
        if (recorder != null) Text(recorder.fullName, style: AppTextStyles.caption),
        if (payment.sessionBalanceAdded != 0)
          Text(
            '${AppStrings.sessionBalanceAddedField}: ${payment.sessionBalanceAdded}',
            style: AppTextStyles.caption,
          ),
        if (payment.tractionBalanceAdded != 0)
          Text(
            '${AppStrings.tractionBalanceAddedField}: ${payment.tractionBalanceAdded}',
            style: AppTextStyles.caption,
          ),
      ],
    );
    final amountCells = [
      _Amount(label: AppStrings.patientPrice, amount: payment.totalPrice ?? payment.amount),
      _Amount(label: AppStrings.patientPaid, amount: payment.amount),
      _Amount(label: AppStrings.patientDue, amount: payment.remainingDue),
    ];
    final amounts = Wrap(spacing: AppSizes.p24, runSpacing: AppSizes.p12, children: amountCells);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= AppSizes.desktopBreakpoint &&
              MediaQuery.textScalerOf(context).scale(1) < 1.5) {
            return Row(
              children: [
                Expanded(child: description),
                const SizedBox(width: AppSizes.p24),
                Expanded(
                  child: Row(
                    children: [
                      for (final cell in amountCells)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: AppSizes.p8),
                            child: cell,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.p16),
                if (ref.watch(currentUserProvider).value?.canHandlePayments == true)
                  SizedBox(
                    width: AppSizes.patientPaymentActionWidth,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: WorkspacePaymentActions(payment: payment),
                    ),
                  ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              description,
              const SizedBox(height: AppSizes.p16),
              amounts,
              Align(
                alignment: Alignment.centerRight,
                child: WorkspacePaymentActions(payment: payment),
              ),
            ],
          );
        },
      ),
    );
  }
}
