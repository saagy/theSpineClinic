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
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
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
    return DataListTile(
      title: payment.reason,
      subtitle: payment.recordedAt.toDateTimeString(),
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
