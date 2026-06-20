/// Payment history row with amount and optional admin delete action.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';

/// A single payment history row with amount and optional delete.
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
    final recordedByAsync = payment.recordedBy != null
        ? ref.watch(staffProfileProvider(payment.recordedBy!))
        : null;

    return DataListTile(
      titleWidget: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSizes.p8,
        runSpacing: AppSizes.p4,
        children: [
          Text(
            payment.reason,
            style: AppTextStyles.bodyBold.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (payment.sessionBalanceAdded > 0)
            _BalanceTag(
              label: '+${payment.sessionBalanceAdded} PT',
              bg: AppColors.primaryLight,
              fg: AppColors.primary,
            ),
          if (payment.tractionBalanceAdded > 0)
            _BalanceTag(
              label: '+${payment.tractionBalanceAdded} Tr',
              bg: AppColors.warningBg,
              fg: AppColors.warning,
            ),
        ],
      ),
      subtitleWidget: _buildSubtitle(ref, recordedByAsync),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            payment.amount.toCurrencyString(),
            style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary),
          ),
          if (isAdmin) ...[
            const SizedBox(width: AppSizes.p4),
            GestureDetector(
              onTap: () => _confirmDelete(context, ref),
              child: const Icon(Icons.delete_outline_rounded,
                  size: AppSizes.iconSmall, color: AppColors.error),
            ),
          ],
        ],
      ),
      transparent: true,
    );
  }

  Widget _buildSubtitle(
    WidgetRef ref,
    AsyncValue<Staff>? recordedByAsync,
  ) {
    final dateStr = payment.recordedAt.toDateTimeString();
    final recordedByWidget = recordedByAsync?.when(
          data: (staff) {
            final String name = staff.isActive
                ? staff.fullName
                : '${staff.fullName} (${AppStrings.deactivated})';
            return Text(
              'Recorded by $name',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
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
        Text(
          dateStr,
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
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
    if (confirm == true && context.mounted) {
      final repo = ref.read(paymentRepositoryProvider);
      final result = await repo.deletePayment(payment.id);
      if (context.mounted) {
        result.when(
          success: (_) {
            AppSnackbar.show(context,
                message: AppStrings.paymentDeleted,
                variant: AppSnackbarVariant.success);
            ref.invalidate(patientPaymentsProvider(patientId));
            ref.invalidate(patientDetailProvider(patientId));
          },
          failure: (error) {
            AppSnackbar.show(context,
                message: error.message, variant: AppSnackbarVariant.error);
          },
        );
      }
    }
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8,
        vertical: AppSizes.p2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
