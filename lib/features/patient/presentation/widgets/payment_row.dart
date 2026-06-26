/// Payment history row with amount and optional admin delete action.
///
/// Rule 15/16 — all colours via Theme.of(context).colorScheme.
/// Rule 3 — delete goes through RecordPaymentController, not direct repo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';

class PaymentRow extends ConsumerWidget {
  const PaymentRow({
    super.key,
    required this.payment,
    required this.isAdmin,
    required this.patientId,
  });
  final PaymentRecord payment;
  final bool isAdmin;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final recordedByAsync = payment.recordedBy != null
        ? ref.watch(staffProfileProvider(payment.recordedBy!))
        : null;

    return DataListTile(
      titleWidget: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSizes.p8,
        runSpacing: AppSizes.p4,
        children: [
          Text(payment.reason, style: AppTextStyles.bodyBold),
          if (payment.sessionBalanceAdded > 0)
            _BalanceTag(
              label: '+${payment.sessionBalanceAdded} PT',
              bg: cs.primaryContainer,
              fg: cs.primary,
            ),
          if (payment.tractionBalanceAdded > 0)
            _BalanceTag(
              label: '+${payment.tractionBalanceAdded} Tr',
              bg: cs.secondaryContainer,
              fg: cs.secondary,
            ),
        ],
      ),
      subtitleWidget: _buildSubtitle(ref, recordedByAsync),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            payment.amount.toCurrencyString(),
            style: AppTextStyles.bodyBold,
          ),
          if (isAdmin) ...[
            const SizedBox(width: AppSizes.p8),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: cs.error, size: AppSizes.iconSmall),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubtitle(WidgetRef ref, AsyncValue<Staff>? recordedByAsync) {
    final dateStr = payment.recordedAt.toDateTimeString();
    final recordedByWidget = recordedByAsync?.when(
          data: (staff) {
            final String name = staff.isActive
                ? staff.fullName
                : '${staff.fullName} (${AppStrings.deactivated})';
            return Text(
              '${AppStrings.recordedBy} $name',
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ) ??
        const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(dateStr, style: AppTextStyles.caption),
        if (recordedByAsync != null) recordedByWidget,
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.deletePayment,
        message: AppStrings.confirmDeletePayment,
        confirmLabel: AppStrings.delete,
        cancelLabel: AppStrings.cancel,
        isDestructive: true,
      ),
    );
    if (confirm != true || !context.mounted) return;
    final result = await ref
        .read(recordPaymentControllerProvider.notifier)
        .deletePayment(paymentId: payment.id, patientId: patientId);
    if (!context.mounted) return;
    result.when(
      success: (_) => AppSnackbar.show(context,
          message: AppStrings.paymentDeleted, variant: AppSnackbarVariant.success),
      failure: (error) => AppSnackbar.show(context,
          message: error.message, variant: AppSnackbarVariant.error),
    );
  }
}

class _BalanceTag extends StatelessWidget {
  const _BalanceTag({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.r6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: fg, fontWeight: FontWeight.bold),
      ),
    );
  }
}
