import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/form_page_skeleton.dart';
import '../../auth/domain/staff.dart';
import '../../patient/presentation/patient_providers.dart';
import 'invoice_detail_providers.dart';
import 'widgets/invoice_access_gate.dart';
import 'widgets/refund_form.dart';

const _t = AppStrings.invoiceDetail;

/// Route entry for refunding an invoice. Waits for the invoice and for the
/// patient, whose session balance limits how many sessions can be cancelled.
class RefundScreen extends ConsumerWidget {
  const RefundScreen({super.key, required this.patientId, required this.invoiceId});
  final String patientId;
  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => InvoiceManageGate(
    frame: _frame,
    loading: const FormPageSkeleton(),
    builder: (Staff user) {
      final invoice = ref.watch(invoiceDetailProvider(invoiceId));
      final patient = ref.watch(patientDetailProvider(patientId));
      final Object? error = invoice.error ?? patient.error;
      if (error != null && (!invoice.hasValue || !patient.hasValue)) {
        return _frame(
          ErrorView(
            exception: AppException.fromSupabaseException(error),
            onRetry: () {
              ref.invalidate(invoiceDetailProvider(invoiceId));
              ref.invalidate(patientDetailProvider(patientId));
            },
          ),
        );
      }
      if (!invoice.hasValue || !patient.hasValue) return _frame(const FormPageSkeleton());
      final document = invoice.requireValue;
      if (!document.canRefund) {
        return _frame(
          EmptyState(
            icon: Icons.block,
            message: AppStrings.fromKey(
              document.isVoided ? 'invoice_invoice_voided' : 'invoice_refund_limit',
            ),
          ),
        );
      }
      // The form pins the invoice version it opened with, so a refund prepared
      // from outdated figures stays rejected until the form is reopened.
      return RefundForm(
        key: ValueKey(document.id),
        invoice: document,
        ptBalance: patient.requireValue.sessionBalance,
        tractionBalance: patient.requireValue.tractionBalance,
        defaultBranch: user.branch ?? document.branch,
      );
    },
  );

  Widget _frame(Widget body) => Scaffold(
    appBar: AppBar(title: Text(_t.refundTitle)),
    body: body,
  );
}
