/// Payment history row component with structured ledger breakdown and context menu.
///
/// Rule 1  — under 200 lines.
/// Rule 3  — Riverpod state management.
/// Rule 15 — colorScheme tokens.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/collect_due_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/edit_payment_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/payment_ledger_box.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/payment_row_header.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// A single payment row card in the patient payment history list.
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

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        side: BorderSide(color: cs.outlineVariant, width: AppSizes.borderWidth),
      ),
      color: cs.surface,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        child: InkWell(
          onTap: isAdmin ? () => _showEditPayment(context) : null,
          onLongPress: isAdmin ? () => _confirmDelete(context, ref) : null,
          splashColor: cs.surfaceContainer,
          highlightColor: cs.surfaceContainer.withAlpha(128),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                PaymentRowHeader(
                  payment: payment,
                  recordedByAsync: recordedByAsync,
                  isAdmin: isAdmin,
                  onEdit: () => _showEditPayment(context),
                  onDelete: () => _confirmDelete(context, ref),
                ),
                if (_hasLedgerData)
                  PaymentLedgerBox(
                    payment: payment,
                    isAdmin: isAdmin,
                    onCollectDue: () => _showCollectDue(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasLedgerData =>
      payment.sessionBalanceAdded > 0 ||
      payment.tractionBalanceAdded > 0 ||
      payment.totalPrice != null ||
      payment.hasOutstandingDue;

  void _showCollectDue(BuildContext context) {
    AppBottomSheet.show<void>(
      context: context,
      title: AppStrings.collectDue,
      initialChildSize: 0.58,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) => CollectDueSheet(
        payment: payment,
        patientId: patientId,
        scrollController: scrollController,
      ),
    );
  }

  void _showEditPayment(BuildContext context) {
    AppBottomSheet.show<void>(
      context: context,
      title: AppStrings.editPayment,
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => EditPaymentSheet(
        payment: payment,
        patientId: patientId,
        scrollController: scrollController,
      ),
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
      success: (_) => AppSnackbar.show(
        context,
        message: AppStrings.paymentDeleted,
        variant: AppSnackbarVariant.success,
      ),
      failure: (error) => AppSnackbar.show(
        context,
        message: error.message,
        variant: AppSnackbarVariant.error,
      ),
    );
  }
}
