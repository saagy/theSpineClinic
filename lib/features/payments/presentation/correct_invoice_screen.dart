import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/form_page_skeleton.dart';
import '../../patient/presentation/patient_providers.dart';
import '../../staff/presentation/staff_providers.dart';
import 'invoice_detail_providers.dart';
import 'service_catalog_providers.dart';
import 'widgets/correct_invoice_form.dart';
import 'widgets/invoice_access_gate.dart';

const _t = AppStrings.invoiceDetail;

/// Route entry for correcting an invoice. Waits for the invoice, the patient
/// and the catalog; the doctor list only pre-fills lines, so a failure there
/// leaves doctors to be chosen again rather than blocking the correction.
class CorrectInvoiceScreen extends ConsumerWidget {
  const CorrectInvoiceScreen({super.key, required this.patientId, required this.invoiceId});
  final String patientId;
  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => InvoiceManageGate(
    frame: _frame,
    loading: const FormPageSkeleton(),
    builder: (_) {
      final invoice = ref.watch(invoiceDetailProvider(invoiceId));
      final patient = ref.watch(patientDetailProvider(patientId));
      final catalog = ref.watch(serviceCatalogProvider);
      final doctors = ref.watch(allDoctorsForFilterProvider);
      final bool ready = invoice.hasValue && patient.hasValue && catalog.hasValue;
      final Object? error = invoice.error ?? patient.error ?? catalog.error;
      if (error != null && !ready) {
        return _frame(
          ErrorView(
            exception: AppException.fromSupabaseException(error),
            onRetry: () {
              ref.invalidate(invoiceDetailProvider(invoiceId));
              ref.invalidate(patientDetailProvider(patientId));
              ref.invalidate(serviceCatalogProvider);
            },
          ),
        );
      }
      if (!ready || doctors.isLoading && !doctors.hasValue) return _frame(const FormPageSkeleton());
      final document = invoice.requireValue;
      if (!document.canCorrect) {
        return _frame(
          EmptyState(
            icon: Icons.block,
            message: AppStrings.fromKey(
              document.isVoided ? 'invoice_invoice_voided' : 'invoice_has_refunds',
            ),
          ),
        );
      }
      // The form pins the invoice it opened with; see RefundScreen.
      return CorrectInvoiceForm(
        key: ValueKey(document.id),
        invoice: document,
        patient: patient.requireValue,
        services: catalog.requireValue.where((service) => service.active).toList(),
        doctors: doctors.value ?? const [],
      );
    },
  );

  Widget _frame(Widget body) => Scaffold(
    appBar: AppBar(title: Text(_t.correctInvoice)),
    body: body,
  );
}
