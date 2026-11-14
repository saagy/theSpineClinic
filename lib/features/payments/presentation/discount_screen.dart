import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/form_page_skeleton.dart';
import '../../auth/domain/staff.dart';
import 'invoice_detail_providers.dart';
import 'widgets/discount_form.dart';
import 'widgets/invoice_access_gate.dart';

const _d = AppStrings.invoiceDiscount;

/// Route entry for discounting an issued invoice. Payment staff only.
class DiscountScreen extends ConsumerWidget {
  const DiscountScreen({super.key, required this.patientId, required this.invoiceId});
  final String patientId;
  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => InvoiceManageGate(
    frame: _frame,
    loading: const FormPageSkeleton(),
    builder: (Staff user) {
      final invoice = ref.watch(invoiceDetailProvider(invoiceId));
      if (invoice.hasError && !invoice.hasValue) {
        return _frame(
          ErrorView(
            exception: AppException.fromSupabaseException(invoice.error!),
            onRetry: () => ref.invalidate(invoiceDetailProvider(invoiceId)),
          ),
        );
      }
      if (!invoice.hasValue) return _frame(const FormPageSkeleton());
      final document = invoice.requireValue;
      if (!document.canDiscount) {
        return _frame(
          EmptyState(
            icon: Icons.block,
            message: document.isVoided ? AppStrings.fromKey('invoice_invoice_voided') : _d.nothingLeft,
          ),
        );
      }
      // The form pins the invoice version it opened with, so a discount
      // prepared from outdated figures stays rejected until it is reopened.
      return DiscountForm(
        key: ValueKey(document.id),
        invoice: document,
        defaultBranch: user.branch ?? document.branch,
      );
    },
  );

  Widget _frame(Widget body) => Scaffold(
    appBar: AppBar(title: Text(_d.title)),
    body: body,
  );
}
