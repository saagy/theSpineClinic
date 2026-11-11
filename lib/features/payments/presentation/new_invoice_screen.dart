import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/form_page_skeleton.dart';
import '../../auth/domain/staff.dart';
import '../../patient/presentation/patient_providers.dart';
import '../domain/invoice_access.dart';
import 'service_catalog_providers.dart';
import 'widgets/invoice_access_gate.dart';
import 'widgets/new_invoice_form.dart';

const _t = AppStrings.invoices;

/// Route entry for a new invoice. Waits for the patient and the catalog;
/// assigned doctors only pre-fill lines, so a failure there is not blocking.
class NewInvoiceScreen extends ConsumerWidget {
  const NewInvoiceScreen({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => InvoiceManageGate(
    allow: InvoiceAccess.canIssue,
    frame: _frame,
    loading: const FormPageSkeleton(),
    builder: (Staff user) {
      final patient = ref.watch(patientDetailProvider(patientId));
      final catalog = ref.watch(serviceCatalogProvider);
      final doctors = ref.watch(patientAssignedDoctorsProvider(patientId));
      final Object? error = patient.error ?? catalog.error;
      if (error != null && (!patient.hasValue || !catalog.hasValue)) {
        return _frame(
          ErrorView(
            exception: AppException.fromSupabaseException(error),
            onRetry: () {
              ref.invalidate(patientDetailProvider(patientId));
              ref.invalidate(serviceCatalogProvider);
            },
          ),
        );
      }
      if (!patient.hasValue || !catalog.hasValue || doctors.isLoading && !doctors.hasValue) {
        return _frame(const FormPageSkeleton());
      }
      return NewInvoiceForm(
        patient: patient.requireValue,
        services: catalog.requireValue.where((service) => service.active).toList(),
        assignedDoctors: doctors.value ?? const [],
        canDiscount: InvoiceAccess.canManage(user),
      );
    },
  );

  Widget _frame(Widget body) => Scaffold(
    appBar: AppBar(title: Text(_t.newInvoice)),
    body: body,
  );
}
