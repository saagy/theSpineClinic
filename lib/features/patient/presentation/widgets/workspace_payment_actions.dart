import 'package:flutter/material.dart';
import 'package:spine_clinic_app/shared/widgets/record_action_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/collect_due_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/edit_payment_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

class WorkspacePaymentActions extends ConsumerWidget {
  const WorkspacePaymentActions({super.key, required this.payment});
  final PaymentRecord payment;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(currentUserProvider).value?.canHandlePayments != true) {
      return const SizedBox.shrink();
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (payment.hasOutstandingDue)
          TextButton(
            onPressed: () {
              if (ref.read(currentUserProvider).value?.canHandlePayments != true) return;
              AppBottomSheet.show<void>(
                context: context,
                title: AppStrings.collectDue,
                builder: (_, scroll) =>
                    CollectDueSheet(payment: payment, patientId: payment.patientId, scrollController: scroll),
              );
            },
            child: const Text(AppStrings.collectDue),
          ),
        RecordActionMenu<String>(
          tooltip: AppStrings.moreActions,
          actions: const [
            RecordMenuAction('edit', AppStrings.editPayment, Icons.edit_outlined),
            RecordMenuAction('delete', AppStrings.deletePayment, Icons.delete_outline, destructive: true),
          ],
          onSelected: (action) async {
            if (ref.read(currentUserProvider).value?.canHandlePayments != true) return;
            if (action == 'edit') {
              await AppBottomSheet.show<void>(
                context: context,
                title: AppStrings.editPayment,
                builder: (_, scroll) => EditPaymentSheet(
                  payment: payment,
                  patientId: payment.patientId,
                  scrollController: scroll,
                ),
              );
            } else {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => const ConfirmationDialog(
                  title: AppStrings.deletePayment,
                  message: AppStrings.confirmDeletePayment,
                  confirmLabel: AppStrings.delete,
                  isDestructive: true,
                ),
              );
              if (confirmed != true || !context.mounted) return;
              final result = await ref
                  .read(recordPaymentControllerProvider.notifier)
                  .deletePayment(patientId: payment.patientId, paymentId: payment.id);
              if (!context.mounted) return;
              result.when(
                success: (_) => AppSnackbar.show(context, message: AppStrings.paymentDeleted),
                failure: (e) => AppSnackbar.show(
                  context,
                  message: AppStrings.fromKey(e.userMessageKey),
                  variant: AppSnackbarVariant.error,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
